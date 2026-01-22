import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class MyRewardsPage extends StatefulWidget {
  final String userEmail;

  const MyRewardsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _MyRewardsPageState createState() => _MyRewardsPageState();
}

class _MyRewardsPageState extends State<MyRewardsPage> {
  bool loading = true;
  int ecoPoints = 0;
  int maxPoints = 50; // initial threshold for certificate

  @override
  void initState() {
    super.initState();
    fetchRewards();
  }

  Future<void> fetchRewards() async {
    final uri = Uri.parse('http://10.144.16.64/trash2trees/get_rip.php');
    try {
      final response = await http.post(uri, body: {'email': widget.userEmail});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int totalPoints = 0;
        for (var report in data) {
          totalPoints += 10; // 10 points per resolved complaint
        }

        // Update maxPoints dynamically based on earned points
        while (totalPoints > maxPoints) {
          maxPoints += 50;
        }

        setState(() {
          ecoPoints = totalPoints;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => loading = false);
      print('Error fetching rewards: $e');
    }
  }

  Future<void> generateCertificate() async {
    final pdf = pw.Document();

    // Load logo from network or asset
    final Uint8List logoBytes = (await http.get(
        Uri.parse('https://i.ibb.co/4f0v5zP/logo.png'))) // replace with your logo URL
        .bodyBytes;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green, width: 4),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Logo
                pw.Image(pw.MemoryImage(logoBytes), height: 80),
                pw.SizedBox(height: 20),

                // Ribbon Banner
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Eco-Points Certificate',
                    style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Divider(color: PdfColors.grey, thickness: 1),
                pw.SizedBox(height: 16),

                // Certificate text
                pw.Text(
                  'This certificate is proudly presented to',
                  style: pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  widget.userEmail,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'for earning $ecoPoints eco-points 🌳',
                  style: pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Thank you for your contribution to a greener environment!',
                  style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 40),

                // Signature / Seal placeholder
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          height: 40,
                          width: 120,
                          color: PdfColors.blue100,
                          child: pw.Center(
                            child: pw.Text('Authorized Sign', style: pw.TextStyle(fontSize: 12)),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Officer Name', style: pw.TextStyle(fontSize: 12))
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          height: 40,
                          width: 120,
                          color: PdfColors.blue100,
                          child: pw.Center(
                            child: pw.Text('Seal', style: pw.TextStyle(fontSize: 12)),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Trash2Trees', style: pw.TextStyle(fontSize: 12))
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }


  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.green[700]; // changed theme to blue

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
        backgroundColor: themeColor,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Eco Points Progress Box =====
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.green[50], // blue theme
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Eco Points Progress',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: ecoPoints / maxPoints,
                      minHeight: 20,
                      backgroundColor: Colors.green[100],
                      color: themeColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$ecoPoints / $maxPoints points 🌳',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Earn 10 points for each resolved complaint.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== Certificate & Tree Box =====
            if (ecoPoints >= maxPoints)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.card_giftcard,
                          size: 60, color: Colors.green),
                      const SizedBox(height: 10),
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'You have earned a certificate and a tree from the nursery 🌱',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: generateCertificate,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('View / Download Certificate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Connect to nursery for tree
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Tree request sent to nursery! 🌳')));
                        },
                        icon: const Icon(Icons.local_florist),
                        label: const Text('Get Tree from Nursery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
