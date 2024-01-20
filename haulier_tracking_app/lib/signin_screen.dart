import 'package:flutter/material.dart';
import 'intro_screen.dart';
import 'signup_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignInScreen extends StatelessWidget {
  SignInScreen({Key? key});

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _logo(),
                  _header(context),
                  _inputField(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _logo() {
    return Center(
      child: Image.asset(
        "images/logo.png",
        width: 140,
      ),
    );
  }

  _header(context) {
    return Column(
      children: [
        const SizedBox(height: 7),
        Text(
          "Welcome Back",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text("Enter your credentials to login"),
      ],
    );
  }

  // Display the input fields and login button
  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            prefixIcon: const Icon(Icons.email),
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

        // Login Button
        ElevatedButton(
          onPressed: () {
            _performLogin(context);
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.purple,
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),

        // Sign Up option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account? "),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(),
                  ),
                );
              },
              child: Text(
                "SignUp",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Perform login
  void _performLogin(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    final url = Uri.https(
        'hauliertrackingapp-default-rtdb.asia-southeast1.firebasedatabase.app',
        'user.json');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic>? usersData = json.decode(response.body);

        if (usersData != null) {
          bool isAuthenticated = false;

          // Check user credentials
          usersData.forEach((userId, userData) {
            if (userData['username'] == username &&
                userData['password'] == password) {
              isAuthenticated = true;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(),
                ),
              );
            }
          });

          // Error message if authentication fails
          if (!isAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Invalid credentials"),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        _showErrorSnackBar(context, 'Invalid response format from the server.');
      }
    } catch (error) {
      _showErrorSnackBar(context, 'Error during login: $error');
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(BuildContext context, String errorMessage) {}
}
