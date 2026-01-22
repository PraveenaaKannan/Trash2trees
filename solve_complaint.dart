import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SolveComplaintPage extends StatefulWidget {
  final String ticketId;
  const SolveComplaintPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  _SolveComplaintPageState createState() => _SolveComplaintPageState();
}

class _SolveComplaintPageState extends State<SolveComplaintPage> {
  Map complaint = {};
  bool _loading = true;
  File? _image;

  final String fetchComplaintUrl = "http://10.144.16.64/trash2trees/fetch_complaints.php";
  final String updateComplaintUrl = "http://10.144.16.64/trash2trees/resolve_complaints.php";

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();
  }

  Future<void> _fetchComplaintDetails() async {
    final response = await http.post(
      Uri.parse(fetchComplaintUrl),
      body: {"ticket_id": widget.ticketId},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          complaint = data['complaint'];
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _submitResolution() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please capture a photo")));
      return;
    }

    var request = http.MultipartRequest("POST", Uri.parse(updateComplaintUrl));
    request.fields["ticket_id"] = widget.ticketId;
    request.fields["eco_points"] = "10";
    request.files.add(await http.MultipartFile.fromPath("resolved_photo", _image!.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Complaint resolved")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Solve Complaint"), backgroundColor: Colors.green),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          ListTile(title: Text("Street: ${complaint['street']}")),
          ListTile(title: Text("Bin ID: ${complaint['bin_id']}")),
          ListTile(title: Text("Ward: ${complaint['ward']}")),
          ListTile(title: Text("Lat: ${complaint['latitude']}")),
          ListTile(title: Text("Long: ${complaint['longitude']}")),
          SizedBox(height: 10),
          _image == null
              ? Text("No photo captured")
              : Image.file(_image!, height: 200),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text("Capture Photo"),
          ),
          ElevatedButton(
            onPressed: _submitResolution,
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }
}
