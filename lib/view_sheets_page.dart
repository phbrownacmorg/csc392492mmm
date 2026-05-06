import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for future database integration
import 'music_sheet_widget.dart';

class ViewSheetsPage extends StatefulWidget {
  @override
  ViewSheetsPageState createState() => ViewSheetsPageState();
}

class ViewSheetsPageState extends State<ViewSheetsPage> {
  // Currently simulating a single blank sheet for the UI prototype.
  // FUTURE ARCHITECTURE: This list will eventually be populated dynamically 
  // by mapped data fetched straight from the Firestore database.
  List<MusicSheetWidget> sheets = [MusicSheetWidget()];

  // TODO: Integrate Firestore fetching once the "MusicSheets" saving logic is built by teammates.
  // This conceptual function demonstrates how the view page will pull the data:
  /*
  Future<void> _fetchSheetsFromDatabase() async {
    try {
      // 1. Query the 'MusicSheets' collection from Firebase Cloud Firestore
      final snapshot = await FirebaseFirestore.instance.collection('MusicSheets').get();
      
      // 2. Map through each document found in the database
      // List<MusicSheetWidget> fetchedSheets = snapshot.docs.map((doc) {
      //   final data = doc.data();
      //   // We would pass 'data' into a modified MusicSheetWidget to prepopulate the grid
      //   return MusicSheetWidget(databaseData: data); 
      // }).toList();
      
      // 3. Update the UI state with the real sheets from the database
      // setState(() {
      //   sheets = fetchedSheets;
      // });
    } catch (e) {
      print("Error fetching database sheets: $e");
    }
  }
  */

  void _addNewSheet() {
    setState(() {
      sheets.add(MusicSheetWidget());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Music Mastery Sheets')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            ...sheets, // List of MusicSheetWidgets
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addNewSheet,
              icon: Icon(Icons.library_add),
              label: Text('Add New Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
