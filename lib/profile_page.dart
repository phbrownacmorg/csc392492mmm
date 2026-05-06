import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // Adjust the import path if your main.dart is in a different folder
import 'account_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    final name = appState.studentName ?? 'Guest';
    final problem = appState.selectedProblem?.name ?? 'None';

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
              'Name: $name',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Selected Problem: $problem',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
                );
              },
              child: const Text('Account Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
