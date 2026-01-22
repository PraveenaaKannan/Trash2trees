import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'dashboard_registered.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  File? profilePic;
  bool loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picked != null) {
        setState(() => profilePic = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error opening camera: $e')));
    }
  }

  Future<void> registerUser() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        districtController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => loading = true);

    final uri = Uri.parse('http://10.144.16.64/trash2trees/register.php');
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = nameController.text.trim();
    request.fields['email'] = emailController.text.trim();
    request.fields['phone'] = phoneController.text.trim();
    request.fields['district'] = districtController.text.trim();
    request.fields['password'] = passwordController.text;

    if (profilePic != null) {
      request.files
          .add(await http.MultipartFile.fromPath('profile_pic', profilePic!.path));
    }

    try {
      final streamedResponse = await request.send();
      final respStr = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${streamedResponse.statusCode}')));
        setState(() => loading = false);
        return;
      }

      final decoded = json.decode(respStr);

      if (decoded['status'] == 'success') {
        // Navigate to RegisteredDashboard without reportsSubmitted/treesPlanted
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegisteredDashboard(
              name: nameController.text.trim(),
              district: districtController.text.trim(),
              profilePic: profilePic?.path ?? "",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['message'] ?? 'Registration failed')));
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error — cannot reach server')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _greenInput(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon: Icon(Icons.edit, color: Colors.green[700]),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _passwordInput(TextEditingController controller, String label) {
    final bool isConfirm = label.toLowerCase().contains('confirm');
    final bool show = isConfirm ? _showConfirmPassword : _showPassword;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: !show,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility : Icons.visibility_off, color: Colors.green[700]),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _showConfirmPassword = !_showConfirmPassword;
                } else {
                  _showPassword = !_showPassword;
                }
              });
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    districtController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.green[700];

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 90),
                const SizedBox(height: 10),
                Text(
                  'Trash2Trees',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.green[100],
                    backgroundImage: profilePic != null ? FileImage(profilePic!) : null,
                    child: profilePic == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 25),
                _greenInput(nameController, 'Full Name'),
                _greenInput(emailController, 'Email', keyboardType: TextInputType.emailAddress),
                _greenInput(phoneController, 'Phone', keyboardType: TextInputType.phone),
                _greenInput(districtController, 'District'),
                _passwordInput(passwordController, 'Password'),
                _passwordInput(confirmPasswordController, 'Confirm Password'),
                const SizedBox(height: 25),
                loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

