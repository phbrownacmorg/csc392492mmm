import 'package:flutter/material.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = 'Guest';
  String lastName = '';
  String email = '[Not Logged In]';
  String role = '[Not Logged In]';
  String phone = '[Not Logged In]';
  String myInstructors = '[Not Logged In]';
  String problems = '[Not Logged In]';
  String assignedSheets = '[Not Logged In]';
  String completedSheets = '[Not Logged In]';
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
    print('User data $data');  // Debug check
    if (data != null) {
      setState(() {
        _isEnabled = true;
        firstName = data['firstName'] ?? 'Guest';
        lastName = data['lastName'] ?? '';
        email = data['email'] ?? '[No Email Linked]';
        role = data['role'] ?? '[No Role Set]';
        phone = data['phone'] ?? '[No Phone Number Set]';
        myInstructors = data['myInstructors'].join(', ') ?? '[No Instructors Set]';
        problems = data['problems'].join(', ') ?? '[No Problems Found]';
        assignedSheets = data['assignedSheets'].join(', ') ?? '[No Sheets Assigned]';
        completedSheets = data['completedSheets'].join(', ') ?? '[No Sheets Completed]';
      });
    } else {
      print('Unable to access profile data');
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
    // String problem = 'None';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: _isEnabled
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfile()),
                  );
                } : null,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                'Edit Profile',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
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
              'Phone: $phone',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'My Instructors: $myInstructors',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Problems: $problems',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Assigned Sheets: $assignedSheets',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Completed Sheets: $completedSheets',
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