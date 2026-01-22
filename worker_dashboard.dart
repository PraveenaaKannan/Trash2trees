import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'solve_complaint.dart';

class WorkerDashboard extends StatefulWidget {
  final String workerId;
  const WorkerDashboard({Key? key, required this.workerId}) : super(key: key);

  @override
  _WorkerDashboardState createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  List notifications = [];
  bool _isLoading = true;

  final String fetchUrl = "http://10.144.16.64/trash2trees/fetch_notifications.php";
  final String markSolvedUrl = "http://10.144.16.64/trash2trees/mark_solved.php";

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(fetchUrl),
        body: {"worker_id": widget.workerId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            notifications = data['notifications'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsSolved(String ticketId) async {
    try {
      final response = await http.post(
        Uri.parse(markSolvedUrl),
        body: {"ticket_id": ticketId},
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        // Refresh notifications
        _fetchNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Dashboard"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No Notifications"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final isSolved = notif['status'] == "Resolved";

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text("Ticket: ${notif['ticket_id'] ?? 'N/A'}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif['message'] ?? "No message"),
                  Text("Status: ${notif['status']}"),
                ],
              ),
              trailing: isSolved
                  ? const Text(
                "Solved ✅",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : ElevatedButton(
                onPressed: () async {
                  // Navigate to solve page
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolveComplaintPage(
                        ticketId: notif['ticket_id'] ?? '',
                      ),
                    ),
                  );

                  // If complaint solved, update backend
                  if (result == true) {
                    await _markAsSolved(notif['ticket_id']);
                  }
                },
                child: const Text("Solve"),
              ),
            ),
          );
        },
      ),
    );
  }
}
