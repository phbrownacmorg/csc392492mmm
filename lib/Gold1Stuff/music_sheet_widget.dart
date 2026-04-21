import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:file_picker/file_picker.dart';

class MusicSheetWidget extends StatefulWidget {
  const MusicSheetWidget({super.key});

  @override
  State<MusicSheetWidget> createState() => _MusicSheetWidgetState();
}

class _MusicSheetWidgetState extends State<MusicSheetWidget> {
  late List<PlutoColumn> columns;
  late List<PlutoRow> rows;
  late PlutoGridStateManager stateManager;
  String? selectedVideoPath;
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
      stateManager.resetCurrentState();
    });
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        selectedVideoPath = result.files.single.path;
      });
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
            if (selectedVideoPath != null) ...[
              const SizedBox(height: 10),
              Text('Selected: $selectedVideoPath'),
            ],
          ],
        ),
      ),
    );
  }
}