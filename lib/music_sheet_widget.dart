import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MusicSheetWidget extends StatefulWidget {
  const MusicSheetWidget({super.key});

  @override
  State<MusicSheetWidget> createState() => _MusicSheetWidgetState();
}

class _MusicSheetWidgetState extends State<MusicSheetWidget> { 
  late List<PlutoColumn> columns;
  late List<PlutoRow> rows;
  PlutoGridStateManager? stateManager;
  Uint8List? selectedVideoBytes;
  String? selectedVideoName;
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    columns = [
      PlutoColumn(
        title: 'Piece',
        field: 'piece',
        type: PlutoColumnType.select([
          'Concerto No. 5',
          'Etude No. 7',
          'Scale Drill',
          'Antonio Vivaldi',
        ]),
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Tempo',
        field: 'tempo',
        type: PlutoColumnType.number(),
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Practice Passage',
        field: 'passage',
        type: PlutoColumnType.text(),
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Practice Strategy',
        field: 'strategy',
        type: PlutoColumnType.text(),
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'M',
        field: 'mon',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'T',
        field: 'tue',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'W',
        field: 'wed',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'H',
        field: 'thu',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'F',
        field: 'fri',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Sat',
        field: 'sat',
        type: PlutoColumnType.number(),
        width: 70,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Sun',
        field: 'sun',
        type: PlutoColumnType.number(),
        width: 70,
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Mastery',
        field: 'mastery',
        type: PlutoColumnType.select(["Mastered", "Not Mastered"]),
        width: 90,
        enableSorting: false,
      ),
    ];

    rows = [
      _createNewPracticeRow(),
    ];
  }

  PlutoRow _createNewPracticeRow() {
    return PlutoRow(cells: {
      'piece': PlutoCell(value: 'Select a piece'),
      'tempo': PlutoCell(value: 80),
      'passage': PlutoCell(value: 'Select a passage'),
      'strategy': PlutoCell(value: 'Select a strategy'),
      'mon': PlutoCell(value: 0),
      'tue': PlutoCell(value: 0),
      'wed': PlutoCell(value: 0),
      'thu': PlutoCell(value: 0),
      'fri': PlutoCell(value: 0),
      'sat': PlutoCell(value: 0),
      'sun': PlutoCell(value: 0),
      'mastery': PlutoCell(value: "Not Mastered"),
    });
  }

  void _addNewRow() {
    setState(() {
      rows.add(_createNewPracticeRow());
      stateManager?.resetCurrentState();
    });
  }

  Future<void> _pickVideo() async {
  FilePickerResult? result = await FilePicker.pickFiles(
    type: FileType.video,
    withData: true,
  );

  if (result != null) {
    setState(() {
      selectedVideoBytes = result.files.single.bytes;
      selectedVideoName = result.files.single.name;
    });
  }
}
  Map<String, dynamic> _getSheetData() {
  List<Map<String, dynamic>> rowData =
    stateManager!.rows.map((row) {
    return {
      'piece': row.cells['piece']?.value,
      'tempo': row.cells['tempo']?.value,
      'passage': row.cells['passage']?.value,
      'strategy': row.cells['strategy']?.value,
      'mon': row.cells['mon']?.value,
      'tue': row.cells['tue']?.value,
      'wed': row.cells['wed']?.value,
      'thu': row.cells['thu']?.value,
      'fri': row.cells['fri']?.value,
      'sat': row.cells['sat']?.value,
      'sun': row.cells['sun']?.value,
      'mastery': row.cells['mastery']?.value,
    };
  }).toList();

  return {
    'rows': rowData,
    'notes': notesController.text,
    'videoName': selectedVideoName,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

Future<void> _saveSheet() async {
  print("1 - _saveSheet started");

  try {
    print("2 - checking stateManager");

    if (stateManager == null) {
      print("STOP - stateManager is null");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grid not ready yet. Try again.'),
        ),
      );
      return;
    }

    print("3 - stateManager is ready");

    String? videoUrl;

    if (selectedVideoBytes != null && selectedVideoName != null) {
      print("4 - video selected: $selectedVideoName");

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('music_sheet_videos/$selectedVideoName');

      print("5 - uploading video to storage");

      await storageRef.putData(selectedVideoBytes!);

      print("6 - video uploaded");

      videoUrl = await storageRef.getDownloadURL();

      print("7 - video URL received: $videoUrl");
    } else {
      print("4 - no video selected");
    }

    print("8 - getting sheet data");

    final data = _getSheetData();
    data['videoUrl'] = videoUrl;

    print("9 - saving to Firestore");

    await FirebaseFirestore.instance
        .collection('music_sheets')
        .add(data);

    print("10 - Firestore save complete");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sheet and video saved to Firebase!'),
      ),
    );
  } catch (e, stackTrace) {
    print("SAVE SHEET ERROR: $e");
    print(stackTrace);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving sheet: $e'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: PlutoGrid(
                columns: columns,
                rows: rows,
                onLoaded: (event) => stateManager = event.stateManager,
                configuration: PlutoGridConfiguration(
                  style: PlutoGridStyleConfig(
                    borderColor: Colors.grey,
                    gridBorderColor: Colors.grey,
                  ),
                  columnFilter: PlutoGridColumnFilterConfig(),
                ),
                columnGroups: [
                  PlutoColumnGroup(
                    title: 'Name',
                    children: [
                      PlutoColumnGroup(title: 'Piece', fields: ['piece']),
                      PlutoColumnGroup(title: 'Tempo', fields: ['tempo']),
                    ],
                  ),
                  PlutoColumnGroup(
                    title: 'My Music Mastery',
                    children: [
                      PlutoColumnGroup(title: 'Practice Passage', fields: ['passage']),
                      PlutoColumnGroup(title: 'Practice Strategy', fields: ['strategy']),
                    ],
                  ),
                  PlutoColumnGroup(
                    title: 'Days Practiced',
                    children: [
                      PlutoColumnGroup(title: 'M', fields: ['mon']),
                      PlutoColumnGroup(title: 'T', fields: ['tue']),
                      PlutoColumnGroup(title: 'W', fields: ['wed']),
                      PlutoColumnGroup(title: 'H', fields: ['thu']),
                      PlutoColumnGroup(title: 'F', fields: ['fri']),
                      PlutoColumnGroup(title: 'Sat', fields: ['sat']),
                      PlutoColumnGroup(title: 'Sun', fields: ['sun']),
                      PlutoColumnGroup(title: 'Mastery', fields: ['mastery']),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Notes section as a separate component below the grid
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: const Text(
                      'Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter your notes here...',
                      ),
                      maxLines: 5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Row'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Upload Video'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
              ],
            ),
            if (selectedVideoName != null) ...[
            const SizedBox(height: 10),
            Text('Selected: $selectedVideoName'),
            ],
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
              debugPrint("SAVE BUTTON CLICKED");
              _saveSheet();
            },
              icon: const Icon(Icons.save),
              label: const Text('Save Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
