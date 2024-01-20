import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:haulier_tracking_app/signin_screen.dart';

class SignUpScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers for the text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Register Your Account"),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _header(),
                  _inputField(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _header() {
    return Column(
      children: [
        const SizedBox(height: 7),
        Text(
          "Register Your Account",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text("Enter your details to create an account"),
      ],
    );
  }

  // Display the input fields and registration button
  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name TextField
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),

        // Email TextField
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: "Email",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 10),

        // Username TextField
        TextField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: "Username",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),

        // Password TextField
        TextField(
          controller: passwordController,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.purple.withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),

        // Registration Button
        ElevatedButton(
          onPressed: () {
            _performRegistration(context);
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.purple,
          ),
          child: const Text(
            "Register",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),

        // Login option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Already have an account? "),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInScreen(),
                  ),
                );
              },
              child: Text(
                "Login",
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Perform user registration
  void _performRegistration(BuildContext context) async {
    // Check if all input fields are filled
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all the details'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final url = Uri.https(
      'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
      'user.json',
    );

    try {
      // POST request to register the user
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
          {
            'name': nameController.text,
            'email': emailController.text,
            'username': usernameController.text,
            'password': passwordController.text,
          },
        ),
      );

      print("Response Body: ${response.body}");
      print("Status Code: ${response.statusCode}");

      // Check if the registration was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String userId = responseData['name'];
        print("Registration successful, User ID: $userId");

        // Success message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful! User ID: $userId'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print("Registration failed: ${response.statusCode}");
        final Map<String, dynamic> errorData = json.decode(response.body);
        print("Error Message: ${errorData['error']}");
      }
    } catch (error) {
      print("Error during registration: $error");
    }
  }
}
