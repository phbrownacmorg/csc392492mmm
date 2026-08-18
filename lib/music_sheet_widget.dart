import 'package:firebase_auth/firebase_auth.dart';
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

  Stream<Uint8List>? selectedVideoByteStream;
  String? selectedVideoName;

  final TextEditingController notesController = TextEditingController();
  final TextEditingController worksheetNameController = TextEditingController();

  List<String> strategies = [];
  List<String> pieces = [];
  //avoid duplicaring code for the practice log
  bool _readOnlyHelperFunction(PlutoRow row, PlutoCell cell) {
      final piece = row.cells['strategy']?.value?.toString().trim() ?? '';
      return piece.isEmpty;
  }


  @override
  void initState() {
    super.initState();

    columns = [
      PlutoColumn(
        title: 'Piece',
        field: 'piece',
        type: PlutoColumnType.select(pieces),
        enableSorting: false,
      ),
      PlutoColumn(
        title: 'Tempo',
        field: 'tempo',
        type: PlutoColumnType.number(),
        enableSorting: false,
        checkReadOnly: (row, cell) {
          final piece = row.cells['piece']?.value?.toString().trim() ?? '';
          return piece.isEmpty;
        },
      ),
      PlutoColumn(
        title: 'Practice Passage',
        field: 'passage',
        type: PlutoColumnType.text(),
        enableSorting: false,
        checkReadOnly: (row, cell) {
          final piece = row.cells['piece']?.value?.toString().trim() ?? '';
          return piece.isEmpty;
        },
      ),
      PlutoColumn(
        title: 'Problems',
        field: 'problems',
        type: PlutoColumnType.text(),
        enableSorting: false,
        checkReadOnly: (row, cell) {
          final piece = row.cells['piece']?.value?.toString().trim() ?? '';
          return piece.isEmpty;
        },
      ),
      PlutoColumn(
        title: 'Practice Strategy',
        field: 'strategy',
        type: PlutoColumnType.select(strategies),
        enableSorting: false,
        checkReadOnly: (row, cell) {
          final passage = row.cells['passage']?.value?.toString().trim() ?? '';
          return passage.isEmpty;
        },
      ),
      PlutoColumn(
        title: 'M',
        field: 'mon',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'T',
        field: 'tue',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'W',
        field: 'wed',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'H',
        field: 'thu',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'F',
        field: 'fri',
        type: PlutoColumnType.number(),
        width: 50,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'Sat',
        field: 'sat',
        type: PlutoColumnType.number(),
        width: 70,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'Sun',
        field: 'sun',
        type: PlutoColumnType.number(),
        width: 70,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
      PlutoColumn(
        title: 'Mastery',
        field: 'mastery',
        type: PlutoColumnType.select(['Mastered', 'Not Mastered']),
        width: 120,
        enableSorting: false,
        checkReadOnly: _readOnlyHelperFunction,
      ),
    ];

    rows = [
      _createNewPracticeRow(),
    ];

    _fetchStrategiesFromFirestore();
    _fetchPiecesFromFirestore();
  }

  Future<void> _fetchPiecesFromFirestore() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('pieces').get();

      final loadedPieces = querySnapshot.docs
          .map((doc) => doc['name'].toString())
          .toList();

      setState(() {
        pieces = loadedPieces;

        final pieceColumn = columns.firstWhere(
          (column) => column.field == 'piece',
        );

        pieceColumn.type = PlutoColumnType.select(pieces);
      });

      stateManager?.notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load pieces.')),
      );
    }
  }

  Future<void> _fetchStrategiesFromFirestore() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Strategies').get();

      final loadedStrategies = querySnapshot.docs
          .map((doc) => doc['strategy_name'].toString())
          .toList();

      setState(() {
        strategies = loadedStrategies;

        final strategyColumn = columns.firstWhere(
          (column) => column.field == 'strategy',
        );

        strategyColumn.type = PlutoColumnType.select(strategies);
      });

      stateManager?.notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load strategies.')),
      );
    }
  }

  PlutoRow _createNewPracticeRow() {
    return PlutoRow(
      cells: {
        'piece': PlutoCell(value: ''),
        'tempo': PlutoCell(value: 80),
        'passage': PlutoCell(value: ''),
        'problems': PlutoCell(value: ''),
        'strategy': PlutoCell(value: ''),
        'mon': PlutoCell(value: 0),
        'tue': PlutoCell(value: 0),
        'wed': PlutoCell(value: 0),
        'thu': PlutoCell(value: 0),
        'fri': PlutoCell(value: 0),
        'sat': PlutoCell(value: 0),
        'sun': PlutoCell(value: 0),
        'mastery': PlutoCell(value: 'Not Mastered'),
      },
    );
  }

  void _addNewRow() {
    if (stateManager != null) {
      stateManager!.appendRows([_createNewPracticeRow()]);
    } else {
      rows.add(_createNewPracticeRow());
    }
  }

  Future<void> _pickVideo() async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.video,
      //withData: true,
    );

    if (result != null) {
      setState(() {
        selectedVideoByteStream = result.readAsByteStream();
        selectedVideoName = result.name;
      });
    }
  }

  void _removeSelectedVideo() {
    setState(() {
      selectedVideoByteStream = null;
      selectedVideoName = null;
    });
  }

  String _getWorksheetName() {
    if (worksheetNameController.text.trim().isNotEmpty) {
      return worksheetNameController.text.trim();
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    return 'Music Sheet - ${now.month}/${now.day}/${now.year} - ${currentUser?.email ?? 'Guest'}';
  }

  Map<String, dynamic> _getSheetData() {
    final gridRows = stateManager?.rows ?? rows;

    final rowData = gridRows.map((row) {
      return {
        'piece': row.cells['piece']?.value,
        'tempo': row.cells['tempo']?.value,
        'passage': row.cells['passage']?.value,
        'problems': row.cells['problems']?.value,
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
      'sheetName': _getWorksheetName(),
      'rows': rowData,
      'notes': notesController.text.trim(),
      'videoName': selectedVideoName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _saveSheet() async {
    try {
      if (stateManager == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grid not ready yet. Try again.')),
        );
        return;
      }

      String? videoUrl;

      if (selectedVideoByteStream != null && selectedVideoName != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('music_sheet_videos/$selectedVideoName');

        final BytesBuilder videoBytes = BytesBuilder();
        await for (final chunk in selectedVideoByteStream!) {
          videoBytes.add(chunk);
        }

        await storageRef.putData(videoBytes.toBytes());
        videoUrl = await storageRef.getDownloadURL();
      }

      final data = _getSheetData();
      data['videoUrl'] = videoUrl;

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        data['userId'] = currentUser.uid;
        data['creatorEmail'] = currentUser.email;
      }

      await FirebaseFirestore.instance.collection('music_sheets').add(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet not saved. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    worksheetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: worksheetNameController,
              decoration: const InputDecoration(
                labelText: 'Worksheet Name',
                hintText: 'Name your worksheet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Enter your notes here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Row'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Upload Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            if (selectedVideoName != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Selected: $selectedVideoName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove selected video',
                    onPressed: _removeSelectedVideo,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSheet,
              icon: const Icon(Icons.save),
              label: const Text('Save Sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}