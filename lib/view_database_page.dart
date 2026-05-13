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
  final List<String> displayFields; // Defined fields to prevent overflow
  List<Document>? _documents;

  Collection(this.collectionPath, this.displayFields, this._documents);
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

//temp use strings for database collections untill database collection loading logic is possible.
final List<Collection> _collections = [
    Collection('Problems', ['problem_name', 'problem_id'], null),
    Collection('Solutions', ['strategy_name', 'solution_id'], null),
    Collection('Strategies', ['strategy_name'], null),
    Collection('users', ['username', 'email'], null),
    Collection('music_sheets', ['title', 'sheet_id'], null)
  ];

  @override
  void initState() {
    super.initState();
    //_fetchCollectionsFromFirestore();
    _fetchDocumentsFromFirestore();
  }
  
  Future<void> _fetchDocumentsFromFirestore() async {
    for (var index = 0; index < _collections.length; index += 1){
      final collection = _collections[index];
      final querySnapshot = await FirebaseFirestore.instance.collection(collection.collectionPath).get();

      collection._documents = querySnapshot.docs.map<Document>((element){
        final data = element.data();
        List<String> displayValues = [];

        // Build the dropdown name using only specified fields
        for (String field in collection.displayFields) {
          if (data.containsKey(field) && data[field] != null && data[field].toString().isNotEmpty) {
            displayValues.add(data[field].toString());
          }
        }

        String documentName;
        if (displayValues.isNotEmpty) {
          // Joins multiple found fields (e.g. "Math Problem - 123")
          documentName = displayValues.join(' - ');
        } else {
          // Use the actual Firestore document ID as a clean fallback instead of hashCode
          documentName = 'ID: ${element.id}'; 
        }

        return Document(documentName, data);
      }).toList();
    }
    // Trigger a rebuild once documents are loaded so dropdowns populate
    if (mounted) setState(() {});
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Collection:'),
              SizedBox(width: 8),
              // Wrapped in Expanded to prevent layout overflow
              Expanded(
                child: DropdownButton<Collection>(
                  isExpanded: true, // Crucial for preventing text overflow
                  value: _selectedCollection,
                  items: _collections.map((Collection collection) {
                    return DropdownMenuItem<Collection>(
                      value: collection,
                      child: Text(
                        collection.collectionPath,
                        overflow: TextOverflow.ellipsis, // Truncates text instead of breaking UI
                      ),
                    );
                  }).toList(),
                  onChanged: (Collection? newValue) {
                    setState(() {
                      _selectedCollection = newValue;
                      _selectedDocument = null;
                      _documentJson = '';
                    });
                  },
                  hint: Text('Select a collection'),
                ),
              ),
              SizedBox(width: 20),
              Text('Document:'),
              SizedBox(width: 8),
              // Wrapped in Expanded to prevent layout overflow
              Expanded(
                child: DropdownButton<Document>(
                  isExpanded: true, // Crucial for preventing text overflow
                  value: _selectedDocument,
                  items: _selectedCollection?._documents?.map((Document document) {
                    return DropdownMenuItem<Document>(
                      value: document,
                      child: Text(
                        document.name,
                        overflow: TextOverflow.ellipsis, // Truncates text instead of breaking UI
                      ),
                    );
                  }).toList(),
                  onChanged: (Document? newValue) {
                    setState(() {
                      _selectedDocument = newValue;
                      if (newValue != null) {
                        _documentJson = newValue.data.toString();
                      } else {
                        _documentJson = '';
                      }
                    });
                  },
                  hint: Text('Select a document'),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            _documentJson,
            style: TextStyle(fontFamily: 'monospace'), // Makes JSON data slightly easier to read
          )
        ],
      ),
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