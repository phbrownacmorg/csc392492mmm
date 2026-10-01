import 'package:flutter/material.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Map<String, dynamic>> pendingConnections = [];
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
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      final connectionsSnapshot = await FirebaseFirestore.instance
          .collection('Connections')
          .where('studentId', isEqualTo: currentUser.uid)
          .get();

      pendingConnections = [];

      for (final connectionDoc in connectionsSnapshot.docs) {
        final connectionData = connectionDoc.data();

        if (connectionData['accepted'] == null) {
          final instructorId = connectionData['instructorId'];

          final instructorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(instructorId)
              .get();

          final instructorData = instructorDoc.data();
          final instructorFirstName = instructorData?['firstName'] ?? '';
          final instructorLastName = instructorData?['lastName'] ?? '';

          pendingConnections.add({
            'id': connectionDoc.id,
            ...connectionData,
            'instructorName':
                '$instructorFirstName $instructorLastName'.trim(),
          });
        }
      }
    }      

    final acceptedConnectionsSnapshot = await FirebaseFirestore.instance
        .collection('Connections')
        .where('studentId', isEqualTo: currentUser?.uid)
        .get();

    final instructorNames = <String>[];

    for (final connection in acceptedConnectionsSnapshot.docs) {
      final connectionData = connection.data();

      if (connectionData['accepted'] != null) {
        final instructorId = connectionData['instructorId'];

        final instructorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(instructorId)
            .get();

        if (instructorDoc.exists) {
          final instructorData = instructorDoc.data();
          final firstName = instructorData?['firstName'] ?? '';
          final lastName = instructorData?['lastName'] ?? '';

          instructorNames.add('$firstName $lastName'.trim());
        }
      }
    }

    // print('User data $data');  // Debug check
    if (data != null) {
      setState(() {
        _isEnabled = true;
        firstName = data['firstName'] ?? 'Guest';
        lastName = data['lastName'] ?? '';
        email = data['email'] ?? '[No Email Linked]';
        role = data['role'] ?? '[No Role Set]';
        phone = data['phone'] ?? '[No Phone Number Set]';
        myInstructors = instructorNames.isNotEmpty
            ? instructorNames.join(', ')
            : '[No Instructors Set]';
        problems = data['problems']?.join(', ') ?? '[No Problems Found]';
        assignedSheets = data['assignedSheets']?.join(', ') ?? '[No Sheets Assigned]';
        completedSheets = data['completedSheets']?.join(', ') ?? '[No Sheets Completed]';
      });
    } else {
      print('Unable to access profile data');
    }
  }

  Future<void> _acceptConnection(Map<String, dynamic> connection) async {
    final connectionId = connection['id'];

    await FirebaseFirestore.instance
        .collection('Connections')
        .doc(connectionId)
        .update({
      'accepted': FieldValue.serverTimestamp(),
    });

    await _loadProfile();

    if (!mounted) return;

    snackBarMessage('Instructor invitation accepted.');
  }

  Future<void> _rejectConnection(Map<String, dynamic> connection) async {
    final connectionId = connection['id'];

    await FirebaseFirestore.instance
        .collection('Connections')
        .doc(connectionId)
        .delete();

    await _loadProfile();

    if (!mounted) return;

    snackBarMessage('Instructor invitation rejected.');
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

            if (pendingConnections.isNotEmpty) ...[
              const Text(
                'Pending Instructor Invitations:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              ...pendingConnections.map(
                (connection) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${connection['instructorName']} has invited you to join their studio.',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _acceptConnection(connection),
                      child: const Text('Accept'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _rejectConnection(connection),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
            ],
            
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
            // Soon: Add a way to display information on assigned sheets and completed sheets (hint: both fields are initialized as empty lists in auth_service.dart).
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
