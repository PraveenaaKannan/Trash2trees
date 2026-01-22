import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true; // <-- for password toggle

  // Change this to your own backend URL
  final String baseUrl = 'http://10.144.16.64/trash2trees/login.php';

  void _showSnack(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Email and password are required");
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse(baseUrl);
    try {
      final response = await http
          .post(uri, body: {"email": email, "password": password})
          .timeout(const Duration(seconds: 15));

      print('LOGIN HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode != 200) {
        _showSnack('Server error: ${response.statusCode}. Check server & URL.');
        return;
      }

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        _showSnack('Invalid JSON from server.');
        return;
      }

      if (data['status'] == 'success') {
        final user = data['user'] ?? data;
        final args = <String, dynamic>{
          'name': user['name'] ?? 'User',
          'district': user['district'] ?? '',
          'profile_pic': user['profile_pic'] ?? '',
          'reports_submitted': user['reports_submitted'] ?? 0,
          'trees_planted': user['trees_planted'] ?? 0,
        };

        Navigator.pushReplacementNamed(
          context,
          '/dashboard_registered',
          arguments: args,
        );
      } else {
        _showSnack(data['message'] ?? 'Login failed');
      }
    } on SocketException {
      _showSnack('Network error – could not reach server.');
    } on TimeoutException {
      _showSnack('Request timed out. Try again.');
    } catch (e) {
      _showSnack('Something went wrong.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // soft green background
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- App Logo & Name ----------
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: AssetImage('assets/logo.png'),
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trash2Trees',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ---------- Email ----------
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // ---------- Password with toggle ----------
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.green,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ---------- Login Button ----------
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---------- Register Navigation ----------
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
