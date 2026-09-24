import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'instruct_student.dart';

class ViewStudentsPage extends StatefulWidget {
  const ViewStudentsPage({super.key});

  @override
  State<ViewStudentsPage> createState() => _ViewStudentsPageState();
}

class _ViewStudentsPageState extends State<ViewStudentsPage> {
  Future<List<Map<String, dynamic>>> _loadStudents() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return [];
    }

    final studentOfSnapshot = await FirebaseFirestore.instance
        .collection('StudentOf')
        .where('instructorId', isEqualTo: currentUser.uid)
        .get();

    final students = <Map<String, dynamic>>[];

    for (final relation in studentOfSnapshot.docs) {
      final studentId = relation.data()['studentId'];

      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        students.add({
          'uid': studentId,
          ...studentDoc.data()!,
        });
      }
    }

    return students;
  }
  Future<List<Map<String, dynamic>>> _loadAvailableStudents() async {
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .get();

    final studentOfSnapshot =
        await FirebaseFirestore.instance.collection('StudentOf').get();

    final studentsWithInstructor = studentOfSnapshot.docs
        .map((doc) => doc.data()['studentId']?.toString())
        .whereType<String>()
        .toSet();

    final availableStudents = <Map<String, dynamic>>[];

    for (final studentDoc in studentsSnapshot.docs) {
      final data = studentDoc.data();
      final studentId = data['uid']?.toString() ?? studentDoc.id;

      if (!studentsWithInstructor.contains(studentId)) {
        availableStudents.add({
          'uid': studentId,
          ...data,
        });
      }
    }

    return availableStudents;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Students'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final availableStudents = await _loadAvailableStudents();

              if (!context.mounted) return;

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Add Student'),
                    content: SizedBox(
                      width: 400,
                      child: availableStudents.isEmpty
                          ? const Text('No available students.')
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableStudents.length,
                              itemBuilder: (context, index) {
                                final student = availableStudents[index];

                                final firstName = student['firstName'] ?? '';
                                final lastName = student['lastName'] ?? '';
                                final email = student['email'] ?? '';

                                return ListTile(
                                  title: Text('$firstName $lastName'),
                                  subtitle: Text(email),
                                  onTap: () async {
                                    final currentUser = FirebaseAuth.instance.currentUser;

                                    if (currentUser == null) return;

                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Add Student'),
                                          content: Text(
                                            'Are you sure you want to add $firstName $lastName?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Add'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmed != true) return;

                                    await FirebaseFirestore.instance
                                        .collection('StudentOf')
                                        .add({
                                      'studentId': student['uid'],
                                      'instructorId': currentUser.uid,
                                    });

                                    if (!context.mounted) return;

                                    Navigator.pop(context);

                                    setState(() {});
                                  },
                                );
                              },
                            ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Student'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return const Center(
              child: Text('No students found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];

              final firstName = student['firstName'] ?? '';
              final lastName = student['lastName'] ?? '';
              final email = student['email'] ?? '';

              return Card(
                child: ListTile(
                  title: Text('$firstName $lastName'),
                  subtitle: Text(email),
                  trailing: TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InstructStudentPage(
                            studentId: student['uid'],
                            studentName: '$firstName $lastName',
                          ),
                        ),
                      );

                      setState(() {});
                    },
                    child: const Text('Manage'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}