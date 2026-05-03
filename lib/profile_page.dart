import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Old import
// import 'package:music_app/main.dart';  // Old import
import 'package:music_app/services/auth_service.dart';

// Eventually: add condition that toggles Sign Out button (currently set to null)
// (Also, make the Sign Out button actually work)

// If you can implement the Sign Out button on the homepage and get it working,
// please do that. I tried to add a button there, but I kept having issues.

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
        role = data['role'];
      });
    }
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
              'Selected Problem: $problem',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: null,
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
