import 'package:flutter/material.dart';
import 'register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:fancy_password_field/fancy_password_field.dart';

// Eventually: currently, the app prevents a user from logging in after they're
// already logged in. Make it so the email + password validators are hidden when
// this happens (i.e., 'Enter your...' doesn't appear.)

// In the future: implement a way to change your email and/or password.

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    // final emailExists = await authService.value.doesEmailExist(_emailController.text.toLowerCase());
    User? user = FirebaseAuth.instance.currentUser;
    if (_formKey.currentState!.validate() && user == null) {
      try {
        await authService.value.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        snackBarMessage('Login successful.');
        popPage(); // Go back to home page after logging in
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'invalid-credential') {
          message = 'Incorrect email or password.';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address.';
        } else {
          message = e.message ?? 'An error occurred.';
        }
        snackBarMessage(message);
      }
    } else if (user != null) {
      snackBarMessage('User is already logged in.');
    } else if (!_formKey.currentState!.validate()) {
      snackBarMessage('Please enter valid credentials.');
    } else {
      snackBarMessage('Something went wrong.');
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  void popPage() {
    Navigator.pop(context);
  }

  void snackBarMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // TODO: Add ability to sign in with phone number. Ideally, email and phone number would share a text field. Likely, most of the logic would be handled by auth_service.dart.
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your email' : null,
              ),
              SizedBox(height: 20),
              FancyPasswordField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                hasStrengthIndicator: false,
                hasShowHidePassword: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your password' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: Text(
                  'Login with Google',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: Text(
                  'Login with Facebook',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _navigateToRegister,
                child: Text(
                  "Don't have an account? Register here",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Container(
                color: Colors.grey[300],
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: Center(child: Text('Bottom Banner')),
              ),
            ],
          ),
        )
      ),
    );
  }
}