import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'view_sheets_page.dart';
import 'music_sheet_page.dart';
import 'profile_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
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
        title: 'Music Sheet App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: AuthGate(), // ✅ CHANGED HERE (this enables login + roles)
      ),
    );
  }
}

//
// ===================== AUTH GATE =====================
//

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoginPage();
        }

        return RoleRedirect();
      },
    );
  }
}

//
// ===================== ROLE REDIRECT =====================
//

class RoleRedirect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'];

        if (role == 'student') {
          return MyHomePage();
        } else if (role == 'admin') {
          return MyHomePage(); // replace later with AdminPage
        } else {
          return LoginPage();
        }
      },
    );
  }
}


//APP STATE 


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


// HOME PAGE 


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
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('Profile', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
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
     