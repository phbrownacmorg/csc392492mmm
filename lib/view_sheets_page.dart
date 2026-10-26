import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'music_sheet_widget.dart';

class ViewSheetsPage extends StatefulWidget {
  final String? studentId;
  final bool studentView;

  const ViewSheetsPage({
    super.key,
    this.studentId,
    this.studentView = false,
  });

  @override
  State<ViewSheetsPage> createState() => _ViewSheetsPageState();
}

class _ViewSheetsPageState extends State<ViewSheetsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  bool _showAllSheets = false;
  bool _showAssignedSheets = true;
  List<String> _assignedSheetIds = [];
  Map<String, String> _assignedClonesByOriginalId = {};
  List<Map<String, String>> _acceptedPeers = [];

  @override
  void initState() {
    super.initState();
    _loadAssignedSheets();
    _loadAcceptedPeers();
  }

  Future<void> _loadAcceptedPeers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final sentSnapshot = await FirebaseFirestore.instance
          .collection('Connections')
          .where('requesterId', isEqualTo: currentUser.uid)
          .get();

      final receivedSnapshot = await FirebaseFirestore.instance
          .collection('Connections')
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      final peers = <String, String>{};

      for (final connection in [
        ...sentSnapshot.docs,
        ...receivedSnapshot.docs,
      ]) {
        final data = connection.data();

        if (data['connectionType'] != 'peer' ||
            data['accepted'] == null) {
          continue;
        }

        final peerId = data['requesterId'] == currentUser.uid
            ? data['receiverId']
            : data['requesterId'];

        if (peerId is! String ||
            peerId.isEmpty ||
            peerId == currentUser.uid) {
          continue;
        }

        final peerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(peerId)
            .get();

        if (!peerDoc.exists) continue;

        final peerData = peerDoc.data();
        final peerName =
            '${peerData?['firstName'] ?? ''} ${peerData?['lastName'] ?? ''}'
                .trim();

        peers[peerId] = peerName.isEmpty ? 'Unknown Peer' : peerName;
      }

      if (!mounted) return;

      setState(() {
        _acceptedPeers = peers.entries
            .map((entry) => {
                  'id': entry.key,
                  'name': entry.value,
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading accepted peers: $e');
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedSheets() async {
    final studentId =
        widget.studentId ?? FirebaseAuth.instance.currentUser?.uid;

    if (studentId == null) {
      return;
    }

    final studentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .get();

    final assignedSheets = studentDoc.data()?['assignedSheets'];

    final assignedIds = assignedSheets is List
        ? assignedSheets.map((id) => id.toString()).toList()
        : <String>[];

    final clonesByOriginalId = <String, String>{};
    final currentUser = FirebaseAuth.instance.currentUser;

    for (final assignedId in assignedIds) {
      final sheetDoc = await FirebaseFirestore.instance
          .collection('music_sheets')
          .doc(assignedId)
          .get();

      if (!sheetDoc.exists) continue;

      final sheetData = sheetDoc.data()!;
      final backlink = sheetData['backlink'];

      if (backlink is String &&
          sheetData['Assigned'] == currentUser?.uid) {
        clonesByOriginalId[backlink] = assignedId;
      }
    }

    if (!mounted) return;

    setState(() {
      _assignedSheetIds = assignedIds;
      _assignedClonesByOriginalId = clonesByOriginalId;
    });
  }
  Future<void> _assignSheet(String sheetId) async {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (widget.studentId == null || currentUser == null) {
        return;
      }

      final bool? restrictWrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assignment Permissions'),
          content: const Text(
            'Should the student have limited or full editing permissions?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Full Editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limited Editing'),
            ),
          ],
        ),
      );

      if (restrictWrite == null) return;

      final originalSheet = await FirebaseFirestore.instance
          .collection('music_sheets')
          .doc(sheetId)
          .get();

      if (!originalSheet.exists) {
        return;
      }
      
      final existingAssignment = await FirebaseFirestore.instance
          .collection('music_sheets')
          .where('userId', isEqualTo: widget.studentId)
          .where('backlink', isEqualTo: sheetId)
          .where('creatorEmail', isEqualTo: currentUser.email)
          .get();

      if (existingAssignment.docs.isNotEmpty) {
        final activeCopies = existingAssignment.docs.where(
          (doc) => doc.data()['Assigned'] != null,
        );

        if (activeCopies.isNotEmpty) {
          return;
        }

        final previousCopy = existingAssignment.docs.first;

        await previousCopy.reference.update({
          'Assigned': currentUser.uid,
          'restrictWrite': restrictWrite,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentId)
            .update({
          'assignedSheets': FieldValue.arrayUnion([previousCopy.id]),
        });

        await _loadAssignedSheets();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sheet reassigned successfully')),
        );

        return;
      }

      final originalData = originalSheet.data()!;

      final clonedSheet = await FirebaseFirestore.instance
          .collection('music_sheets')
          .add({
        ...originalData,
        'userId': widget.studentId,
        'backlink': sheetId,
        'creatorEmail': currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
        'creationDate': FieldValue.serverTimestamp(),
        'Assigned': currentUser.uid,
        'restrictWrite': restrictWrite,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .update({
        'assignedSheets': FieldValue.arrayUnion([clonedSheet.id]),
      });

      await _loadAssignedSheets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet assigned successfully')),
      );
    }
    Future<void> _unassignSheet(String sheetId) async {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (widget.studentId == null || currentUser == null) {
        return;
      }

      final sheetDoc = await FirebaseFirestore.instance
          .collection('music_sheets')
          .doc(sheetId)
          .get();

      if (!sheetDoc.exists) return;

      final sheetData = sheetDoc.data()!;

      if (sheetData['userId'] != widget.studentId ||
          sheetData['Assigned'] != currentUser.uid) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .update({
        'assignedSheets': FieldValue.arrayRemove([sheetId]),
      });

      await FirebaseFirestore.instance
          .collection('music_sheets')
          .doc(sheetId)
          .update({
        'Assigned': null,
        'restrictWrite': null,
      });

      await _loadAssignedSheets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sheet unassigned successfully')),
      );
    }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getSheetsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('music_sheets');

    if (currentUser == null) {
      return query
          .where('userId', isEqualTo: '__no_user__')
          .snapshots();
    }

    if (widget.studentId == null) {
      query = query.where(
        Filter.or(
          Filter('userId', isEqualTo: currentUser.uid),
          Filter('Assigned', isEqualTo: currentUser.uid),
        ),
      );
    }

    return query.snapshots();
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
    final sheetDoc = await FirebaseFirestore.instance
        .collection('music_sheets')
        .doc(documentId)
        .get();

    if (!sheetDoc.exists) return;

    final ownerId = sheetDoc.data()?['userId'];

    if (ownerId is String && ownerId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .update({
        'assignedSheets': FieldValue.arrayRemove([documentId]),
      });
    }
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
  Future<void> _pushSheetToPeer(
    String sheetId,
    String peerId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || peerId == currentUser.uid) {
      return;
    }

    try {
      final originalSheet = await FirebaseFirestore.instance
          .collection('music_sheets')
          .doc(sheetId)
          .get();

      if (!originalSheet.exists) return;

      final originalData = originalSheet.data()!;

      if (originalData['userId'] != currentUser.uid) {
        return;
      }

      final existingCopies = await FirebaseFirestore.instance
          .collection('music_sheets')
          .where('userId', isEqualTo: peerId)
          .where('backlink', isEqualTo: sheetId)
          .get();

      if (existingCopies.docs.isNotEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This sheet has already been sent to this peer'),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('music_sheets')
          .add({
        ...originalData,
        'userId': peerId,
        'backlink': sheetId,
        'creatorEmail': currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
        'creationDate': FieldValue.serverTimestamp(),
        'Assigned': null,
        'restrictWrite': false,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sheet pushed to peer successfully'),
        ),
      );
    } catch (e) {
      debugPrint('Error pushing sheet to peer: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not push sheet to peer'),
        ),
      );
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
    final currentUser = FirebaseAuth.instance.currentUser;

    final isOwner =
        currentUser != null &&
        data['userId'] == currentUser.uid;

    final canRenameOrDelete =
        isOwner &&
        data['Assigned'] == null;
        
    final isAssignedCopy =
        data['userId'] == widget.studentId &&
        data['Assigned'] == FirebaseAuth.instance.currentUser?.uid &&
        _assignedSheetIds.contains(documentId);

    final assignedCloneId = _assignedClonesByOriginalId[documentId];

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
              if (widget.studentId != null)
                TextButton.icon(
                  onPressed: () {
                    if (isAssignedCopy) {
                      _unassignSheet(documentId);
                    } else if (assignedCloneId != null) {
                      _unassignSheet(assignedCloneId);
                    } else {
                      _assignSheet(documentId);
                    }
                  },
                  icon: Icon(
                    isAssignedCopy || assignedCloneId != null
                        ? Icons.remove_circle_outline
                        : Icons.assignment_add,
                  ),
                  label: Text(
                    isAssignedCopy || assignedCloneId != null
                        ? 'Unassign'
                        : 'Assign',
                  ),
                ),
              TextButton.icon(
                onPressed: isOwner
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Push Sheet to Peer'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_acceptedPeers.isEmpty)
                                const ListTile(
                                  title: Text('No accepted peers found'),
                                ),
                              ..._acceptedPeers.map((peer) {
                                return ListTile(
                                  leading: const Icon(Icons.person_outline),
                                  title: Text(peer['name'] ?? 'Unknown Peer'),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    final peerId = peer['id'];

                                    if (peerId != null) {
                                      await _pushSheetToPeer(documentId, peerId);
                                    }
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    );
                  }
                : null,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Push Sheet'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
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

                  if (mounted) {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),      

              TextButton.icon(
                onPressed: canRenameOrDelete
                    ? () => _renameSheet(documentId, sheetName)
                    : null,
                icon: const Icon(Icons.drive_file_rename_outline),
                label: const Text('Rename'),
              ),
              TextButton.icon(
                onPressed: canRenameOrDelete
                    ? () => _confirmDelete(documentId)
                    : null,
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
        actions: [
          TextButton.icon(
            onPressed: () async {
                final newSheetId = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('New Sheet'),
                        backgroundColor: Colors.deepOrange,
                      ),
                      body: const MusicSheetWidget(),
                    ),
                  ),
                );

                if (newSheetId != null && widget.studentId != null) {
                  await _assignSheet(newSheetId);
                }
              },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(
              Icons.add,
              size: 24,
            ),
            label: const Text(
              'New Sheet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.studentId != null)
              SwitchListTile(
                title: const Text('Show assigned sheets'),
                subtitle: Text(
                  _showAssignedSheets
                      ? 'Showing sheets assigned to this student'
                      : 'Showing assigned sheets and your own sheets',
                ),
                value: _showAssignedSheets,
                onChanged: (value) {
                  setState(() {
                    _showAssignedSheets = value;
                  });
                },
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
                    if (!_sheetMatchesSearch(doc.data())) {
                      return false;
                    }

                    if (widget.studentId != null) {
                      final isAssigned = _assignedSheetIds.contains(doc.id);

                      if (_showAssignedSheets) {
                        return isAssigned;
                      } else {
                        final isInstructorOwned =
                            currentUser != null &&
                            doc.data()['userId'] == currentUser.uid;

                        return isAssigned || isInstructorOwned;
                      }
                    }

                    // Student viewing their own View Sheets page.
                    if (widget.studentView) {
                      if (_showAllSheets) {
                        return true;
                      }

                      final isOwned = doc.data()['userId'] ==
                          FirebaseAuth.instance.currentUser?.uid;

                      final isAssigned = _assignedSheetIds.contains(doc.id);

                      return isOwned || isAssigned;
                    }

                    // Instructor viewing View Sheets normally.
                    return currentUser != null &&
                        (doc.data()['userId'] == currentUser.uid ||
                            doc.data()['Assigned'] == currentUser.uid);
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