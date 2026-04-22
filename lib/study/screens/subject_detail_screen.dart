import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'chapter_detail_screen.dart';

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
  List<_ChapterInfo> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final controller = context.read<StudyController>();
    try {
      final results = await Future.wait([
        controller.getLectures(widget.courseId, widget.batchId),
        controller.getBatchNotes(widget.courseId, widget.batchId),
        controller.repository.getBatchDpps(widget.courseId, widget.batchId),
      ]);

      final lectures = (results[0] as List<StudyLecture>)
          .where((l) => l.subject == widget.subject);
      final notes = (results[1] as List<StudyNote>)
          .where((n) => n.subject == widget.subject);
      final dpps = (results[2] as List<StudyDpp>)
          .where((d) => d.subject == widget.subject);

      // Aggregate unique chapters
      final chapterSet = <String>{};
      for (final l in lectures) {
        if (l.chapter.isNotEmpty) chapterSet.add(l.chapter);
      }
      for (final n in notes) {
        if (n.chapter.isNotEmpty) chapterSet.add(n.chapter);
      }
      for (final d in dpps) {
        if (d.chapter.isNotEmpty) chapterSet.add(d.chapter);
      }

      final chapterList = chapterSet.toList()..sort();

      // Build chapter info with counts
      final chapters = chapterList.map((ch) {
        final lectureCount = lectures.where((l) => l.chapter == ch).length;
        final noteCount = notes.where((n) => n.chapter == ch).length;
        final dppCount = dpps.where((d) => d.chapter == ch).length;
        return _ChapterInfo(
          name: ch,
          lectureCount: lectureCount,
          noteCount: noteCount,
          dppCount: dppCount,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chapters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No chapters found for this subject.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChapters,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chapters.length + 1, // +1 for header
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Header
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor.withValues(alpha: 0.12), primaryColor.withValues(alpha: 0.04)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.subject, color: primaryColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.subject,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_chapters.length} chapter${_chapters.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: primaryColor.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final chapter = _chapters[index - 1];
                      return _ChapterCard(
                        chapter: chapter,
                        index: index,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: context.read<StudyController>(),
                                child: ChapterDetailScreen(
                                  courseId: widget.courseId,
                                  batchId: widget.batchId,
                                  subject: widget.subject,
                                  chapter: chapter.name,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _ChapterInfo {
  final String name;
  final int lectureCount;
  final int noteCount;
  final int dppCount;

  _ChapterInfo({
    required this.name,
    required this.lectureCount,
    required this.noteCount,
    required this.dppCount,
  });

  int get totalItems => lectureCount + noteCount + dppCount;
}

class _ChapterCard extends StatelessWidget {
  final _ChapterInfo chapter;
  final int index;
  final VoidCallback onTap;

  const _ChapterCard({
    required this.chapter,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1.5,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Chapter number
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade300,
                        Colors.indigo.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (chapter.lectureCount > 0)
                            _MiniChip(
                              icon: Icons.play_circle_fill,
                              label: '${chapter.lectureCount}',
                              color: Colors.blue,
                            ),
                          if (chapter.noteCount > 0)
                            _MiniChip(
                              icon: Icons.description,
                              label: '${chapter.noteCount}',
                              color: Colors.orange,
                            ),
                          if (chapter.dppCount > 0)
                            _MiniChip(
                              icon: Icons.assignment,
                              label: '${chapter.dppCount}',
                              color: Colors.deepPurple,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
