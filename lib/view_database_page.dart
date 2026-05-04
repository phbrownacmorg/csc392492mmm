import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';// for database access

//class to hold info for a database item
class Document{
  final String name;
  final Map<String, dynamic> data;
  Document(this.name, this.data);
}
//class to hold the info for a database colection
class Colection{
  final String colectionPath;
  Colection(this.colectionPath, this._documents);
  List<Document>? _documents;
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
  Document? _selectedDocument;
  String _documentJson = '';
  //final _formKey = GlobalKey<FormState>();

//temp use strings for database colections untill database collection loading logic is possible.
  List<Colection> _colections = [Colection('Problems', null),Colection('Solutions', null),Colection('Strategies', null),Colection('users',null),Colection('music_sheets',null)];
//Update when doocument format changes
  Map<String,String> _documentIdTable = {'Problems':'problem_name','Solutions':'strategy_name','Strategies':'strategy_name'};

  @override
  void initState() {
    super.initState();
    //_fetchCollectionsFromFirestore();
    _fetchDocumentsFromFirestore();
  }
  //need to get a database that allowes accessing a list of collections for this to be implemented
  /*Future<void> _fetchCollectionsFromFirestore() async {
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
  
  Future<void> _fetchDocumentsFromFirestore() async {
    for (var index = 0; index < _colections.length; index += 1){
      final querySnapshot = await FirebaseFirestore.instance.collection(_colections[index].colectionPath).get();
      _colections[index]._documents = querySnapshot.docs.map<Document>((element){
        final data = element.data();
        String documentName = '';
        //use hash of document as fallback
        if(_documentIdTable[_colections[index].colectionPath] != null){
          documentName = data[_documentIdTable[_colections[index].colectionPath]].toString();
        }
        else{
          documentName = data.hashCode.toString();
        }
        return Document(documentName, data);
      }).toList();
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
              SizedBox(width: 20),
              Text(
               'Colection:'
              ),
              DropdownButton<Colection>(
                value: _selectedColection,
                items: _colections.map((Colection collection) {
                  return DropdownMenuItem<Colection>(
                    value: collection,
                    child: Text(collection.colectionPath),
                  );
                }).toList(),
                onChanged: (Colection? newValue){
                  setState(() {
                    _selectedColection = newValue;
                    _selectedDocument = null;
                    _documentJson = '';
                  });
                },
                hint: Text(
                  'Please select a colection'
                ),
              ),
              SizedBox(width: 20),
              Text(
               'Document:'
              ),
              DropdownButton<Document>(
                value: _selectedDocument,
                items: _selectedColection?._documents?.map((Document document) {
                  return DropdownMenuItem<Document>(
                    value: document,
                    child: Text(document.name),
                  );
                }).toList(),
                onChanged: (Document? newValue){
                  setState(() {
                    _selectedDocument = newValue;
                    if(newValue != null){
                      _documentJson = newValue.data.toString();
                    }
                    else{
                      _documentJson = '';
                    }
                  });
                },
                hint: Text(
                  'Please select a document'
                ),
              ),
            ],
          ),
          Text(
            _documentJson
          )
        ],
      )
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