import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    // final name = appState.studentName ?? 'Guest';
    // final name = '[Not signed in]';
    final problem = appState.selectedProblem?.name ?? 'None';

    final user = FirebaseAuth.instance.currentUser;
    String? email = user != null ? user.email : '[Not signed in]';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email: $email',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Selected Problem: $problem',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
