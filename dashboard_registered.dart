import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'report_page.dart';
import 'my_reports_page.dart';
import 'my_rewards.dart';

class RegisteredDashboard extends StatefulWidget {
  final String name;
  final String district;
  final String profilePic;

  const RegisteredDashboard({
    Key? key,
    required this.name,
    required this.district,
    required this.profilePic,
  }) : super(key: key);

  @override
  _RegisteredDashboardState createState() => _RegisteredDashboardState();
}

class _RegisteredDashboardState extends State<RegisteredDashboard> {
  int reportsSubmitted = 0;
  int treesPlanted = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserReports();
  }

  Future<void> fetchUserReports() async {
    final uri = Uri.parse('http://10.144.16.64/trash2trees/get_reports.php');

    try {
      final response = await http.post(uri, body: {'user_name': widget.name});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        int totalEcoPoints = 0;
        for (var report in data) {
          totalEcoPoints += int.tryParse(report['eco_points'].toString()) ?? 0;
        }

        setState(() {
          reportsSubmitted = data.length;
          treesPlanted = totalEcoPoints; // using eco_points as treesPlanted
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => loading = false);
      print('Error fetching reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: widget.profilePic.isNotEmpty
                        ? NetworkImage(widget.profilePic)
                        : null,
                    child: widget.profilePic.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, ${widget.name} 👋",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "District: ${widget.district}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Reports Submitted",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$reportsSubmitted",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Eco Points",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$treesPlanted 🌳",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.camera_alt,
                  label: "Report Bin Issue",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportPage(userName: widget.name),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.article,
                  label: "My Reports",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyReportsPage(userName: widget.name),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.emoji_events,
                  label: "My Rewards",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  MyRewardsPage(userEmail: widget.name),
                      ),
                    );

                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.settings,
                  label: "Settings",
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
