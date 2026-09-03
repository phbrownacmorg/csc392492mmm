import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
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
                'Problems: ${problems is List ? problems.join(', ') : (problems is String ? problems : '')}',
              ),
              Text(
                'Days: M ${row['mon'] ?? 0}, T ${row['tue'] ?? 0}, W ${row['wed'] ?? 0}, H ${row['thu'] ?? 0}, F ${row['fri'] ?? 0}, Sat ${row['sat'] ?? 0}, Sun ${row['sun'] ?? 0}',
              ),
              if (row['videoUrl'] != null &&
                  row['videoUrl'].toString().isNotEmpty)
                SheetVideoPlayer(
                  videoUrl: row['videoUrl'].toString(),
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
          if (data['videoUrl'] != null &&
              data['videoUrl'].toString().isNotEmpty)
            SheetVideoPlayer(
              videoUrl: data['videoUrl'].toString(),
            ),

const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Edit Music Sheet'),
                          backgroundColor: Colors.deepOrange,
                        ),
                        body: MusicSheetWidget(
                          documentId: documentId,
                          initialData: data,
                        ),
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

class SheetVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const SheetVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<SheetVideoPlayer> createState() => _SheetVideoPlayerState();
}

class _SheetVideoPlayerState extends State<SheetVideoPlayer> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize().timeout(
        const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Video unavailable',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 140,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}