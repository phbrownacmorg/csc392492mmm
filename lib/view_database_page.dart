import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';// for database access

//class to hold info for a database item
class Document{
  final String name;
  final Map<String, dynamic> data;
  Document(this.name, this.data);
}
//class to hold the info for a database collection
class Collection{
  final String collectionPath;
  Collection(this.collectionPath, this._documents);
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
  Collection? _selectedCollection;
  Document? _selectedDocument;
  String _documentJson = '';
  //final _formKey = GlobalKey<FormState>();

//temp use strings for database collections untill database collection loading logic is possible.
  List<Collection> _collections = [Collection('Problems', null),Collection('Solutions', null),Collection('Strategies', null),Collection('users',null),Collection('music_sheets',null)];
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
    for (var index = 0; index < _collections.length; index += 1){
      final querySnapshot = await FirebaseFirestore.instance.collection(_collections[index].collectionPath).get();
      _collections[index]._documents = querySnapshot.docs.map<Document>((element){
        final data = element.data();
        String documentName = '';
        //use hash of document as fallback
        if(_documentIdTable[_collections[index].collectionPath] != null){
          documentName = data[_documentIdTable[_collections[index].collectionPath]].toString();
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
               'Collection:'
              ),
              DropdownButton<Collection>(
                value: _selectedCollection,
                items: _collections.map((Collection collection) {
                  return DropdownMenuItem<Collection>(
                    value: collection,
                    child: Text(collection.collectionPath),
                  );
                }).toList(),
                onChanged: (Collection? newValue){
                  setState(() {
                    _selectedCollection = newValue;
                    _selectedDocument = null;
                    _documentJson = '';
                  });
                },
                hint: Text(
                  'Please select a collection'
                ),
              ),
              SizedBox(width: 20),
              Text(
               'Document:'
              ),
              DropdownButton<Document>(
                value: _selectedDocument,
                items: _selectedCollection?._documents?.map((Document document) {
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