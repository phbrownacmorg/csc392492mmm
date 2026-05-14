import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'view_sheets_page.dart';
import 'music_sheet_page.dart';
import 'view_database_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        home: AuthGate(), // Redirects back to MyHomePage()
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
          ),
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
                _buildButton('Database Debug', context, () {
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

  Uint8List? videoBytes;
  String? videoName;
}

class AuthGate extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MyHomePage();
      },
    );
  }
}

class StudentForm extends StatefulWidget {
  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _studentNameController =
      TextEditingController();

  final TextEditingController _sheetNameController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  List<Problem> _problems = [];
  List<String> _strategies = [];
  List<String> _pieces = [];

  List<PracticeRowData> _rows = [];

  @override
  void initState() {
    super.initState();

    _rows.add(PracticeRowData());

    _fetchProblemsFromFirestore();
    _fetchStrategiesFromFirestore();
    _fetchPiecesFromFirestore();

    final currentUser = FirebaseAuth.instance.currentUser;

    _sheetNameController.text =
        'Music Sheet - ${DateTime.now().toString()} - ${currentUser?.email ?? "Unknown"}';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load problems'),
        ),
      );
    }
  }

  Future<void> _fetchStrategiesFromFirestore() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Strategies').get();

      final strategies = querySnapshot.docs
          .map((doc) => doc['strategy_name'].toString())
          .toList();

      setState(() {
        _strategies = strategies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load strategies.'),
        ),
      );
    }
  }

  Future<void> _fetchPiecesFromFirestore() async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('pieces').get();

    final pieces = querySnapshot.docs
        .map((doc) => doc['name'].toString())
        .toList();

    setState(() {
      _pieces = pieces;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not load pieces.'),
      ),
    );
  }
}

  Future<void> _pickVideo(PracticeRowData row) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
      withData: true,
    );

    if (result != null) {
      setState(() {
        row.videoBytes = result.files.single.bytes;
        row.videoName = result.files.single.name;
      });
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(PracticeRowData());
    });
  }

  Widget _buildDayField(
    String label,
    TextEditingController controller,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSheet() async {
    try {
      List<Map<String, dynamic>> rowData = [];

      for (var row in _rows) {
        String? videoUrl;

        if (row.videoBytes != null && row.videoName != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('music_sheet_videos/${row.videoName}');

          await storageRef.putData(row.videoBytes!);

          videoUrl = await storageRef.getDownloadURL();
        }

        rowData.add({
          'piece': row.pieceController.text.trim(),
          'tempo':
              int.tryParse(row.tempoController.text.trim()) ?? 0,
          'passage': row.passageController.text.trim(),
          'strategy': row.selectedStrategy,
          'mastery': row.mastery,
          'problems':
              row.selectedProblems.map((p) => p.name).toList(),
          'videoName': row.videoName,
          'videoUrl': videoUrl,
          'mon':
              int.tryParse(row.monController.text.trim()) ?? 0,
          'tue':
              int.tryParse(row.tueController.text.trim()) ?? 0,
          'wed':
              int.tryParse(row.wedController.text.trim()) ?? 0,
          'thu':
              int.tryParse(row.thuController.text.trim()) ?? 0,
          'fri':
              int.tryParse(row.friController.text.trim()) ?? 0,
          'sat':
              int.tryParse(row.satController.text.trim()) ?? 0,
          'sun':
              int.tryParse(row.sunController.text.trim()) ?? 0,
        });
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('music_sheets')
          .add({
        'sheetName': _sheetNameController.text.trim(),
        'studentName': _studentNameController.text.trim(),
        'notes': _notesController.text.trim(),
        'rows': rowData,
        'creatorEmail': currentUser?.email,
        'userId': currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sheet saved successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sheet failed to save'),
        ),
      );
    }
  }

  Widget _buildPracticeRow(
    PracticeRowData row,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Passage ${index + 1}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Piece',
                border: OutlineInputBorder(),
              ),
              value: row.pieceController.text.isEmpty
                  ? null
                  : row.pieceController.text,
              items: _pieces.map((piece) {
                return DropdownMenuItem<String>(
                value: piece,
                child: Text(piece),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                row.pieceController.text = value ?? '';
              });
            },
          ),

            const SizedBox(height: 20),

            TextFormField(
              controller: row.tempoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: row.passageController,
              decoration: const InputDecoration(
                labelText: 'Passage',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Problems',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Column(
              children: _problems.map((problem) {
                bool isSelected =
                    row.selectedProblems.contains(problem);

                return CheckboxListTile(
                  title: Text(problem.name),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        row.selectedProblems.add(problem);
                      } else {
                        row.selectedProblems.remove(problem);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Practice Strategy',
                border: OutlineInputBorder(),
              ),
              value: row.selectedStrategy,
              items: _strategies.map((strategy) {
                return DropdownMenuItem<String>(
                  value: strategy,
                  child: Text(strategy),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  row.selectedStrategy = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _buildDayField('M', row.monController),
                _buildDayField('T', row.tueController),
                _buildDayField('W', row.wedController),
                _buildDayField('H', row.thuController),
                _buildDayField('F', row.friController),
                _buildDayField('Sat', row.satController),
                _buildDayField('Sun', row.sunController),
              ],
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Mastery',
                border: OutlineInputBorder(),
              ),
              value: row.mastery,
              items: const [
                DropdownMenuItem(
                  value: 'Mastered',
                  child: Text('Mastered'),
                ),
                DropdownMenuItem(
                  value: 'Not Mastered',
                  child: Text('Not Mastered'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  row.mastery = value ?? 'Not Mastered';
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _pickVideo(row),
              icon: const Icon(Icons.video_library),
              label: const Text('Upload Video'),
            ),

            if (row.videoName != null)
  Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            row.videoName!,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          tooltip: 'Remove Video',
          onPressed: () {
            setState(() {
              row.videoBytes = null;
              row.videoName = null;
            });
          },
        ),
      ],
    ),
  ),
          ],
        ),
      ),
    );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _sheetNameController,
              decoration: const InputDecoration(
                labelText: 'Sheet Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _studentNameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ..._rows.asMap().entries.map(
                  (entry) => _buildPracticeRow(
                    entry.value,
                    entry.key,
                  ),
                ),

            ElevatedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Add Passage Row'),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Sheet Notes',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _saveSheet,
              icon: const Icon(Icons.save),
              label: const Text('Save Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}