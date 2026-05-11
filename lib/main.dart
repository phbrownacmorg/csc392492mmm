import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'view_sheets_page.dart';
import 'create_music_sheet_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'view_database_page.dart';



void main() async{
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  String? studentName;
  Problem? selectedProblem;

  void updateStudentName(String name) {
    studentName = name;
    notifyListeners();
  }

  void updateSelectedProblem(Problem? problem) {
    selectedProblem = problem;
    notifyListeners();
  }
}

class Problem {
  final int id;
  final String name;

  Problem(this.id, this.name);
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Music Sheet App'),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                'Login',
                style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('Profile', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                }),
                _buildButton('Create Music Sheet', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateMusicSheetPage()),
                  );
                }),
                _buildButton('View Sheets', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewSheetsPage()),
                  );
                }),
                _buildButton('Debug_Database_Viewer', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewDatabaseSheetPage()),
                  );
                }),
              ],
            ),
            SizedBox(height: 30),
            Container(
              color: Colors.grey[300],
              padding: EdgeInsets.all(16),
              width: double.infinity,
              child: Center(child: Text('Bottom Banner')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, BuildContext context, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(
          height: 100,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}



     