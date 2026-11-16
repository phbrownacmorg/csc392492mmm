import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'login_page.dart';
//import 'register_page.dart';
import 'view_sheets_page.dart';
import 'view_database_page.dart';
import 'profile_page.dart';
import 'dart:typed_data';
import 'admin_page.dart';
import 'instructor_page.dart';
import 'package:music_app/services/auth_service.dart';
import 'package:music_app/logged_in_user.dart';

Future<void> main() async {

  //
  // Ensures Flutter bindings are initialized
  // BEFORE Firebase starts.
  //
  WidgetsFlutterBinding.ensureInitialized();

  //
  // Initialize Firebase.
  //
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //
  // Start app.
  //
  runApp(const MyApp());
}

//
// ===================== MAIN APP =====================
//

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(

      create: (context) => MyAppState(),

      child: MaterialApp(

        debugShowCheckedModeBanner: false,

        title: 'Music Sheet App',

        theme: ThemeData(

          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
          ),
        ),

        //
        // AuthGate decides:
        // - Login page
        // - Student page
        // - Admin page
        //
        home: const AuthGate(),
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

    //
    // Listens for Firebase login/logout changes.
    //
    return StreamBuilder<User?>(

      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        //
        // Show loading while Firebase checks auth state.
        //
        if (snapshot.connectionState == ConnectionState.waiting) {

          return const Scaffold(

            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        //
        // If NOT logged in:
        // go to login page.
        //
        if (!snapshot.hasData) {
          return LoginPage();
        }

        //
        // User IS logged in.
        // Now check Firestore role.
        //
        return const RoleRedirect();
      },
    );
  }
}

//
// ===================== ROLE REDIRECT =====================
//

class RoleRedirect extends StatelessWidget {
  const RoleRedirect({super.key});

  @override
  Widget build(BuildContext context) {

    //
    // Current Firebase authenticated user.
    //
    final user = FirebaseAuth.instance.currentUser;

    //
    // Safety check.
    //
    if (user == null) {
      return LoginPage();
    }

    //
    // Load Firestore user document.
    //
    return FutureBuilder<DocumentSnapshot>(

      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),

      builder: (context, snapshot) {

        //
        // While Firestore loads.
        //
        if (snapshot.connectionState == ConnectionState.waiting) {

          return const Scaffold(

            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        //
        // Firestore document missing.
        //
        if (!snapshot.hasData || !snapshot.data!.exists) {

          return const Scaffold(

            body: Center(
              child: Text('User data not found'),
            ),
          );
        }

        //
        // Convert Firestore document into map.
        //
        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        //
        // Read role from Firestore.
        //
        final role = data['role']?.toString().toLowerCase();

        //
        // Redirect based on role.
        //
        if (role == 'student') {

          return MyHomePage();

        } else if (role == 'admin') {

          return AdminPage();

        } else if (role == 'instructor') {

          return const InstructorPage();

        } else {

          //
          // Unknown role.
          //
          return const Scaffold(

            body: Center(
              child: Text('Invalid user role'),
            ),
          );
        }
      },
    );
  }
}

//
// ===================== APP STATE =====================
//

class MyAppState extends ChangeNotifier {

  //
  // Random word pair from english_words package.
  //
  var current = WordPair.random();

  //
  // Stores selected student name.
  //
  String? studentName;

  //
  // Stores selected problem.
  //
  Problem? selectedProblem;

  //
  // Update student name.
  //
  void updateStudentName(String name) {

    studentName = name;

    notifyListeners();
  }

  //
  // Update selected problem.
  //
  void updateSelectedProblem(Problem? problem) {

    selectedProblem = problem;

    notifyListeners();
  }
}

//
// ===================== PROBLEM MODEL =====================
//

class Problem {

  final int id;

  final String name;

  Problem(this.id, this.name);
}

//
// ===================== HOME PAGE =====================
//

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: FutureBuilder<Map<String, dynamic>?>(
          future: AuthService().getUserData(),
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Music Sheet App',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const LoggedInUser(),
              ],
            );
          },
        ),
        toolbarHeight: 85,

        centerTitle: true,

        actions: [

          //
          // Logout button.
          //
          Padding(

            padding: const EdgeInsets.only(right: 10),

            child: TextButton(

              onPressed: () async {

                //
                // Firebase logout.
                //
                await FirebaseAuth.instance.signOut();
              },

              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
              ),

              child: const Text(

                'Logout',

                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(

        child: Column(

          children: [

            const SizedBox(height: 100),

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,

              children: [
                _buildButton('Profile', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                }),
                _buildButton('View Sheets', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewSheetsPage(studentView: true),
                    ),
                  );
                }),
                _buildButton('Database Debug', context, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewDatabaseSheetPage()),
                  );
                }),
              ],
            ),

            const SizedBox(height: 30),

            //
            // Bottom banner placeholder.
            //
            Container(

              color: Colors.grey[300],

              padding: const EdgeInsets.all(16),

              width: double.infinity,

              child: const Center(
                child: Text('Bottom Banner'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
  // Reusable home page button.
  //
  Widget _buildButton(

    String text,

    BuildContext context,

    VoidCallback onPressed,

  ) {

    return Expanded(

      child: Padding(

        padding:
            const EdgeInsets.symmetric(horizontal: 5),

        child: SizedBox(

          height: 100,

          child: ElevatedButton(

            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.black,

              shape: const RoundedRectangleBorder(

                borderRadius: BorderRadius.zero,
              ),
            ),

            onPressed: onPressed,

            child: Text(

              text,

              style: const TextStyle(

                fontSize: 18,

                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PracticeRowData {
  TextEditingController pieceController = TextEditingController();
  TextEditingController tempoController = TextEditingController();
  TextEditingController passageController = TextEditingController();

  TextEditingController monController = TextEditingController();
  TextEditingController tueController = TextEditingController();
  TextEditingController wedController = TextEditingController();
  TextEditingController thuController = TextEditingController();
  TextEditingController friController = TextEditingController();
  TextEditingController satController = TextEditingController();
  TextEditingController sunController = TextEditingController();

  String? selectedStrategy;
  String mastery = 'Not Mastered';

  List<Problem> selectedProblems = [];

  Stream<Uint8List>? videoByteStream;
  String? videoName;
}

//
// ===================== STUDENT FORM =====================
//

class StudentForm extends StatefulWidget {
  const StudentForm({super.key});

  @override
  State<StudentForm> createState() =>
      _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {

  final TextEditingController _nameController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Problem? _selectedProblem;

  final TextEditingController _studentNameController =
      TextEditingController();

  final TextEditingController _sheetNameController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  List<Problem> _problems = [];

  List<PracticeRowData> _rows = [];

  @override
  void initState() {

    super.initState();

    _rows.add(PracticeRowData());


    //
    // Load Firestore problems.
    //
    _fetchProblemsFromFirestore();

    final currentUser = FirebaseAuth.instance.currentUser;

    _sheetNameController.text =
        'Music Sheet - ${DateTime.now().toString()} - ${currentUser?.email ?? "Unknown"}';
  }

  //
  // Load problems from Firestore.
  //
  Future<void> _fetchProblemsFromFirestore() async {

    try {

      final querySnapshot = await FirebaseFirestore
          .instance
          .collection('Problems')
          .get();

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load problems'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _sheetNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.grey[100],

        border: Border.all(
          color: Colors.grey[300]!,
        ),

        borderRadius: BorderRadius.circular(8),
      ),

      width: double.infinity,

      child: Form(

        key: _formKey,

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            TextFormField(
              controller: _sheetNameController,
              decoration: const InputDecoration(
                labelText: 'Sheet Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            //
            // Student name field.
            //
            TextFormField(
              controller: _studentNameController,
              decoration: const InputDecoration(
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

            const SizedBox(height: 20),

            const Text(

              'Please select the problem you are having',

              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 10),

            //
            // Problem dropdown.
            //
            DropdownButtonFormField<Problem>(

              decoration: const InputDecoration(

                border: OutlineInputBorder(),

                contentPadding:
                    EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),

              hint: const Text('Select a problem'),

              initialValue: _selectedProblem,

              validator: (value) {

                if (value == null) {
                  return 'Please select a problem';
                }

                return null;
              },

              items: _problems.map((problem) {

                return DropdownMenuItem<Problem>(

                  value: problem,

                  child: Text(
                    '${problem.id}. ${problem.name}',
                  ),
                );

              }).toList(),

              onChanged: (Problem? newValue) {

                setState(() {
                  _selectedProblem = newValue;
                });

                Provider.of<MyAppState>(
                  context,
                  listen: false,
                ).updateSelectedProblem(newValue);
              },
            ),

            const SizedBox(height: 30),

            Center(

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.deepOrange,

                  padding:
                      const EdgeInsets.symmetric(

                    horizontal: 40,

                    vertical: 15,
                  ),
                ),

                onPressed: () {

                  if (_formKey.currentState!
                      .validate()) {

                    //
                    // Save student name.
                    //
                    Provider.of<MyAppState>(
                      context,
                      listen: false,
                    ).updateStudentName(
                      _nameController.text,
                    );

                    //
                    // Success snackbar.
                    //
                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(
                        content: Text(
                          'Form submitted successfully',
                        ),
                      ),
                    );

                    //
                    // Return to previous page.
                    //
                    Navigator.pop(context);
                  }
                },

                child: const Text(

                  'Submit',

                  style: TextStyle(

                    fontSize: 18,

                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
