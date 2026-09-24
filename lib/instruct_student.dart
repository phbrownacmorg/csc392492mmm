import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'view_sheets_page.dart';

class InstructStudentPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const InstructStudentPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  Future<void> _removeStudent(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .update({
      'assignedSheets': [],
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('StudentOf')
        .where('studentId', isEqualTo: studentId)
        .where('instructorId', isEqualTo: currentUser.uid)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    if (!context.mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(studentName),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewSheetsPage(
                      studentId: studentId,
                    ),
                  ),
                );
              },
              child: const Text('View Sheets'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final shouldRemove = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Student'),
                    content: Text(
                      'Are you sure you want to remove $studentName?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );

                if (shouldRemove == true && context.mounted) {
                  await _removeStudent(context);
                }
              },
              child: const Text('Remove Student'),
            ),
          ],
        ),
      ),
    );
  }
}