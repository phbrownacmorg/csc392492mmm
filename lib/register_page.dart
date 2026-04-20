import 'package:flutter/material.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:email_validator/email_validator.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FancyPasswordController _passwordController = FancyPasswordController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (_formKey.currentState!.validate()) {
      // Database write goes here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful')),
      );
      Navigator.pop(context); // Go back to login page after registering
    }
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
              TextFormField(
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
              FancyPasswordField(
                passwordController: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validationRules: <ValidationRule>{
                  MinCharactersValidationRule(8),
                  UppercaseValidationRule(),
                  DigitValidationRule(),
                },
                hasStrengthIndicator: true,
                hasShowHidePassword: true,
                validator: (_) {
                  return _passwordController.areAllRulesValidated
                      ? null
                      : 'Password does not meet requirements';
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitRegister,
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