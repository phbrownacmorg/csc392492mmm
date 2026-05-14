import 'package:flutter/material.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditProfile extends StatefulWidget {
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();
  // Account Information
  String role = '[Not Logged In]';
  String firstName = 'Guest';
  String lastName = '';
  String oldEmail = '[Not Logged In]';
  String oldPhone = '';

  // Currently unused
  String myInstructors = '[Not Logged In]';
  String problems = '[Not Logged In]';
  String assignedSheets = '[Not Logged In]';
  String completedSheets = '[Not Logged In]';

  // Extra data
  String? phoneISO = 'US';
  String? phoneDialCode = '+1';
  String _formattedPhone = '';
  bool _isChecked = false;
  bool _deleteButton = false;
  bool _isPhoneValid = false;

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
    // print('User data $data');  // Debug check
    if (data != null) {
      // print('Profile data is not null.');  // Debug check
      setState(() {
        role = data['role'];
        firstName = data['firstName'];
        lastName = data['lastName'];
        oldEmail = data['email'];
        oldPhone = data['phone'] ?? '';
        myInstructors = data['myInstructors'].join(', ') ?? '[No Instructors Set]';
        problems = data['problems'].join(', ') ?? '[No Problems Found]';
        assignedSheets = data['assignedSheets'].join(', ') ?? '[No Sheets Assigned]';
        completedSheets = data['completedSheets'].join(', ') ?? '[No Sheets Completed]';
      });
      if (oldPhone != '') {
        final phoneInfo = await PhoneNumber.getRegionInfoFromPhoneNumber(oldPhone);
        phoneISO = phoneInfo.isoCode;
        phoneDialCode = phoneInfo.dialCode;
      }
      _firstNameController = TextEditingController(text: firstName);
      _lastNameController = TextEditingController(text: lastName);
      _roleController = TextEditingController(text: role);
      _emailController = TextEditingController(text: oldEmail);
      _passTextController = TextEditingController();
      _passwordController = FancyPasswordController();
    } else {
      print('Unable to access profile data');
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
    final newPhone = _formattedPhone;
    // Is the email already in use?
    bool emailExists;
    if (newEmail == oldEmail) {
      emailExists = false;
    } else {
      emailExists = await authService.value.doesEmailExist(newEmail);
    }
    // Is the phone number already in use?
    bool phoneExists;
    if (newPhone == oldPhone) {
      phoneExists = true;
    } else {
      phoneExists = await authService.value.doesPhoneExist(newPhone);
    }
    // Are the attempted changes valid?
    if (_profileFormKey.currentState!.validate() && !emailExists) {
      // Try to save changes on Firebase and Firestore
      try {
        await authService.value.editProfile(
          role: _roleController.text,
          oldEmail: oldEmail,
          newEmail: newEmail,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: newPhone,
        );
        if (newEmail != oldEmail && newEmail != '') {
          authService.value.updateEmail(email: newEmail);
          snackBarMessage('Please check your inbox to verify your new email address');
        }
        // If the phone number changed, verify the new number on Firebase
        if (!phoneExists && newPhone != '') {
          // Soon: add phone number as a new sign-in provider on Firebase console
          authService.value.verifyPhone(phone: newPhone);
        }
        snackBarMessage('Your changes have been saved.');
        popPage();
        popPage();  // Sends user back to home page, forcing a profile reload
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

  Future<void> _deleteUser() async {
    final User? user = authService.value.currentUser;

    if (user != null) {
      try {
        authService.value.deleteAccount(user: user);
        snackBarMessage('Your account has been deleted.');
        authService.value.signOut();
        popPage();
        popPage();
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'requires-recent-login') {
          message = 'Error. Please try signing out then logging back in.';
        } else {
          message = e.message ?? 'An error occurred.';
        }
        snackBarMessage(message);
      } catch (e) {
        snackBarMessage('Error: $e');
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
                  validator: (email) => EmailValidator.validate(email ?? "")
                    ? null
                    : 'Enter a valid email',
                ),
                SizedBox(height: 20),
                InternationalPhoneNumberInput(  /// Optional: Add Phone Number
                  initialValue: PhoneNumber(
                    phoneNumber: oldPhone,
                    isoCode: phoneISO,
                    dialCode: phoneDialCode,
                  ),
                  onInputChanged: (PhoneNumber number) {
                    _formattedPhone = number.phoneNumber ?? '';
                  },
                  onInputValidated: (bool value) {
                    _isPhoneValid = value;
                  },
                  // autoValidateMode: AutovalidateMode.always,
                  countries: ['US', 'CA', 'MX'],  // Can add more countries later
                  selectorConfig: SelectorConfig(
                    selectorType: PhoneInputSelectorType.DROPDOWN,
                    setSelectorButtonAsPrefixIcon: true,
                    trailingSpace: false,
                    showFlags: true,
                    useEmoji: true,
                  ),
                  inputDecoration: InputDecoration(
                    hintText: '[OPTIONAL] Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  autofillHints: [AutofillHints.telephoneNumberLocalPrefix],
                  validator: (phone) {
                    if (phone == null || phone.isEmpty) {
                      return null;
                    } else if (!_isPhoneValid) {
                      return 'Invalid phone number.';
                    } else {
                      return null;
                    }
                  },
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
                      _deleteUser();
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
                SizedBox(height: 70),
              ],
            ),
          ),
          Form(
            // key: _passFormKey,
            child: Column(
              children: [
                Text(
                  'Login with Other Services',
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
                SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => snackBarMessage('Coming Soon!'),
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => snackBarMessage('Coming Soon!'),
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
              SizedBox(height: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
