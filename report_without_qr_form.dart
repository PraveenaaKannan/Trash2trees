import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'my_reports_page.dart'; // for registered users

class ReportWithoutQRForm extends StatefulWidget {
  final String userName; // "Guest" if guest user
  const ReportWithoutQRForm({super.key, required this.userName});

  @override
  State<ReportWithoutQRForm> createState() => _ReportWithoutQRFormState();
}

class _ReportWithoutQRFormState extends State<ReportWithoutQRForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController wardController = TextEditingController();
  final TextEditingController branchController = TextEditingController();

  String complaintType = "Missing";
  String description = "";
  double latitude = 0.0, longitude = 0.0;
  File? image;
  bool isLoadingLocation = false;

  final String wardLink = "https://drive.google.com/uc?export=download&id=1EvVFjOMtWw-6VLWlkcAfNSjz62sGxIFh";


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => isLoadingLocation = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      latitude = position.latitude;
      longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String streetName = place.thoroughfare ?? place.name ?? "";
        String subLocality = place.subLocality ?? place.subAdministrativeArea ?? "";
        String locality = place.locality ?? "";

        String fetchedStreet = [streetName, subLocality, locality]
            .where((part) => part.isNotEmpty)
            .join(", ");

        streetController.text = fetchedStreet; // Editable
      }

      setState(() => isLoadingLocation = false);
    } catch (e) {
      setState(() => isLoadingLocation = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error getting location: $e")));
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => image = File(picked.path));
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cannot open URL")));
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Photo required")));
      return;
    }

    String ticketNo = "TCKT-${DateTime.now().millisecondsSinceEpoch}";
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.144.16.64/trash2trees/submit_report.php"),
    );

    request.fields['ticket_id'] = ticketNo;
    request.fields['user_name'] = widget.userName;
    request.fields['bin_id'] = '';
    request.fields['street'] = streetController.text;
    request.fields['ward'] = wardController.text;
    request.fields['branch'] = branchController.text;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['complaint_type'] = complaintType;
    request.fields['description'] = description;

    request.files.add(await http.MultipartFile.fromPath('photo', image!.path));

    try {
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      var jsonResp = jsonDecode(respStr);

      if (jsonResp['status'] == 'success') {
        int existingCount = jsonResp['existing_complaints'];
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Report Submitted", style: TextStyle(color: Colors.green)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // close dialog
                    if (widget.userName.toLowerCase() == "guest") {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Access Denied"),
                          content: const Text("Guest users cannot track reports."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
                          ],
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyReportsPage(userName: widget.userName),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Ticket ID: $ticketNo",
                    style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                Text("Existing complaints for this street: $existingCount"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // back to dashboard
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${jsonResp['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.green.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        title: const Text("Report Without QR"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isLoadingLocation
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Latitude: $latitude", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Longitude: $longitude", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10), // space before street
                    TextFormField(
                      controller: streetController,
                      decoration: _inputDecoration("Street"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                TextButton(
                  onPressed: () => _launchURL(wardLink),
                  child: const Text(
                    "View Available Wards (PDF)",
                    style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: wardController,
              decoration: _inputDecoration("Ward"),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: branchController,
              decoration: _inputDecoration("Branch"),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField(
              value: complaintType,
              decoration: _inputDecoration("Complaint Type"),
              items: ["Missing", "Damaged", "Full"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => complaintType = val!),
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: _inputDecoration("Description"),
              onSaved: (val) => description = val ?? "",
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (image != null) Padding(padding: const EdgeInsets.all(8), child: Image.file(image!, height: 150)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.send),
              label: const Text("Submit Report"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
