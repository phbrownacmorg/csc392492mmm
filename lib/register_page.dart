import 'package:flutter/material.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passTextController = TextEditingController();
  final FancyPasswordController _passwordController = FancyPasswordController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _passTextController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        // throw FirebaseAuthException(code: 'email-already-in-use');
        // throw FirebaseAuthException(code: 'weak-password');
        // throw FirebaseAuthException(code: '');
        await authService.value.createAccount(
          email: _emailController.text,
          password: _passTextController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          role: _roleController.text,
        );
        snackBarMessage('Registration successful');
        popPage(); // Go back to login page after registering
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'An account already exists for that email.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else {
          message = e.message ?? 'An error occurred.';
        }
        snackBarMessage(message);
      }
    }
  }

  // popPage and snackBarMessage contain the exact same context logic, but are now kept
  // inside their own function definitions so that VS Code stops complaining about handling
  // context within an async function -- it's also a bit cleaner looking.
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
        title: Text('Register', style: TextStyle(color: Colors.white)),
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
              DropdownMenuFormField(  /// Select User Role
                controller: _roleController,
                width: double.infinity,
                label: const Text('Select Role'),
                requestFocusOnTap: false,
                enableSearch: false,
                dropdownMenuEntries: <DropdownMenuEntry>[
                  DropdownMenuEntry(value: 'Student', label: 'Student'),
                  DropdownMenuEntry(value: 'Instructor', label: 'Instructor'),
                ],
                validator: (last) {
                  if (last == null || last.isEmpty) {
                    return 'Select a user role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(  /// Enter First Name
                controller: _firstNameController,
                decoration: InputDecoration(
                  hintText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (first) {
                  if (first == null || first.isEmpty) {
                    return 'Enter a first name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(  /// Enter Last Name
                controller: _lastNameController,
                decoration: InputDecoration(
                  hintText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (last) {
                  if (last == null || last.isEmpty) {
                    return 'Enter a last name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(  /// Enter Email
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: [AutofillHints.email],
                // Validator only checks email syntax; there should also be a check
                // to make sure an email isn't already in use.
                validator: (email) => EmailValidator.validate(email ?? "")
                  ? null
                  : 'Enter a valid email',
              ),
              SizedBox(height: 20),
              FancyPasswordField(  /// Enter Password
                controller: _passTextController,
                passwordController: _passwordController,
                onChanged: (value) {
                  _passwordTextController.text = value;
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validationRules: <ValidationRule>{
                  DigitValidationRule(),
                  MinCharactersValidationRule(8),
                  UppercaseValidationRule(),
                  SpecialCharacterValidationRule(),
                },
                hasStrengthIndicator: true,
                hasShowHidePassword: true,
                validator: (_) {
                  return (_passwordController.areAllRulesValidated && 
                  _passTextController.text != "")
                      ? null
                      : 'Password does not meet requirements';
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    registerUser();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}