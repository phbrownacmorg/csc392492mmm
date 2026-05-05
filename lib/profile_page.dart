import 'package:flutter/material.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// TODO: Add a way to edit user profile. Possibly, this could take the form of a new account settings page that can be accessed from the profile page. This page would allow important account functions, such as setting a phone number, changing email/password, and deleting an account (though most of the logic would be handled by auth_service.dart).

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = 'Guest';
  String lastName = '';
  String email = '[Not Logged In]';
  String myInstructor = '[Not Logged In]';
  String role = '[Not Logged In]';
  String phone = '[Not Logged In]';
  bool _isEnabled = false;

  Future<void> _submitSignOut() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await authService.value.signOut();
        snackBarMessage('You have been signed out.');
        popPage(); // Go back to home page after signing out
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'network-request-failed') {
          message = 'Network Error. Please try again.';
        } else if (e.code == 'internal-error') {
          message = 'Internal Error. Please try again.';
        } else {
          message = e.message ?? 'An error occurred.';
        }
        snackBarMessage(message);
      }
    } else {
      snackBarMessage('Something went wrong.');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthService().getUserData();
    if (data != null) {
      setState(() {
        firstName = data['firstName'];
        lastName = data['lastName'];
        email = data['email'];
        myInstructor = data['myInstructor'] ?? '[No Instructor Set]';
        role = data['role'];
        phone = data['phone'] ?? '[No Phone Number Set]';
      });
      _isEnabled = true;
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
    // final appState = Provider.of<MyAppState>(context);
    String problem = 'None';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: $firstName $lastName',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Email: $email',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Role: $role',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'My Instructor: $myInstructor',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Phone: $phone',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Selected Problem: $problem',
              style: const TextStyle(fontSize: 20),
            ),
            // TODO: Add a way to display information on assigned sheets and completed sheets (hint: both fields are initialized as empty lists in auth_service.dart).
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isEnabled
                ? () => _submitSignOut()
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      )
    );
  }
}
