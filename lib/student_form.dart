import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart'; // for MyAppState + Problem

class StudentForm extends StatefulWidget {
  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final TextEditingController _nameController = TextEditingController();
  Problem? _selectedProblem;
  final _formKey = GlobalKey<FormState>();

  List<Problem> _problems = [];

  @override
  void initState() {
    super.initState();
    _fetchProblemsFromFirestore();
  }

  Future<void> _fetchProblemsFromFirestore() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Problems').get();

      final problems = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Problem(
          data['problem_id'] as int,
          data['problem_name'] as String,
        );
      }).toList();

      problems.sort((a, b) => a.id.compareTo(b.id));

      setState(() {
        _problems = problems;
      });
    } catch (e) {
      print('Error fetching problems: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter name' : null,
            ),

            SizedBox(height: 20),

            DropdownButtonFormField<Problem>(
              hint: Text('Select a problem'),
              initialValue: _selectedProblem,
              items: _problems.map((problem) {
                return DropdownMenuItem(
                  value: problem,
                  child: Text('${problem.id}. ${problem.name}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProblem = value;
                });

                Provider.of<MyAppState>(context, listen: false)
                    .updateSelectedProblem(value);
              },
              validator: (value) =>
                  value == null ? 'Select a problem' : null,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Provider.of<MyAppState>(context, listen: false)
                      .updateStudentName(_nameController.text);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Form submitted')),
                  );

                  Navigator.pop(context);
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}