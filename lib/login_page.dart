import 'package:flutter/material.dart';
import 'register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    if (_formKey.currentState!.validate() && 
      FirebaseAuth.instance.currentUser == null) {
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
    } else if (FirebaseAuth.instance.currentUser != null) {
      snackBarMessage('User is already logged in.');
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
              SizedBox(height: 24),
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
              // Divider with "or" label
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 24),
              // Google Button
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  minimumSize: Size(double.infinity, 52),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.earbuds, size: 20),
                    SvgPicture.asset('assets/Google_G_logo.svg', width: 24, height: 24),
                    SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: Color(0xFF3C4043),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Facebook Button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  minimumSize: Size(double.infinity, 52),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.facebook, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Continue with Facebook',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
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