import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'main.dart';

//TODO implement while reusing as much code as posible from the existing music sheet widigit system

/*
Let user select a peice->
Let user select measures from that peice->
for the future{
 generate a list of problems to select for each set of mesures by quering the database for known problems.
 query the database for common problems for the selected peice and mesure set, factoring in the students skill level
 sort the problem set by how common the problems are.
 add a "custom problem" option that pops up a widigt to enter a custom problem.
 allow the user to select/add as many problems as needed.
 saving the peice, mesure set, skill level, and selected problem(s) to the database to allow us to get statistics of common problems to improve recomendataion.
}
for now
{
  generate a list of problems to select for each set of mesures by quering the database for known problems.
  allow the user to select as many problems as needed.
}->
for each set of problems selected{
  query the database for known solutions to all selected problems.
  generate a list that dynamicaly resorts itself with each solution selected using a sorting order that{
    keeps the selected solutions at the top in the order that they were selected
    and sorts the rest of the list by order of how many problems the unselected solutions solve, that the allreaddy selected solutions dont solve.
  }
  allow the user to select solution(s) from the generated list.
  for the future{
    save the peice, mesure set, skill level, problem set, and selected solution(s) to the database to allow us to get statistics of common solutions choices for the problems to improve recomendataion.
    query and use saved (problem set-solution set) statistics to improve recomendations of solutions.
  }
}->
allow the user to imput the measure set's tempo, practice time goals, etc->
allow user to enter aditional peices(repeat steps above for each peice)->
allow user to save the sheet to the database under their account/push the sheet to their students.
*/








































//TODO old code
class StudentForm extends StatefulWidget {
  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pieceController = TextEditingController();
  final TextEditingController _measuresController = TextEditingController();
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
      final querySnapshot = await FirebaseFirestore.instance.collection('Problems').get();
      final problems = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Problem(
          data['problem_id'] as int,
          data['problem_name'] as String,
        );
      }).toList();

      problems.sort((a, b) => a.id.compareTo(b.id)); // Sort by ID
      
      setState(() {
        _problems = problems;
      });
    } catch (e) {
      print('Error fetching problems: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load problems')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pieceController.dispose();
    _measuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter student name';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _pieceController,
              decoration: InputDecoration(
                labelText: 'Piece Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a piece name';
                }
                return null;
              },
            ),

            SizedBox(height: 20),
            TextFormField(
              controller: _measuresController,
              decoration: InputDecoration(
                labelText: 'Measures',
                hintText: 'Example: 1-8',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the measure range';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            Text('Please select the problem you are having', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            DropdownButtonFormField<Problem>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text('Select a problem'),
              initialValue: _selectedProblem,
              validator: (value) {
                if (value == null) {
                  return 'Please select a problem';
                }
                return null;
              },
              items: _problems.map((Problem problem) {
                return DropdownMenuItem<Problem>(
                  value: problem,
                  child: Text('${problem.id}. ${problem.name}'),
                );
              }).toList(),
              onChanged: (Problem? newValue) {
                setState(() {
                  _selectedProblem = newValue;
                });
                Provider.of<MyAppState>(context, listen: false)
                    .updateSelectedProblem(newValue);
              },
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save the form data to app state
                    Provider.of<MyAppState>(context, listen: false)
                        .updateStudentName(_nameController.text);
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Form submitted successfully')),
                    );
                    
                    // Navigate back to home page after submission
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateMusicSheetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Music Sheet'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              StudentForm(),
              SizedBox(height: 20),
              Container(
                color: Colors.grey[300],
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: Center(child: Text('Bottom Banner')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}