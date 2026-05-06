import 'package:flutter/material.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:music_app/services/auth_service.dart';

class EditProfile extends StatefulWidget {
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();
  String firstName = 'Guest';
  String lastName = '';
  String oldEmail = '[Not Logged In]';
  String myInstructor = '[Not Logged In]';
  String role = '[Not Logged In]';
  String phone = '[Not Logged In]';
  bool _isChecked = false;
  bool _deleteButton = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  late TextEditingController _firstNameController = TextEditingController(text: firstName);
  late TextEditingController _lastNameController = TextEditingController(text: lastName);
  late TextEditingController _roleController = TextEditingController(text: role);
  late TextEditingController _emailController = TextEditingController(text: oldEmail);
  late TextEditingController _passTextController = TextEditingController();
  late FancyPasswordController _passwordController = FancyPasswordController();

  Future<void> _loadProfile() async {
    final data = await AuthService().getUserData();
    if (data != null) {
      setState(() {
        firstName = data['firstName'];
        lastName = data['lastName'];
        oldEmail = data['email'];
        myInstructor = data['myInstructor'] ?? '[No Instructor Set]';
        role = data['role'];
        phone = data['phone'] ?? '[No Phone Number Set]';
      });
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _roleController = TextEditingController(text: role);
    _emailController = TextEditingController(text: oldEmail);
    _passTextController = TextEditingController();
    _passwordController = FancyPasswordController();
    }
  }

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

  Future<void> _saveChanges() async {
    final newEmail = _emailController.text.toLowerCase();
    bool emailExists;
    if (newEmail == oldEmail) {
      emailExists = false;
    } else {
      emailExists = await authService.value.doesEmailExist(_emailController.text.toLowerCase());
    }
    if (_profileFormKey.currentState!.validate() && !emailExists) {
      try {
        await authService.value.editProfile(
          oldEmail: oldEmail,
          newEmail: newEmail,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          role: _roleController.text,
        );
        snackBarMessage('Your changes have been saved.');
        popPage();
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'email-already-in-use') {
          // Won't work — we have Firebase email enumeration protection enabled
          message = 'An account already exists for that email.';
        } else if (e.code == 'requires-recent-login') {
          message = 'Error. Please try signing out then logging back in.';
        } else {
          message = e.message ?? 'An error occurred.';
        }
        snackBarMessage(message);
      }
    } else if (emailExists) {
      snackBarMessage('An account already exists for that email.');
    } else {
      snackBarMessage('Something went wrong.');
    }
  }

  Future<void> _updatePassword() async {
    if (_passFormKey.currentState!.validate()) {
      try {
        await authService.value.updatePassword(
          password: _passTextController.text,
        );
        snackBarMessage('Password Updated.');
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'requires-recent-login') {
          message = 'Error. Please try signing out then logging back in.';
        } else if (e.code == 'user-not-found') {
          message = 'User no longer exists.';
        } else {
          message = e.message ?? 'An error occurred.';
        }
        snackBarMessage(message);
      }
    } else {
      snackBarMessage('Something went wrong.');
    }
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
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Form(
            key: _profileFormKey,
            child: Column(
              children: [
                Text(
                  'Update Account Information',
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
                SizedBox(height: 20),
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
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 70),
              ],
            ),
          ),
          Form(
            key: _passFormKey,
            child: Column(
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(fontSize: 25, color: Colors.black),
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
                    return (_passwordController.areAllRulesValidated && 
                    _passTextController.text != "")
                        ? null
                        : 'Password does not meet requirements';
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Update Password',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 70),
              ],
            ),
          ),
          Form(
            // key: _passFormKey,
            child: Column(
              children: [
                Text(
                  'Account Deletion',
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
                SizedBox(height: 20),
                CheckboxListTile(
                  title: Text(
                    'I understand that account deletion is permanent.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  value: _isChecked, 
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isChecked = newValue!;
                      _deleteButton = _isChecked;
                    });
                  }
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _deleteButton
                    ? () {
                      print('Working!');
                    } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Delete Account',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
