import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class QRReportForm extends StatefulWidget {
  const QRReportForm({super.key});

  @override
  State<QRReportForm> createState() => _QRReportFormState();
}

class _QRReportFormState extends State<QRReportForm> {
  final _formKey = GlobalKey<FormState>();
  String? binId, street, ward, latitude, longitude, branch;
  String complaintType = "Missing";
  String description = "";
  File? image;
  bool scanned = false;

  // QR scanner result
  void _onQRViewCreated(String qrData) {
    List<String> parts = qrData.split("|"); // Format: binId|lat|lon|street|ward|branch
    if (parts.length == 6) {
      setState(() {
        binId = parts[0];
        latitude = parts[1];
        longitude = parts[2];
        street = parts[3];
        ward = parts[4];
        branch = parts[5];
        scanned = true;
      });
    }
  }

  // Scan QR
  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Scan QR Code")),
          body: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final raw = barcodes.first.rawValue;
                if (raw != null) {
                  Navigator.pop(context, raw);
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null) _onQRViewCreated(result);
  }

  // Pick optional image
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) setState(() => image = File(picked.path));
  }

  // Submit report to DB
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    String ticketNo = "TCKT-${DateTime.now().millisecondsSinceEpoch}";
    bool isRegistered = true; // Replace with actual login check

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.144.16.64/submit_report.php"),
    );

    request.fields['bin_id'] = binId ?? '';
    request.fields['street'] = street ?? '';
    request.fields['ward'] = ward ?? '';
    request.fields['branch'] = branch ?? '';
    request.fields['latitude'] = latitude ?? '';
    request.fields['longitude'] = longitude ?? '';
    request.fields['complaint_type'] = complaintType;
    request.fields['description'] = description;
    request.fields['ticket_id'] = ticketNo;
    request.fields['user_id'] = isRegistered ? "1" : "";

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', image!.path));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      if (!isRegistered) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Login Required"),
            content: const Text("Login to track your report and earn points."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report submitted! Ticket: $ticketNo")),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting report")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report with QR")),
      body: scanned
          ? Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Bin ID: $binId"),
            Text("Street: $street"),
            Text("Ward: $ward"),
            Text("Latitude: $latitude"),
            Text("Longitude: $longitude"),
            Text("Branch: $branch"),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: complaintType,
              items: ["Missing", "Damaged", "Full"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => complaintType = val!),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Description"),
              onSaved: (val) => description = val ?? "",
            ),
            ElevatedButton(
                onPressed: _pickImage, child: const Text("Capture Photo (Optional)")),
            if (image != null) Image.file(image!, height: 150),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitReport, child: const Text("Submit Report")),
          ],
        ),
      )
          : Center(
        child: ElevatedButton.icon(
            onPressed: _scanQR,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Start QR Scan")),
      ),
    );
  }
}
