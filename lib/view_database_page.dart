import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';// for database access
//class to hold the info for a database colection
class Colection{
  final String name;
  Colection(this.name);
}



//statefull widigit to hold the database entrees.
class DatabaseForm extends StatefulWidget{
  @override
  State<DatabaseForm> createState() => _CreateDatabaseFormFormState();
}
//copy from student form to get something up and running.
class _CreateDatabaseFormFormState extends State<DatabaseForm> {
  final TextEditingController _nameController = TextEditingController();
  Colection? _selectedColection;
  //final _formKey = GlobalKey<FormState>();

//temp use strings for database colections.
  List<Colection> _colections = [Colection('test')];

  @override
  void initState() {
    super.initState();
    //_fetchProblemsFromFirestore();
  }

  /*Future<void> _fetchProblemsFromFirestore() async {
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
  }*/

  @override
  void dispose() {
    _nameController.dispose();
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
      child: Column(
        children: [
          Row(
          children: [
            Text(
              'Colection:'
            ),
            DropdownButton<Colection>(
              value: _selectedColection,
              items: _colections.map((Colection collection) {
                return DropdownMenuItem<Colection>(
                    value: collection,
                    child: Text(collection.name),
                );
              }).toList(),
              onChanged: (Colection? newValue){
                setState(() {
                _selectedColection = newValue;
                });
              },
              hint: Text(
                'Please select a colection'
              ),
            ),
        ],
      )
      ],)
    );
  }
}

//copy code to get page working TEMP
class ViewDatabaseSheetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database View Page'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DatabaseForm(),
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