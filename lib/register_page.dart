import 'package:flutter/material.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
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

  final FancyPasswordController _passwordController =
      FancyPasswordController();

      final TextEditingController _confirmPassTextController =
    TextEditingController();

  
  // Tracks whether registration is currently happening.
  // This prevents users from spamming the register button.
  bool _isLoading = false;

  @override
  void dispose() {

    
    // Dispose controllers when page is removed from memory.
    // Prevents memory leaks.
    _firstNameController.dispose();
    _lastNameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _passTextController.dispose();
    _passwordController.dispose();
    _confirmPassTextController.dispose();

    super.dispose();
  }

  Future<void> _submitRegister() async {

    
    // Extra protection against multiple clicks.
    // If already loading, stop immediately.
    if (_isLoading) return;

    
    // Turn loading ON before async work starts.
    //button disables, spinner appears
    setState(() => _isLoading = true);

    
    // Validate form BEFORE contacting Firebase.
    //
    // WHY?
    // Without this:
    // - Firebase gets contacted even if fields are empty
    // - unnecessary network requests happen
    // - slower app
    //  are fields valid?
    if (!_formKey.currentState!.validate()) {

      
      // If validation fails, stop loading immediately.
      // Otherwise button would stay disabled forever.
      setState(() => _isLoading = false);

      return;
    }

    try {

      // Checks if email already exists in Firebase.
      final emailExists = await authService.value
          .doesEmailExist(_emailController.text.toLowerCase());

      if (!emailExists) {

        // Creates Firebase account.
        await authService.value.createAccount(
          email: _emailController.text.toLowerCase(),

          password: _passTextController.text,

          firstName: _firstNameController.text,

          lastName: _lastNameController.text,

          role: _roleController.text,
        );

        // Success message shown to user.
        snackBarMessage('Registration successful');

        // Go back to login page after registering.
        popPage();

      } else {

        // If email already exists.
        snackBarMessage(
          'An account already exists for that email.',
        );
      }

    } on FirebaseAuthException catch (e) {

      // Handles Firebase-specific errors.
      String message;

      if (e.code == 'email-already-in-use') {

        // Won't work — we have Firebase
        // email enumeration protection enabled
        message = 'An account already exists for that email.';

      } else if (e.code == 'weak-password') {

        message = 'The password provided is too weak.';

      } else {

        // Generic Firebase error.
        message = e.message ?? 'An error occurred.';
      }

      snackBarMessage(message);

    } catch (e) {

      // Handles ANY unexpected error.
      // Examples:
      // - internet failure
      // - server crash
      // - unknown bug
      snackBarMessage('Error: $e');

    } finally {

      
      //
      // finally ALWAYS runs no matter what:
      // - success
      // - Firebase error
      // - unknown error
      //
      // WHY THIS MATTERS:
      // Without this, loading could stay true forever
      // and button would remain disabled.
      //
      // This guarantees UI cleanup.
      setState(() => _isLoading = false);
    }
  }

  void popPage() {

    // Navigates back to previous screen.
    Navigator.pop(context);
  }

  void snackBarMessage(String message) {

    // Reusable snackbar helper.
    // Makes code cleaner instead of repeating snackbar everywhere.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(
          'Register',
          style: TextStyle(color: Colors.white),
        ),

        centerTitle: true,

        backgroundColor: Colors.black,

        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(

        // Allows scrolling if keyboard covers screen.
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

                  DropdownMenuEntry(
                    value: 'Student',
                    label: 'Student',
                  ),

                  DropdownMenuEntry(
                    value: 'Instructor',
                    label: 'Instructor',
                  ),
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
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),

                keyboardType: TextInputType.emailAddress,

                validator: (email) =>
                    EmailValidator.validate(email ?? "")
                        ? null
                        : 'Enter a valid email',
              ),

              SizedBox(height: 20),

              FancyPasswordField(  /// Enter Password

                controller: _passTextController,

                passwordController: _passwordController,

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

                  return (
                    _passwordController.areAllRulesValidated &&
                    _passTextController.text != ""
                  )
                      ? null
                      : 'Password does not meet requirements';
                },
              ),

              SizedBox(height: 20),

            TextFormField( // confirm password 
              controller: _confirmPassTextController,
              obscureText: true,
              autovalidateMode: AutovalidateMode.onUserInteraction, //makes a single text field validate itself automatically while the user is typing or interacting with that field.
               onChanged: (_) {
                setState(() {});  //Every time the user types a letter, rebuild the widget
               },
    
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }

                if (value != _passTextController.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),

              SizedBox(height: 30),

              ElevatedButton(

                
                //
                // If loading is true:
                // button becomes disabled automatically.
                //
                // WHY?
                // Prevents multiple registration requests.
                onPressed:
                    _isLoading ? null : _submitRegister,

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.black,

                  padding: EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),

                
                //
                // Shows loading spinner while waiting.
                //
                // WHY THIS IMPROVES UX:
                // User visually understands:
                // "something is happening"
                //
                // Without this:
                // app feels frozen/confusing.
                child: _isLoading

                    ? SizedBox(

                        // Keeps spinner from becoming too large.
                        height: 20,
                        width: 20,

                        child: CircularProgressIndicator(

                          color: Colors.white,

                          // Makes spinner thinner/cleaner.
                          strokeWidth: 2,
                        ),
                      )

                    : Text(

                        'Register',

                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
