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
    try {
      final results = await Future.wait([
        controller.getLectures(widget.courseId, widget.batchId),
        controller.getBatchNotes(widget.courseId, widget.batchId),
        controller.repository.getBatchDpps(widget.courseId, widget.batchId),
      ]);

      if (mounted) {
        setState(() {
          _allLectures = (results[0] as List<StudyLecture>).where((l) => l.subject == widget.subject).toList();
          _allNotes = (results[1] as List<StudyNote>).where((n) => n.subject == widget.subject).toList();
          _allDpps = (results[2] as List<StudyDpp>).where((d) => d.subject == widget.subject).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

    // 3. Filter files/subfolders if search query is active
    List<dynamic> activeFiles = [];
    if (_searchQuery.isEmpty) {
      activeFiles.addAll(filteredLectures);
      activeFiles.addAll(filteredNotes);
      activeFiles.addAll(filteredDpps);
    } else {
      final q = _searchQuery.toLowerCase();
      activeFiles.addAll(_allLectures.where((l) => l.type != 'folder' && l.title.toLowerCase().contains(q)));
      activeFiles.addAll(_allNotes.where((n) => n.title.toLowerCase().contains(q)));
      activeFiles.addAll(_allDpps.where((d) => d.title.toLowerCase().contains(q)));
    }

    // Sort files: Lectures sorted by orderIndex/lectureNo, others by date
    activeFiles.sort((a, b) {
      int getOrder(dynamic item) {
        if (item is StudyLecture) return item.orderIndex;
        return 9999;
      }
      return getOrder(a).compareTo(getOrder(b));
    });

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
            // Main list / grids
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllResources,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Subfolders (only if search is empty)
                    if (_searchQuery.isEmpty && subfoldersList.isNotEmpty) ...[
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

                    // Files section
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
                        child: Text(
                          'RESOURCES',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                        ),
                      ),
                    ),

                    if (activeFiles.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty ? 'No resources in this folder level.' : 'No resources match your search.',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = activeFiles[index];
                              return _buildFileItemTile(item);
                            },
                            childCount: activeFiles.length,
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
    IconData iconData = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    String typeLabel = '';
    String title = '';
    String subtitle = '';
    Widget? trailingWidget;

    if (item is StudyLecture) {
      iconData = Icons.play_circle_fill;
      iconColor = Colors.red.shade700;
      typeLabel = 'Video';
      title = item.title;
      subtitle = item.lectureNo != null ? 'Lecture #${item.lectureNo}' : 'Video Lesson';

      // Trailing watch indicator
      trailingWidget = item.isWatched
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
    } else if (item is StudyNote) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.orange.shade800;
      typeLabel = 'Note';
      title = item.title;
      subtitle = 'PDF Document';

      trailingWidget = IconButton(
        icon: const Icon(Icons.download_for_offline_outlined, color: Colors.orange),
        onPressed: () async {
          if (item.fileUrl != null) {
            await PdfNavigationManager.navigateToViewer(
              context,
              SecurePdfViewerArgs(pdfUrl: item.fileUrl!, title: item.title, isProtected: false),
            );
          }
        },
      );
    } else if (item is StudyDpp) {
      iconData = Icons.assignment;
      iconColor = Colors.purple.shade700;
      typeLabel = 'DPP';
      title = item.title;
      subtitle = 'Daily Practice Problem';

      trailingWidget = Row(
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
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          radius: 22,
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          title,
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
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        trailing: trailingWidget,
        onTap: () async {
          if (item is StudyLecture) {
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
          } else if (item is StudyNote) {
            if (item.fileUrl != null) {
              await PdfNavigationManager.navigateToViewer(
                context,
                SecurePdfViewerArgs(pdfUrl: item.fileUrl!, title: item.title, isProtected: false),
              );
            }
          } else if (item is StudyDpp) {
            await PdfNavigationManager.navigateToViewer(
              context,
              SecurePdfViewerArgs(pdfUrl: item.dppPdfUrl, title: '${item.title} (DPP)', isProtected: false),
            );
          }
        },
      ),
    );
  }
}
