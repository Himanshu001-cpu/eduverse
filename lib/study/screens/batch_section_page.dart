import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_screen.dart';
import '../widgets/batch_header.dart';
import 'lecture_player_page.dart';
import 'subject_detail_screen.dart';

class BatchSectionPage extends StatefulWidget {
  final StudyCourseModel course;
  final String batchId;

  const BatchSectionPage({
    super.key,
    required this.course,
    required this.batchId,
  });

  @override
  State<BatchSectionPage> createState() => _BatchSectionPageState();
}

class _BatchSectionPageState extends State<BatchSectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, String> _notes = {}; // In-memory notes storage
  final Set<String> _offlineItems = {}; // In-memory offline items
  final Map<String, double> _lessonProgress = {}; // In-memory progress
  final Map<String, bool> _lessonCompletion = {}; // In-memory completion

  // Lessons are fetched from Firestore - no hardcoded data

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _handleDownloadAll() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DownloadProgressDialog(),
    );

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context); // Close dialog
      setState(() {
        _offlineItems.add('all'); // Mark all as offline
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All resources downloaded'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _offlineItems.clear();
              });
            },
          ),
        ),
      );
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing batch link...')));
  }

  // ignore: unused_element
  void _openLessonDetail(Map<String, dynamic> lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LessonDetailSheet(
        lesson: lesson,
        note: _notes[lesson['id']],
        onSaveNote: (note) {
          setState(() {
            if (note.isEmpty) {
              _notes.remove(lesson['id']);
            } else {
              _notes[lesson['id']] = note;
            }
          });
        },
        onComplete: () {
          setState(() {
            _lessonCompletion[lesson['id']] = true;
            _lessonProgress[lesson['id']] = 1.0;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: BatchHeader(
                course: widget.course,
                batchId: widget.batchId,
                onDownloadAll: _handleDownloadAll,
                onShare: _handleShare,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'Subjects'),
                    Tab(text: 'Notes'),
                    Tab(text: 'DPP'),
                    Tab(text: 'Planner'),
                    Tab(text: 'Quizzes'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSubjectsTab(),
              _buildNotesTab(),
              _buildDppTab(),
              _buildPlannerTab(),
              _buildQuizzesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            controller.getLectures(widget.course.id, widget.batchId),
            controller.getBatchNotes(widget.course.id, widget.batchId),
            controller.repository.getBatchDpps(widget.course.id, widget.batchId),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final lectures = snapshot.data![0] as List<StudyLecture>;
            final notes = snapshot.data![1] as List<StudyNote>;
            final dpps = snapshot.data![2] as List<StudyDpp>;

            // Aggregate unique subjects
            final subjectSet = <String>{};
            for (final l in lectures) {
              if (l.subject.isNotEmpty) subjectSet.add(l.subject);
            }
            for (final n in notes) {
              if (n.subject.isNotEmpty) subjectSet.add(n.subject);
            }
            for (final d in dpps) {
              if (d.subject.isNotEmpty) subjectSet.add(d.subject);
            }

            final subjects = subjectSet.toList()..sort();

            if (subjects.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.subject, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No subjects available yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Build subject info
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final lectureCount = lectures.where((l) => l.subject == subject).length;
                final noteCount = notes.where((n) => n.subject == subject).length;
                final dppCount = dpps.where((d) => d.subject == subject).length;

                // Count unique chapters
                final chapSet = <String>{};
                for (final l in lectures.where((l) => l.subject == subject)) {
                  if (l.chapter.isNotEmpty) chapSet.add(l.chapter);
                }
                for (final n in notes.where((n) => n.subject == subject)) {
                  if (n.chapter.isNotEmpty) chapSet.add(n.chapter);
                }
                for (final d in dpps.where((d) => d.subject == subject)) {
                  if (d.chapter.isNotEmpty) chapSet.add(d.chapter);
                }

                return _SubjectCard(
                  subject: subject,
                  chapterCount: chapSet.length,
                  lectureCount: lectureCount,
                  noteCount: noteCount,
                  dppCount: dppCount,
                  colorIndex: index,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailScreen(
                          courseId: widget.course.id,
                          batchId: widget.batchId,
                          subject: subject,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  Widget _buildNotesTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyNote>>(
          future: controller.getBatchNotes(widget.course.id, widget.batchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final notes = snapshot.data ?? [];

            if (notes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No notes available yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(note.title),
                  subtitle: Text('Added ${_formatDate(note.createdAt)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () async {
                      if (note.fileUrl != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${note.title}...')),
                        );
                        final url = Uri.parse(note.fileUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open PDF link'),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDppTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyDpp>>(
          future: controller.repository.getBatchDpps(widget.course.id, widget.batchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final dpps = snapshot.data ?? [];

            if (dpps.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No DPPs available yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dpps.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final dpp = dpps[index];
                final metaParts = <String>[];
                if (dpp.subject.isNotEmpty) metaParts.add(dpp.subject);
                if (dpp.chapter.isNotEmpty) metaParts.add(dpp.chapter);
                final metaLine = metaParts.isNotEmpty ? metaParts.join(' • ') : '';

                return ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.deepPurple),
                  title: Text(dpp.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (metaLine.isNotEmpty)
                        Text(
                          metaLine,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // DPP PDF button
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                        tooltip: 'Open DPP',
                        onPressed: () async {
                          final url = Uri.parse(dpp.dppPdfUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                      ),
                      // Solution PDF button
                      if (dpp.solutionPdfUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          tooltip: 'Open Solution',
                          onPressed: () async {
                            final url = Uri.parse(dpp.solutionPdfUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlannerTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyPlannerItem>>(
          future: controller.getBatchPlanner(widget.course.id, widget.batchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No planner items available yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.event, color: Colors.blue),
                    ),
                    title: Text(item.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (item.dueDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Due: ${_formatDate(item.dueDate!)}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: item.fileUrl != null
                        ? IconButton(
                            icon: const Icon(Icons.attachment),
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Opening attachment for ${item.title}...',
                                  ),
                                ),
                              );
                              final url = Uri.parse(item.fileUrl!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open attachment link',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildQuizzesTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyQuiz>>(
          future: controller.getBatchQuizzes(widget.course.id, widget.batchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final quizzes = snapshot.data ?? [];

            if (quizzes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No quizzes available yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.quiz, color: Colors.white),
                    ),
                    title: Text(quiz.title),
                    subtitle: Text(
                      '${quiz.questionCount} Questions • ${quiz.durationMinutes} mins',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudyQuizScreen(
                              courseId: widget.course.id,
                              batchId: widget.batchId,
                              quizId: quiz.id,
                              quizTitle: quiz.title,
                            ),
                          ),
                        );
                      },
                      child: const Text('Start'),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Downloading resources...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we prepare your offline content.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonDetailSheet extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final String? note;
  final Function(String) onSaveNote;
  final VoidCallback onComplete;

  const _LessonDetailSheet({
    required this.lesson,
    this.note,
    required this.onSaveNote,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lesson['title'],
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${lesson['duration']} • ${lesson['type'].toString().toUpperCase()}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a detailed description of the lesson. It covers all the key topics and provides a comprehensive overview of the subject matter. Students are expected to watch the video and read the accompanying materials.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (note != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Your Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(note!),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (lesson['type'] == 'video' &&
                          lesson['videoUrl'] != null) {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LecturePlayerPage(
                              videoUrl: lesson['videoUrl'],
                              title: lesson['title'],
                              description:
                                  'This is a detailed description of the lesson...',
                            ),
                          ),
                        );
                      } else {
                        onComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      lesson['type'] == 'video' ? 'Watch Now' : 'Mark Complete',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Subject card for the Subjects tab
class _SubjectCard extends StatelessWidget {
  final String subject;
  final int chapterCount;
  final int lectureCount;
  final int noteCount;
  final int dppCount;
  final int colorIndex;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.chapterCount,
    required this.lectureCount,
    required this.noteCount,
    required this.dppCount,
    required this.colorIndex,
    required this.onTap,
  });

  static const _gradients = [
    [Color(0xFF4A90E2), Color(0xFF357ABD)],
    [Color(0xFF7B61FF), Color(0xFF5B3FD4)],
    [Color(0xFFE94560), Color(0xFFC23152)],
    [Color(0xFF00B894), Color(0xFF009874)],
    [Color(0xFFF39C12), Color(0xFFD68910)],
    [Color(0xFF6C5CE7), Color(0xFF5341C4)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[colorIndex % _gradients.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Subject icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.subject, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$chapterCount chapter${chapterCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          if (lectureCount > 0)
                            _MiniTag(
                              icon: Icons.play_circle_fill,
                              label: '$lectureCount',
                              color: Colors.blue,
                            ),
                          if (noteCount > 0)
                            _MiniTag(
                              icon: Icons.description,
                              label: '$noteCount',
                              color: Colors.orange,
                            ),
                          if (dppCount > 0)
                            _MiniTag(
                              icon: Icons.assignment,
                              label: '$dppCount',
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

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniTag({required this.icon, required this.label, required this.color});

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
