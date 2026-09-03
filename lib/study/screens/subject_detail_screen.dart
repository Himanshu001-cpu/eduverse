import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final String subject;

  const SubjectDetailScreen({
    super.key,
    required this.courseId,
    required this.batchId,
    required this.subject,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  List<String> _currentPath = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'video', 'note', 'dpp'

  List<StudyLecture> _allLectures = [];
  List<StudyNote> _allNotes = [];
  List<StudyDpp> _allDpps = [];

  @override
  void initState() {
    super.initState();
    _loadAllResources();
  }

  Future<void> _loadAllResources() async {
    final controller = context.read<StudyController>();
    List<StudyLecture> lectures = [];
    List<StudyNote> notes = [];
    List<StudyDpp> dpps = [];

    try {
      lectures = await controller.getLectures(widget.courseId, widget.batchId);
    } catch (e) {
      debugPrint('SubjectDetailScreen: Error loading lectures: $e');
    }

    try {
      notes = await controller.getBatchNotes(widget.courseId, widget.batchId);
    } catch (e) {
      debugPrint('SubjectDetailScreen: Error loading notes: $e');
    }

    try {
      dpps = await controller.repository.getBatchDpps(widget.courseId, widget.batchId);
    } catch (e) {
      debugPrint('SubjectDetailScreen: Error loading DPPs: $e');
    }

    if (mounted) {
      setState(() {
        _allLectures = lectures.where((l) => l.subject == widget.subject).toList();
        _allNotes = notes.where((n) => n.subject == widget.subject).toList();
        _allDpps = dpps.where((d) => d.subject == widget.subject).toList();
        _isLoading = false;
      });
      debugPrint(
        'SubjectDetailScreen [${widget.subject}]: Loaded ${_allLectures.length} lectures, ${_allNotes.length} notes, ${_allDpps.length} dpps',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subject)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentFullPath = _currentPath.join('/');

    // 1. Filter resource items at current directory level
    final filteredLectures = _allLectures.where((l) => l.chapter == currentFullPath && l.type != 'folder').toList();
    final filteredNotes = _allNotes.where((n) => n.chapter == currentFullPath).toList();
    final filteredDpps = _allDpps.where((d) => d.chapter == currentFullPath).toList();

    // Sort lectures by orderIndex
    filteredLectures.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    // Sort notes and DPPs by date descending
    filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    filteredDpps.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 2. Identify unique subfolder segments directly beneath current path
    final Set<String> directSubfolders = {};

    void checkPath(String ch) {
      if (ch.isEmpty) return;
      if (currentFullPath.isEmpty) {
        final parts = ch.split('/');
        if (parts.isNotEmpty) directSubfolders.add(parts[0]);
      } else {
        final prefix = '$currentFullPath/';
        if (ch.startsWith(prefix)) {
          final remainder = ch.substring(prefix.length);
          final parts = remainder.split('/');
          if (parts.isNotEmpty) directSubfolders.add(parts[0]);
        }
      }
    }

    // Include explicit folder placeholders
    for (final l in _allLectures) {
      if (l.type == 'folder') {
        checkPath(l.chapter.isEmpty ? l.title : '${l.chapter}/${l.title}');
      }
    }
    for (final l in _allLectures) {
      if (l.type != 'folder') checkPath(l.chapter);
    }
    for (final n in _allNotes) {
      checkPath(n.chapter);
    }
    for (final d in _allDpps) {
      checkPath(d.chapter);
    }

    final subfoldersList = directSubfolders.toList()..sort();

    // Filter by search query if active
    final q = _searchQuery.toLowerCase();
    final displayLectures = _searchQuery.isEmpty
        ? filteredLectures
        : _allLectures.where((l) => l.type != 'folder' && l.title.toLowerCase().contains(q)).toList();
    final displayNotes = _searchQuery.isEmpty
        ? filteredNotes
        : _allNotes.where((n) => n.title.toLowerCase().contains(q)).toList();
    final displayDpps = _searchQuery.isEmpty
        ? filteredDpps
        : _allDpps.where((d) => d.title.toLowerCase().contains(q)).toList();

    final showLectures = (_activeFilter == 'all' || _activeFilter == 'video') && displayLectures.isNotEmpty;
    final showNotes = (_activeFilter == 'all' || _activeFilter == 'note') && displayNotes.isNotEmpty;
    final showDpps = (_activeFilter == 'all' || _activeFilter == 'dpp') && displayDpps.isNotEmpty;

    final isOverallEmpty = !showLectures && !showNotes && !showDpps && (_searchQuery.isNotEmpty || subfoldersList.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAllResources();
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.indigo.shade50.withValues(alpha: 0.2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Glassmorphic search bar
            _buildSearchBar(),
            // Breadcrumbs navigation
            _buildBreadcrumbs(),
            // Filter chips bar
            _buildFilterChips(filteredLectures.length, filteredNotes.length, filteredDpps.length),
            // Main list / grids
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllResources,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Subfolders (only if search is empty and filter is 'all')
                    if (_searchQuery.isEmpty && subfoldersList.isNotEmpty && _activeFilter == 'all') ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
                          child: Text(
                            'FOLDERS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final folderName = subfoldersList[index];
                              final targetPath = currentFullPath.isEmpty ? folderName : '$currentFullPath/$folderName';

                              // Recursively count folder items
                              final rLecCount = _allLectures.where((l) => l.type != 'folder' && (l.chapter == targetPath || l.chapter.startsWith('$targetPath/'))).length;
                              final rNoteCount = _allNotes.where((n) => n.chapter == targetPath || n.chapter.startsWith('$targetPath/')).length;
                              final rDppCount = _allDpps.where((d) => d.chapter == targetPath || d.chapter.startsWith('$targetPath/')).length;

                              return _buildFolderCard(folderName, rLecCount, rNoteCount, rDppCount);
                            },
                            childCount: subfoldersList.length,
                          ),
                        ),
                      ),
                    ],

                    // 1. LECTURES SECTION
                    if (showLectures) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, size: 16, color: Colors.red.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'LECTURES (${displayLectures.length})',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildFileItemTile(displayLectures[index]),
                            childCount: displayLectures.length,
                          ),
                        ),
                      ),
                    ],

                    // 2. DEDICATED NOTES SECTION
                    if (showNotes) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.description, size: 16, color: Colors.orange.shade800),
                              const SizedBox(width: 6),
                              Text(
                                'STUDY NOTES (${displayNotes.length})',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildFileItemTile(displayNotes[index]),
                            childCount: displayNotes.length,
                          ),
                        ),
                      ),
                    ],

                    // 3. DEDICATED DPPS SECTION
                    if (showDpps) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.assignment, size: 16, color: Colors.purple.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'DAILY PRACTICE PROBLEMS (DPPs) (${displayDpps.length})',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple.shade900, letterSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildFileItemTile(displayDpps[index]),
                            childCount: displayDpps.length,
                          ),
                        ),
                      ),
                    ],

                    // EMPTY STATE
                    if (isOverallEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty ? 'No resources in this section.' : 'No resources match your search.',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(int lecCount, int noteCount, int dppCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', lecCount + noteCount + dppCount),
          const SizedBox(width: 8),
          _buildFilterChip('Lectures', 'video', lecCount),
          const SizedBox(width: 8),
          _buildFilterChip('Notes', 'note', noteCount),
          const SizedBox(width: 8),
          _buildFilterChip('DPPs', 'dpp', dppCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _activeFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _activeFilter = value);
        }
      },
      selectedColor: Colors.indigo.shade600,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.indigo.shade900,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      elevation: isSelected ? 2 : 0,
      side: BorderSide(
        color: isSelected ? Colors.indigo.shade600 : Colors.indigo.shade100,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search videos, notes, DPPs...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final List<Widget> children = [];

    // Root Icon
    children.add(
      IconButton(
        icon: const Icon(Icons.grid_view_rounded, size: 20, color: Colors.indigo),
        onPressed: () {
          setState(() {
            _currentPath = [];
          });
        },
      ),
    );

    for (int i = 0; i < _currentPath.length; i++) {
      final segment = _currentPath[i];
      children.add(Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400));
      children.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _currentPath = _currentPath.sublist(0, i + 1);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              segment,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.indigo,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: children,
        ),
      ),
    );
  }

  Widget _buildFolderCard(String name, int lecs, int notes, int dpps) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentPath.add(name);
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade600, Colors.purple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade700.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              radius: 18,
              child: const Icon(Icons.folder_open_outlined, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$lecs Lec • $notes Note${notes != 1 ? 's' : ''} • $dpps DPP${dpps != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFileItemTile(dynamic item) {
    if (item is StudyLecture) {
      // Find linked notes and DPPs for this lecture
      final linkedNotes = _allNotes.where((n) => item.linkedNoteIds.contains(n.id) || n.lectureId == item.id).toList();
      final linkedDpps = _allDpps.where((d) => d.lectureId == item.id).toList();

      final trailingWidget = item.isWatched
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green.shade800),
                  const SizedBox(width: 4),
                  Text('WATCHED', style: TextStyle(color: Colors.green.shade800, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: Icon(Icons.play_arrow, color: Colors.red.shade700),
            );

      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade700.withValues(alpha: 0.1),
                radius: 22,
                child: Icon(Icons.play_circle_fill, color: Colors.red.shade700, size: 24),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Video',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.lectureNo != null ? 'Lecture #${item.lectureNo}' : 'Video Lesson',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: trailingWidget,
              onTap: () async {
                final controller = context.read<StudyController>();
                final progressBox = controller.lectureProgressBox;
                final progressData = progressBox.get(item.id);
                int startSeconds = 0;
                if (progressData != null) {
                  try {
                    final map = Map<String, dynamic>.from(progressData);
                    startSeconds = (map['progressSeconds'] as num).toInt();
                  } catch (_) {}
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: controller,
                      child: LecturePlayerScreen(
                        courseId: widget.courseId,
                        batchId: widget.batchId,
                        lecture: item,
                        startPositionSeconds: startSeconds,
                      ),
                    ),
                  ),
                );
                // Mark watched
                try {
                  await controller.markLectureWatched(widget.courseId, widget.batchId, item.id, true);
                } catch (_) {}
              },
            ),

            // LINKED NOTES & DPPS ATTACHED DIRECTLY ON LECTURE CARD
            if (linkedNotes.isNotEmpty || linkedDpps.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_file, size: 14, color: Colors.orange.shade800),
                        const SizedBox(width: 4),
                        Text(
                          'ATTACHED RESOURCES (${linkedNotes.length + linkedDpps.length})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...linkedNotes.map((note) => InkWell(
                      onTap: () async {
                        if (note.fileUrl != null) {
                          await PdfNavigationManager.navigateToViewer(
                            context,
                            SecurePdfViewerArgs(pdfUrl: note.fileUrl!, title: note.title, isProtected: false),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 16, color: Colors.orange.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'OPEN PDF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: Colors.orange.shade800),
                          ],
                        ),
                      ),
                    )),
                    ...linkedDpps.map((dpp) => InkWell(
                      onTap: () async {
                        await PdfNavigationManager.navigateToViewer(
                          context,
                          SecurePdfViewerArgs(pdfUrl: dpp.dppPdfUrl, title: '${dpp.title} (DPP)', isProtected: false),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.assignment, size: 16, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dpp.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'OPEN DPP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: Colors.purple.shade700),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } else if (item is StudyNote) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orange.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            radius: 22,
            child: Icon(Icons.picture_as_pdf, color: Colors.orange.shade800, size: 24),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text('PDF Document', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.orange),
            onPressed: () async {
              if (item.fileUrl != null) {
                await PdfNavigationManager.navigateToViewer(
                  context,
                  SecurePdfViewerArgs(pdfUrl: item.fileUrl!, title: item.title, isProtected: false),
                );
              }
            },
          ),
          onTap: () async {
            if (item.fileUrl != null) {
              await PdfNavigationManager.navigateToViewer(
                context,
                SecurePdfViewerArgs(pdfUrl: item.fileUrl!, title: item.title, isProtected: false),
              );
            }
          },
        ),
      );
    } else if (item is StudyDpp) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.purple.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: Colors.purple.shade100,
            radius: 22,
            child: Icon(Icons.assignment, color: Colors.purple.shade700, size: 24),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DPP',
                  style: TextStyle(color: Colors.purple.shade900, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text('Daily Practice Problem', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.assignment, color: Colors.purple),
                tooltip: 'View Question',
                onPressed: () async {
                  await PdfNavigationManager.navigateToViewer(
                    context,
                    SecurePdfViewerArgs(pdfUrl: item.dppPdfUrl, title: '${item.title} (DPP)', isProtected: false),
                  );
                },
              ),
              if (item.solutionPdfUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.done_all_rounded, color: Colors.green),
                  tooltip: 'View Solution',
                  onPressed: () async {
                    await PdfNavigationManager.navigateToViewer(
                      context,
                      SecurePdfViewerArgs(pdfUrl: item.solutionPdfUrl, title: '${item.title} (Solution)', isProtected: false),
                    );
                  },
                ),
            ],
          ),
          onTap: () async {
            await PdfNavigationManager.navigateToViewer(
              context,
              SecurePdfViewerArgs(pdfUrl: item.dppPdfUrl, title: '${item.title} (DPP)', isProtected: false),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
