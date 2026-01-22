import 'package:flutter/material.dart';
import 'qr_report_form.dart';
import 'report_without_qr_form.dart';

class ReportPage extends StatelessWidget {
  final String userName; // Pass from dashboard

  const ReportPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC8E6C9), // Light peppy green background
      appBar: AppBar(
        title: const Text("Report a Complaint"),
        backgroundColor: const Color(0xFF4CAF50), // Headline color
        foregroundColor: Colors.white, // White text for better contrast
      ),
      body: SingleChildScrollView( // 👈 Added scroll view
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 👇 Image above "Scan with QR"
              ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded shape
                child: Image.asset(
                  "assets/qr.png",
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // Scan with QR button (width increased)
              SizedBox(
                width: 250, // 👈 Increased width
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Scan with QR"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRReportForm(userName: userName),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 👇 New Image between Scan & Report
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/complaint.png", // Add your middle image here
                  width: 300,
                  height: 450,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // Report Without QR button (width increased)
              SizedBox(
                width: 250, // 👈 Increased width
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.report_problem),
                  label: const Text("Report Without QR"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportWithoutQRForm(userName: userName),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 👇 Image below "Report Without QR"
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/download.png",
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
