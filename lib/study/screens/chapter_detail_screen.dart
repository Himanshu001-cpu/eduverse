import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/common/services/download_service.dart';
import 'lecture_player_page.dart';

class ChapterDetailScreen extends StatefulWidget {
  final String courseId;
  final String batchId;
  final String subject;
  final String chapter;

  const ChapterDetailScreen({
    super.key,
    required this.courseId,
    required this.batchId,
    required this.subject,
    required this.chapter,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  List<StudyLecture> _lectures = [];
  List<StudyNote> _notes = [];
  List<StudyDpp> _dpps = [];
  bool _isLoading = true;
  final Set<String> _expandedLectures = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = context.read<StudyController>();
    try {
      final results = await Future.wait([
        controller.getLectures(widget.courseId, widget.batchId),
        controller.getBatchNotes(widget.courseId, widget.batchId),
        controller.repository.getBatchDpps(widget.courseId, widget.batchId),
      ]);

      if (mounted) {
        setState(() {
          _lectures = (results[0] as List<StudyLecture>)
              .where((l) => l.subject == widget.subject && l.chapter == widget.chapter)
              .toList();
          _notes = (results[1] as List<StudyNote>)
              .where((n) => n.subject == widget.subject && n.chapter == widget.chapter)
              .toList();
          _dpps = (results[2] as List<StudyDpp>)
              .where((d) => d.subject == widget.subject && d.chapter == widget.chapter)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Get notes linked to a specific lecture
  List<StudyNote> _getLinkedNotes(String lectureId) {
    return _notes.where((n) => n.lectureId == lectureId).toList();
  }

  // Get DPPs linked to a specific lecture
  List<StudyDpp> _getLinkedDpps(String lectureId) {
    return _dpps.where((d) => d.lectureId == lectureId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.chapter),
          elevation: 0,
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'Lectures'),
              Tab(text: 'Notes'),
              Tab(text: 'DPP'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildLecturesTab(primaryColor),
                  _buildNotesTab(),
                  _buildDppTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildLecturesTab(Color primaryColor) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withValues(alpha: 0.1), primaryColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.subject, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.subject,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: primaryColor.withValues(alpha: 0.5), size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.chapter,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.play_circle_fill,
                label: '${_lectures.length} Lectures',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.description,
                label: '${_notes.length} Notes',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.assignment,
                label: '${_dpps.length} DPPs',
                color: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lectures section
          if (_lectures.isNotEmpty) ...[
            _buildSectionHeader('Lectures', Icons.play_circle_fill, Colors.blue),
            const SizedBox(height: 8),
            ..._lectures.map((lecture) => _buildLectureTile(lecture)),
            const SizedBox(height: 20),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No lectures available yet',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No notes available.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildNoteTile(_notes[index]),
      ),
    );
  }

  Widget _buildDppTab() {
    if (_dpps.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No DPPs available.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _dpps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildDppTile(_dpps[index]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildLectureTile(StudyLecture lecture) {
    final isExpanded = _expandedLectures.contains(lecture.id);
    final linkedNotes = _getLinkedNotes(lecture.id);
    final linkedDpps = _getLinkedDpps(lecture.id);
    final hasLinkedDocs = linkedNotes.isNotEmpty || linkedDpps.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 1,
            shadowColor: Colors.black12,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LecturePlayerPage(
                      videoUrl: lecture.videoUrl,
                      title: lecture.title,
                      description: lecture.description,
                      subject: lecture.subject,
                      chapter: lecture.chapter,
                      lectureNo: lecture.lectureNo,
                      linkedNoteIds: lecture.linkedNoteIds,
                      courseId: widget.courseId,
                      batchId: widget.batchId,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Play icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          lecture.isWatched ? Icons.check_circle : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title & meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lecture.lectureNo != null
                                ? 'Lec ${lecture.lectureNo}: ${lecture.title}'
                                : lecture.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          if (hasLinkedDocs)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  if (linkedNotes.isNotEmpty) ...[
                                    Icon(Icons.description, size: 13, color: Colors.orange.shade600),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${linkedNotes.length}',
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (linkedDpps.isNotEmpty) ...[
                                    Icon(Icons.assignment, size: 13, color: Colors.deepPurple.shade400),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${linkedDpps.length}',
                                      style: TextStyle(fontSize: 11, color: Colors.deepPurple.shade400),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Expand toggle for linked docs
                    if (hasLinkedDocs)
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedLectures.remove(lecture.id);
                            } else {
                              _expandedLectures.add(lecture.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more,
                              color: Colors.grey.shade500,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Linked documents expansion
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildLinkedDocsSection(linkedNotes, linkedDpps),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedDocsSection(List<StudyNote> notes, List<StudyDpp> dpps) {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linked Resources',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...notes.map((note) => _buildLinkedDocRow(
                icon: Icons.description,
                color: Colors.orange,
                title: note.title,
                url: note.fileUrl,
                fileName: '${note.id}_note.pdf',
              )),
          ...dpps.map((dpp) => Column(
                children: [
                   _buildLinkedDocRow(
                    icon: Icons.assignment,
                    color: Colors.deepPurple,
                    title: '${dpp.title} (DPP)',
                    url: dpp.dppPdfUrl,
                    fileName: '${dpp.id}_dpp.pdf',
                  ),
                  if (dpp.solutionPdfUrl.isNotEmpty)
                    _buildLinkedDocRow(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      title: '${dpp.title} (Solution)',
                      url: dpp.solutionPdfUrl,
                      fileName: '${dpp.id}_solution.pdf',
                    ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildLinkedDocRow({
    required IconData icon,
    required Color color,
    required String title,
    String? url,
    String? fileName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (url != null && fileName != null)
            _DownloadActionButton(
              url: url,
              fileName: fileName,
              title: title,
              type: 'pdf',
            ),
          if (url != null)
            IconButton(
              icon: Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade600),
              tooltip: 'Open',
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            )
          else
            Icon(Icons.open_in_new, size: 15, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildNoteTile(StudyNote note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black12,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description, color: Colors.orange, size: 22),
          ),
          title: Text(
            note.title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade900),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.fileUrl != null)
                _DownloadActionButton(
                  url: note.fileUrl!,
                  fileName: '${note.id}_note.pdf',
                  title: note.title,
                  type: 'pdf',
                ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                tooltip: 'Open',
                onPressed: () async {
                  if (note.fileUrl != null) {
                    final uri = Uri.parse(note.fileUrl!);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDppTile(StudyDpp dpp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black12,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment, color: Colors.deepPurple, size: 22),
          ),
          title: Text(
            dpp.title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade900),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DownloadActionButton(
                url: dpp.dppPdfUrl,
                fileName: '${dpp.id}_dpp.pdf',
                title: '${dpp.title} (DPP)',
                type: 'pdf',
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.orange, size: 20),
                tooltip: 'Open DPP',
                onPressed: () async {
                  final uri = Uri.parse(dpp.dppPdfUrl);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
              if (dpp.solutionPdfUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                _DownloadActionButton(
                  url: dpp.solutionPdfUrl,
                  fileName: '${dpp.id}_solution.pdf',
                  title: '${dpp.title} (Solution)',
                  type: 'pdf',
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  tooltip: 'Open Solution',
                  onPressed: () async {
                    final uri = Uri.parse(dpp.solutionPdfUrl);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadActionButton extends StatefulWidget {
  final String url;
  final String fileName;
  final String title;
  final String type;

  const _DownloadActionButton({
    required this.url,
    required this.fileName,
    required this.title,
    required this.type,
  });

  @override
  State<_DownloadActionButton> createState() => _DownloadActionButtonState();
}

class _DownloadActionButtonState extends State<_DownloadActionButton> {
  final _downloadService = DownloadService();
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    if (widget.url.isEmpty) return;
    _localPath = await _downloadService.getLocalPath(widget.url);
    if (mounted) setState(() {});
  }

  Future<void> _download() async {
    if (widget.url.isEmpty) return;
    
    // For web, gracefully fallback to opening the URL which triggers browser download behavior
    if (kIsWeb) {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      return;
    }
    
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    final path = await _downloadService.downloadFile(
      url: widget.url,
      fileName: widget.fileName,
      title: widget.title,
      type: widget.type,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        if (path != null) _localPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(value: _progress, strokeWidth: 2),
        ),
      );
    }
    
    if (_localPath != null && !kIsWeb) {
      return IconButton(
        icon: const Icon(Icons.offline_pin, color: Colors.green, size: 20),
        tooltip: 'Downloaded',
        onPressed: () => _downloadService.openFile(_localPath!),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download_rounded, color: Colors.blue, size: 20),
      tooltip: 'Download',
      onPressed: _download,
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
