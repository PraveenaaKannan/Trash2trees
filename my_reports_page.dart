import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MyReportsPage extends StatefulWidget {
  final String userName;
  const MyReportsPage({Key? key, required this.userName}) : super(key: key);

  @override
  _MyReportsPageState createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  List reports = [];
  bool isLoading = true;
  int totalEcoPoints = 0;

  final String serverUrl = "http://10.144.16.64/trash2trees/";

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.post(
        Uri.parse("${serverUrl}get_reports.php"),
        body: {"user_name": widget.userName},
      );

      if (response.statusCode == 200) {
        setState(() {
          reports = json.decode(response.body);
          totalEcoPoints = reports.fold(
              0, (sum, r) => sum + int.parse(r['eco_points'] ?? '0'));
          isLoading = false;
        });

        // Show eco points dialog if >= 100
        if (totalEcoPoints >= 100) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Congratulations! 🌱"),
                content: const Text(
                    "You’ve earned 100 eco points! Visit the nursery to claim your free plant."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          });
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load reports.")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching reports.")),
      );
    }
  }

  void _showFeedbackDialog(String ticketId) {
    int rating = 0;
    TextEditingController commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Give Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rate the service:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (i) => IconButton(
                    icon: Icon(
                      Icons.star,
                      color: i < rating ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => setStateDialog(() => rating = i + 1),
                  ),
                ),
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(hintText: "Your comments"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await http.post(
                  Uri.parse("${serverUrl}submit_feedback.php"),
                  body: {
                    "ticket_id": ticketId,
                    "rating": rating.toString(),
                    "comment": commentCtrl.text,
                  },
                );
                fetchReports();
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCertificate(String url, String ticketId) async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      String savePath = "${dir.path}/${ticketId}_certificate.pdf";

      await Dio().download(url, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Certificate downloaded: $savePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download certificate: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(child: Text("No reports found"))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final r = reports[index];

          String beforePhoto = r['photo_path'] ?? "";
          String afterPhoto = r['resolved_photo'] ?? "";
          String certificate = r['certificate_path'] ?? "";

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ExpansionTile(
              leading: Icon(
                Icons.report,
                color: getStatusColor(r['status']),
              ),
              title: Text("Ticket: ${r['ticket_id']} - ${r['status']}"),
              subtitle: Text("Complaint: ${r['complaint_type']}"),
              children: [
                const SizedBox(height: 5),

                // Before Photo
                if (beforePhoto != "")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Before Photo:"),
                      Image.network(
                        "$serverUrl$beforePhoto",
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, __) => const Icon(
                          Icons.broken_image,
                          size: 80,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 5),

                // After Photo
                if (afterPhoto != "")
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("After Photo:"),
                        Image.network(
                          "$serverUrl$afterPhoto",
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => const Icon(
                            Icons.broken_image,
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "The problem was resolved. Thank you for helping keep the environment clean! 🌱\nYou can download your certificate from the rewards section.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),


                // Feedback Button
                if (r['status'].toLowerCase() == "resolved" &&
                    (r['feedback_rating'] == null ||
                        r['feedback_rating'] == ""))
                  ElevatedButton(
                    onPressed: () => _showFeedbackDialog(r['ticket_id']),
                    child: const Text("Give Feedback"),
                  ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
