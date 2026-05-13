import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'music_sheet_widget.dart';

class ViewSheetsPage extends StatefulWidget {
  const ViewSheetsPage({super.key});

  @override
  State<ViewSheetsPage> createState() => _ViewSheetsPageState();
}

class _ViewSheetsPageState extends State<ViewSheetsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  bool _showAllSheets = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getSheetsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('music_sheets');

    if (currentUser != null && !_showAllSheets) {
      query = query.where('userId', isEqualTo: currentUser.uid);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  bool _sheetMatchesSearch(Map<String, dynamic> data) {
    if (_searchText.trim().isEmpty) {
      return true;
    }

    final search = _searchText.toLowerCase();

    final sheetName = data['sheetName']?.toString().toLowerCase() ?? '';
    final studentName = data['studentName']?.toString().toLowerCase() ?? '';
    final creatorEmail = data['creatorEmail']?.toString().toLowerCase() ?? '';
    final notes = data['notes']?.toString().toLowerCase() ?? '';

    if (sheetName.contains(search) ||
        studentName.contains(search) ||
        creatorEmail.contains(search) ||
        notes.contains(search)) {
      return true;
    }

    final rows = data['rows'];

    if (rows is List) {
      for (final row in rows) {
        if (row is Map) {
          final piece = row['piece']?.toString().toLowerCase() ?? '';
          final passage = row['passage']?.toString().toLowerCase() ?? '';
          final strategy = row['strategy']?.toString().toLowerCase() ?? '';
          final mastery = row['mastery']?.toString().toLowerCase() ?? '';

          if (piece.contains(search) ||
              passage.contains(search) ||
              strategy.contains(search) ||
              mastery.contains(search)) {
            return true;
          }

          final problems = row['problems'];

          if (problems is List) {
            for (final problem in problems) {
              if (problem.toString().toLowerCase().contains(search)) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }

  Future<void> _deleteSheet(String documentId) async {
    await FirebaseFirestore.instance
        .collection('music_sheets')
        .doc(documentId)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sheet deleted')),
    );
  }

  Future<void> _confirmDelete(String documentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Sheet'),
          content: const Text('Are you sure you want to delete this sheet?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteSheet(documentId);
    }
  }

  Future<void> _renameSheet(
    String documentId,
    String currentSheetName,
  ) async {
    final controller = TextEditingController(text: currentSheetName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Sheet'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Sheet Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('music_sheets')
          .doc(documentId)
          .update({
        'sheetName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet updated')),
      );
    }
  }

  Widget _buildRowsPreview(List<dynamic> rows) {
    if (rows.isEmpty) {
      return const Text('No passage rows found.');
    }

    return Column(
      children: rows.map((row) {
        if (row is! Map) {
          return const SizedBox.shrink();
        }

        final problems = row['problems'];

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Piece: ${row['piece'] ?? ''}'),
              Text('Passage: ${row['passage'] ?? ''}'),
              Text('Tempo: ${row['tempo'] ?? ''}'),
              Text('Strategy: ${row['strategy'] ?? ''}'),
              Text('Mastery: ${row['mastery'] ?? ''}'),
              Text(
                'Problems: ${problems is List ? problems.join(', ') : ''}',
              ),
              Text(
                'Days: M ${row['mon'] ?? 0}, T ${row['tue'] ?? 0}, W ${row['wed'] ?? 0}, H ${row['thu'] ?? 0}, F ${row['fri'] ?? 0}, Sat ${row['sat'] ?? 0}, Sun ${row['sun'] ?? 0}',
              ),
              if (row['videoUrl'] != null)
                const Text(
                  'Video attached',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSheetCard(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final rows = data['rows'];
    final createdAt = data['createdAt'];

    String createdDateText = '';

    if (createdAt is Timestamp) {
      createdDateText = createdAt.toDate().toString();
    }

    final sheetName = data['sheetName']?.toString() ?? 'Untitled Sheet';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(sheetName),
        subtitle: Text(
          'Student: ${data['studentName'] ?? ''}\nCreated: $createdDateText',
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Creator: ${data['creatorEmail'] ?? ''}'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Notes: ${data['notes'] ?? ''}'),
          ),
          const SizedBox(height: 12),
          _buildRowsPreview(rows is List ? rows : []),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSheetPage(
                        documentId: documentId,
                        sheetData: data,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _renameSheet(documentId, sheetName),
                icon: const Icon(Icons.drive_file_rename_outline),
                label: const Text('Rename'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(documentId),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Sheets'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (currentUser != null)
              SwitchListTile(
                title: const Text('Show all sheets'),
                subtitle: const Text(
                  'Off = only sheets saved by the current user',
                ),
                value: _showAllSheets,
                onChanged: (value) {
                  setState(() {
                    _showAllSheets = value;
                  });
                },
              )
            else
              const Text(
                'No user is logged in, so all sheets are shown.',
              ),

            const SizedBox(height: 10),

            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by student, sheet, piece, problem, or strategy',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getSheetsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error loading sheets: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final filteredDocs = docs.where((doc) {
                    return _sheetMatchesSearch(doc.data());
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text('No sheets found.'),
                    );
                  }

                  return ListView(
                    children: filteredDocs.map((doc) {
                      return _buildSheetCard(
                        doc.id,
                        doc.data(),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditRowData {
  TextEditingController pieceController = TextEditingController();
  TextEditingController tempoController = TextEditingController();
  TextEditingController passageController = TextEditingController();
  TextEditingController strategyController = TextEditingController();
  TextEditingController masteryController = TextEditingController();

  TextEditingController monController = TextEditingController();
  TextEditingController tueController = TextEditingController();
  TextEditingController wedController = TextEditingController();
  TextEditingController thuController = TextEditingController();
  TextEditingController friController = TextEditingController();
  TextEditingController satController = TextEditingController();
  TextEditingController sunController = TextEditingController();

  List<dynamic> problems = [];
  String? videoName;
  String? videoUrl;
}

class EditSheetPage extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> sheetData;

  const EditSheetPage({
    super.key,
    required this.documentId,
    required this.sheetData,
  });

  @override
  State<EditSheetPage> createState() => _EditSheetPageState();
}

class _EditSheetPageState extends State<EditSheetPage> {
  late TextEditingController sheetNameController;
  late TextEditingController studentNameController;
  late TextEditingController notesController;

  List<EditRowData> editableRows = [];
  List<String> availableProblems = [];
  List<String> availableStrategies = [];

  @override
  void initState() {
    super.initState();

    sheetNameController = TextEditingController(
      text: widget.sheetData['sheetName']?.toString() ?? '',
    );

    studentNameController = TextEditingController(
      text: widget.sheetData['studentName']?.toString() ?? '',
    );

    notesController = TextEditingController(
      text: widget.sheetData['notes']?.toString() ?? '',
    );

    _fetchProblemsFromFirestore();
    _fetchStrategiesFromFirestore();
  

    final rows = widget.sheetData['rows'];

    if (rows is List) {
      for (final row in rows) {
        if (row is Map) {
          final editRow = EditRowData();

          editRow.pieceController.text = row['piece']?.toString() ?? '';
          editRow.tempoController.text = row['tempo']?.toString() ?? '';
          editRow.passageController.text = row['passage']?.toString() ?? '';
          editRow.strategyController.text = row['strategy']?.toString() ?? '';
          editRow.masteryController.text = row['mastery']?.toString() ?? '';

          editRow.monController.text = row['mon']?.toString() ?? '0';
          editRow.tueController.text = row['tue']?.toString() ?? '0';
          editRow.wedController.text = row['wed']?.toString() ?? '0';
          editRow.thuController.text = row['thu']?.toString() ?? '0';
          editRow.friController.text = row['fri']?.toString() ?? '0';
          editRow.satController.text = row['sat']?.toString() ?? '0';
          editRow.sunController.text = row['sun']?.toString() ?? '0';

          editRow.problems = row['problems'] is List ? row['problems'] : [];
          editRow.videoName = row['videoName']?.toString();
          editRow.videoUrl = row['videoUrl']?.toString();

          editableRows.add(editRow);
        }
      }
    }
  }

Future<void> _fetchProblemsFromFirestore() async {
  final querySnapshot =
      await FirebaseFirestore.instance.collection('Problems').get();

  final problems = querySnapshot.docs
      .map((doc) => doc['problem_name'].toString())
      .toList();

  setState(() {
    availableProblems = problems;
  });
}

Future<void> _fetchStrategiesFromFirestore() async {
  final querySnapshot =
      await FirebaseFirestore.instance.collection('Strategies').get();

  final strategies = querySnapshot.docs
      .map((doc) => doc['strategy_name'].toString())
      .toList();

  setState(() {
    availableStrategies = strategies;
  });
}

  Future<void> _saveChanges() async {
    final updatedRows = editableRows.map((row) {
      return {
        'piece': row.pieceController.text.trim(),
        'tempo': int.tryParse(row.tempoController.text.trim()) ?? 0,
        'passage': row.passageController.text.trim(),
        'strategy': row.strategyController.text.trim(),
        'mastery': row.masteryController.text.trim(),
        'problems': row.problems,
        'videoName': row.videoName,
        'videoUrl': row.videoUrl,
        'mon': int.tryParse(row.monController.text.trim()) ?? 0,
        'tue': int.tryParse(row.tueController.text.trim()) ?? 0,
        'wed': int.tryParse(row.wedController.text.trim()) ?? 0,
        'thu': int.tryParse(row.thuController.text.trim()) ?? 0,
        'fri': int.tryParse(row.friController.text.trim()) ?? 0,
        'sat': int.tryParse(row.satController.text.trim()) ?? 0,
        'sun': int.tryParse(row.sunController.text.trim()) ?? 0,
      };
    }).toList();

    await FirebaseFirestore.instance
        .collection('music_sheets')
        .doc(widget.documentId)
        .update({
      'sheetName': sheetNameController.text.trim(),
      'studentName': studentNameController.text.trim(),
      'notes': notesController.text.trim(),
      'rows': updatedRows,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sheet updated')),
    );

    Navigator.pop(context);
  }

  Widget _buildDayField(String label, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextField(
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

  Widget _buildEditableRow(EditRowData row, int index) {
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
            TextField(
              controller: row.pieceController,
              decoration: const InputDecoration(
                labelText: 'Piece',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: row.tempoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: row.passageController,
              decoration: const InputDecoration(
                labelText: 'Passage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
  decoration: const InputDecoration(
    labelText: 'Strategy',
    border: OutlineInputBorder(),
  ),
  initialValue: availableStrategies.contains(row.strategyController.text)
      ? row.strategyController.text
      : null,
  items: availableStrategies.map((strategy) {
    return DropdownMenuItem<String>(
      value: strategy,
      child: Text(strategy),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      row.strategyController.text = value ?? '';
    });
  },
),
            const SizedBox(height: 20),
            TextField(
              controller: row.masteryController,
              decoration: const InputDecoration(
                labelText: 'Mastery',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Problems',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
),

Column(
  children: availableProblems.map((problem) {
    final isSelected = row.problems.contains(problem);

    return CheckboxListTile(
      title: Text(problem),
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            row.problems.add(problem);
          } else {
            row.problems.remove(problem);
          }
        });
      },
    );
  }).toList(),
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
            const SizedBox(height: 10),
            if (row.videoUrl != null)
              const Text('Video attached'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    sheetNameController.dispose();
    studentNameController.dispose();
    notesController.dispose();

    for (final row in editableRows) {
      row.pieceController.dispose();
      row.tempoController.dispose();
      row.passageController.dispose();
      row.strategyController.dispose();
      row.masteryController.dispose();
      row.monController.dispose();
      row.tueController.dispose();
      row.wedController.dispose();
      row.thuController.dispose();
      row.friController.dispose();
      row.satController.dispose();
      row.sunController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sheet'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: sheetNameController,
              decoration: const InputDecoration(
                labelText: 'Sheet Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: studentNameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ...editableRows.asMap().entries.map(
                  (entry) => _buildEditableRow(entry.value, entry.key),
                ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
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