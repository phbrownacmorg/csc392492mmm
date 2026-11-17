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

  final firestore = FirebaseFirestore.instance;

  try {
    final assignedSheets = await firestore
        .collection('music_sheets')
        .where('userId', isEqualTo: studentId)
        .where('Assigned', isEqualTo: currentUser.uid)
        .get();

    final connections = await firestore
        .collection('Connections')
        .where('studentId', isEqualTo: studentId)
        .where('instructorId', isEqualTo: currentUser.uid)
        .get();

    final allConnections =
        await firestore.collection('Connections').get();

    final existingPeers = allConnections.docs.where((doc) {
      final data = doc.data();

      if (data['connectionType'] != 'peer') return false;

      return (data['requesterId'] == currentUser.uid &&
              data['receiverId'] == studentId) ||
          (data['requesterId'] == studentId &&
              data['receiverId'] == currentUser.uid);
    }).toList();

    final batch = firestore.batch();

    // Keep the sheets, but remove instructor restrictions.
    for (final sheet in assignedSheets.docs) {
      batch.update(sheet.reference, {
        'Assigned': null,
        'restrictWrite': null,
      });
    }

    // Ensure an accepted Peer Connection remains.
    if (existingPeers.isEmpty) {
      final peerRef = firestore.collection('Connections').doc();

      batch.set(peerRef, {
        'connectionType': 'peer',
        'requesterId': currentUser.uid,
        'receiverId': studentId,
        'accepted': FieldValue.serverTimestamp(),
      });
    } else {
      for (final peer in existingPeers) {
        if (peer.data()['accepted'] == null) {
          batch.update(peer.reference, {
            'accepted': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // Remove only the instructor-student relationship.
    for (final connection in connections.docs) {
      if (connection.data()['connectionType'] == 'instructor-student') {
        batch.delete(connection.reference);
      }
    }

    await batch.commit();

    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e) {
    debugPrint('Error dismissing student: $e');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not dismiss student. Please try again.'),
      ),
    );
  }
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
                      studentName: studentName,
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