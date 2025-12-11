import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import '../widgets/batch_header.dart';
import '../widgets/batch_lesson_tile.dart';
import 'lecture_player_page.dart';

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

  // Mock Data
  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Module 1: Foundations',
      'lessons': [
        {'id': 'l1', 'title': 'Introduction to the Course', 'duration': '10m', 'type': 'video', 'locked': false, 'videoUrl': 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'},
        {'id': 'l2', 'title': 'Basic Concepts Overview', 'duration': '25m', 'type': 'article', 'locked': false},
        {'id': 'l3', 'title': 'Historical Context', 'duration': '40m', 'type': 'video', 'locked': false},
        {'id': 'l4', 'title': 'Module 1 Quiz', 'duration': '15m', 'type': 'quiz', 'locked': true},
      ]
    },
    {
      'title': 'Module 2: Core Concepts',
      'lessons': [
        {'id': 'l5', 'title': 'Deep Dive: Part 1', 'duration': '35m', 'type': 'video', 'locked': true},
        {'id': 'l6', 'title': 'Deep Dive: Part 2', 'duration': '30m', 'type': 'video', 'locked': true},
        {'id': 'l7', 'title': 'Case Studies', 'duration': '20m', 'type': 'article', 'locked': true},
        {'id': 'l8', 'title': 'Module 2 Quiz', 'duration': '20m', 'type': 'quiz', 'locked': true},
      ]
    },
    {
      'title': 'Module 3: Advanced Application',
      'lessons': [
        {'id': 'l9', 'title': 'Advanced Techniques', 'duration': '45m', 'type': 'video', 'locked': true},
        {'id': 'l10', 'title': 'Real-world Examples', 'duration': '30m', 'type': 'video', 'locked': true},
        {'id': 'l11', 'title': 'Final Project Guidelines', 'duration': '15m', 'type': 'article', 'locked': true},
        {'id': 'l12', 'title': 'Final Assessment', 'duration': '60m', 'type': 'quiz', 'locked': true},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing batch link...')),
    );
  }

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

  void _handleLessonAction(String action, Map<String, dynamic> lesson) {
    switch (action) {
      case 'complete':
        setState(() {
          _lessonCompletion[lesson['id']] = true;
          _lessonProgress[lesson['id']] = 1.0;
        });
        break;
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${lesson['title']}...')),
        );
        break;
      case 'note':
        _showNoteDialog(lesson['id']);
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported')),
        );
        break;
    }
  }

  void _showNoteDialog(String lessonId) {
    final TextEditingController noteController =
        TextEditingController(text: _notes[lessonId]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: noteController,
          maxLength: 250,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your note here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (noteController.text.isEmpty) {
                  _notes.remove(lessonId);
                } else {
                  _notes[lessonId] = noteController.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLessons() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock refresh logic
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

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
                    Tab(text: 'Lessons'),
                    Tab(text: 'Notes'),
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
              _buildLessonsTab(isWideScreen),
              _buildNotesTab(),
              _buildPlannerTab(),
              _buildQuizzesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsTab(bool isWideScreen) {
    final content = RefreshIndicator(
      onRefresh: _refreshLessons,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isWideScreen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildModulesList()),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildSidePanel()),
              ],
            )
          else ...[
            _buildInstructorCard(),
            const SizedBox(height: 16),
            _buildTimetableCard(),
            const SizedBox(height: 16),
            _buildProgressSummaryCard(),
            const SizedBox(height: 24),
            _buildModulesList(),
          ],
        ],
      ),
    );
    return content;
  }

  Widget _buildModulesList() {
    return Column(
      children: _modules.asMap().entries.map((entry) {
        final moduleIndex = entry.key;
        final module = entry.value;
        final lessons = module['lessons'] as List<Map<String, dynamic>>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                module['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...lessons.asMap().entries.map((lessonEntry) {
              final lessonIndex = lessonEntry.key + 1;
              final lesson = lessonEntry.value;
              final lessonId = lesson['id'];
              final isCompleted = _lessonCompletion[lessonId] ?? false;
              final progress = isCompleted ? 1.0 : (_lessonProgress[lessonId] ?? 0.0);

              return BatchLessonTile(
                index: (moduleIndex * 4) + lessonIndex, // Continuous index mock
                title: lesson['title'],
                duration: lesson['duration'],
                type: lesson['type'],
                isLocked: lesson['locked'],
                progress: progress,
                hasNote: _notes.containsKey(lessonId),
                onTap: () => _openLessonDetail(lesson),
                onAction: (action) => _handleLessonAction(action, lesson),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSidePanel() {
    return Column(
      children: [
        _buildInstructorCard(),
        const SizedBox(height: 16),
        _buildTimetableCard(),
        const SizedBox(height: 16),
        _buildProgressSummaryCard(),
      ],
    );
  }

  Widget _buildInstructorCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Instructor', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'), // Mock image
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dr. Anjali Sharma', style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: const [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(' 4.8', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Expert in Polity and Governance with 10+ years of teaching experience.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<StudyController>(
          builder: (context, controller, child) {
            return FutureBuilder<List<StudyLiveClass>>(
              future: controller.getBatchLiveClasses(widget.course.id, widget.batchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error loading schedule');
                }

                final liveClasses = snapshot.data ?? [];
                final upcomingClasses = liveClasses.where((c) => c.isUpcoming).toList();
                final liveClass = liveClasses.firstWhere((c) => c.isLive, orElse: () => liveClasses.first);

                if (liveClasses.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text('No live classes scheduled yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (upcomingClasses.length > 2)
                          TextButton(onPressed: () {}, child: const Text('View All')),
                      ],
                    ),
                    ...upcomingClasses.take(2).map((c) => Column(
                      children: [
                        _buildScheduleItem(c),
                        if (upcomingClasses.indexOf(c) < upcomingClasses.length - 1) const Divider(),
                      ],
                    )),
                    const SizedBox(height: 12),
                    if (liveClass.isLive || (upcomingClasses.isNotEmpty && upcomingClasses.first.startTime.difference(DateTime.now()).inHours < 1))
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: liveClass.youtubeUrl != null ? () {
                            // TODO: Open YouTube link
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Join Live Class', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleItem(StudyLiveClass liveClass) {
    final isNext = liveClass.isUpcoming && liveClass.startTime.difference(DateTime.now()).inHours < 24;
    final timeStr = '${liveClass.startTime.hour.toString().padLeft(2, '0')}:${liveClass.startTime.minute.toString().padLeft(2, '0')}';
    final dateStr = '${liveClass.startTime.day}/${liveClass.startTime.month}';
    
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: isNext ? Colors.blue : Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(liveClass.title, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
            Text('$dateStr • $timeStr - ${liveClass.durationMinutes} min', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        if (isNext) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('NEXT', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Progress', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('12/40', 'Lessons'),
                _buildStatItem('5', 'Quizzes'),
                _buildStatItem('85%', 'Avg Score'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
                    Text('No notes available yet.', style: TextStyle(color: Colors.grey)),
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
                    onPressed: () {
                      if (note.fileUrl != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${note.title}...')),
                        );
                        // TODO: Open PDF using url_launcher
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
                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No planner items available yet.', style: TextStyle(color: Colors.grey)),
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
                        if (item.description != null && item.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        if (item.dueDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Due: ${_formatDate(item.dueDate!)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    trailing: item.fileUrl != null
                        ? IconButton(
                            icon: const Icon(Icons.attachment),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening attachment for ${item.title}...')),
                              );
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
                    Text('No quizzes available yet.', style: TextStyle(color: Colors.grey)),
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
                    subtitle: Text('${quiz.questionCount} Questions • ${quiz.durationMinutes} mins'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to Quiz Taking Screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Starting quiz... (Implementation pending)')),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
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
            Text('Downloading resources...', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Please wait while we prepare your offline content.', textAlign: TextAlign.center),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${lesson['duration']} • ${lesson['type'].toString().toUpperCase()}'),
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
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Your Note', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
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
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (lesson['type'] == 'video' && lesson['videoUrl'] != null) {
                         Navigator.pop(context); // Close sheet
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => LecturePlayerPage(
                               videoUrl: lesson['videoUrl'],
                               title: lesson['title'],
                               description: 'This is a detailed description of the lesson...',
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
