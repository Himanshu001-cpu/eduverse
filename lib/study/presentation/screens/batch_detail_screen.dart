import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_screen.dart';
import 'package:eduverse/common/services/download_service.dart';

class BatchDetailScreen extends StatefulWidget {
  final StudyBatch batch;

  const BatchDetailScreen({Key? key, required this.batch}) : super(key: key);

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0; // Used to force FutureBuilder refresh

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            title: Text(widget.batch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: _buildHeader(),
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
                  Tab(text: 'Quizzes'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Planner'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLessonsTab(),
            _buildQuizzesTab(),
            _buildNotesTab(),
            _buildPlannerTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Header / Banner
        Container(
          width: double.infinity,
          height: 180,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: widget.batch.gradientColors.isNotEmpty
                  ? widget.batch.gradientColors
                  : [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.batch.gradientColors.isNotEmpty ? widget.batch.gradientColors.first : Colors.blue).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
               Center(
                 child: Text(
                   widget.batch.emoji,
                   style: const TextStyle(fontSize: 64),
                 ),
               ),
               Positioned(
                 bottom: 16,
                 left: 16,
                 right: 16,
                 child: Text(
                   widget.batch.courseName,
                   style: const TextStyle(
                     color: Colors.white,
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                   ),
                   textAlign: TextAlign.center,
                 ),
               )
            ],
          ),
        ),
        // Progress Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Progress",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(widget.batch.progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.batch.progress,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLessonsTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyLecture>>(
          key: ValueKey(_refreshKey), // Force rebuild when key changes
          future: controller.getLectures(widget.batch.courseId, widget.batch.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final lectures = snapshot.data ?? [];
            if (lectures.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No lectures available.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lectures.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lecture = lectures[index];
                return _buildLectureTile(lecture, controller);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLectureTile(StudyLecture lecture, StudyController controller) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: controller,
              child: LecturePlayerScreen(
                courseId: widget.batch.courseId,
                batchId: widget.batch.id,
                lecture: lecture,
              ),
            ),
          ),
        );
        // Increment key to force FutureBuilder to refetch
        setState(() => _refreshKey++);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: lecture.isWatched ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                lecture.isWatched ? Icons.check_circle : Icons.play_arrow_rounded,
                color: lecture.isWatched ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lecture.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("Lecture ${lecture.order}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyQuiz>>(
          future: controller.getBatchQuizzes(widget.batch.courseId, widget.batch.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final quizzes = snapshot.data ?? [];
            if (quizzes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No quizzes available.', style: TextStyle(color: Colors.grey)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.quiz, color: Colors.white),
                    ),
                    title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${quiz.questionCount} Questions • ${quiz.durationMinutes} mins'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudyQuizScreen(
                              courseId: widget.batch.courseId,
                              batchId: widget.batch.id,
                              quizId: quiz.id,
                              quizTitle: quiz.title,
                              themeColor: widget.batch.gradientColors.isNotEmpty 
                                  ? widget.batch.gradientColors.first 
                                  : Colors.purple,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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

  Widget _buildNotesTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyNote>>(
          future: controller.getBatchNotes(widget.batch.courseId, widget.batch.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final notes = snapshot.data ?? [];
            if (notes.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No notes available.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                return _NoteCard(note: note);
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
          future: controller.getBatchPlanner(widget.batch.courseId, widget.batch.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No planner items available.', style: TextStyle(color: Colors.grey)),
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
                return _PlannerCard(item: item);
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

/// Card widget for displaying notes with download/open functionality
class _NoteCard extends StatefulWidget {
  final StudyNote note;
  const _NoteCard({required this.note});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  final _downloadService = DownloadService();
  final _isDownloading = ValueNotifier<bool>(false);
  final _progress = ValueNotifier<double>(0.0);
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    if (widget.note.fileUrl != null) {
      _localPath = await _downloadService.getLocalPath(widget.note.fileUrl!);
      if (mounted) setState(() {});
    }
  }

  Future<void> _download() async {
    if (widget.note.fileUrl == null) return;
    _isDownloading.value = true;
    _progress.value = 0.0;

    final fileName = '${widget.note.id}_${widget.note.title.replaceAll(' ', '_')}.pdf';
    final path = await _downloadService.downloadFile(
      url: widget.note.fileUrl!,
      fileName: fileName,
      title: widget.note.title,
      type: 'pdf',
      onProgress: (p) => _progress.value = p,
    );

    _isDownloading.value = false;
    if (path != null) {
      _localPath = path;
      if (mounted) setState(() {});
    }
  }

  Future<void> _open() async {
    if (_localPath != null) {
      await _downloadService.openFile(_localPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.picture_as_pdf, color: Colors.deepOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Added ${widget.note.createdAt.day}/${widget.note.createdAt.month}/${widget.note.createdAt.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _isDownloading,
              builder: (context, isDownloading, _) {
                if (!isDownloading) return const SizedBox.shrink();
                return ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, progress, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(value: progress, minHeight: 4),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_localPath == null && widget.note.fileUrl != null)
                  ValueListenableBuilder<bool>(
                    valueListenable: _isDownloading,
                    builder: (context, isDownloading, _) => TextButton.icon(
                      onPressed: isDownloading ? null : _download,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                    ),
                  ),
                if (_localPath != null)
                  TextButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying planner items with download/open functionality
class _PlannerCard extends StatefulWidget {
  final StudyPlannerItem item;
  const _PlannerCard({required this.item});

  @override
  State<_PlannerCard> createState() => _PlannerCardState();
}

class _PlannerCardState extends State<_PlannerCard> {
  final _downloadService = DownloadService();
  final _isDownloading = ValueNotifier<bool>(false);
  final _progress = ValueNotifier<double>(0.0);
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    if (widget.item.fileUrl != null) {
      _localPath = await _downloadService.getLocalPath(widget.item.fileUrl!);
      if (mounted) setState(() {});
    }
  }

  Future<void> _download() async {
    if (widget.item.fileUrl == null) return;
    _isDownloading.value = true;
    _progress.value = 0.0;

    final fileName = '${widget.item.id}_${widget.item.title.replaceAll(' ', '_')}.pdf';
    final path = await _downloadService.downloadFile(
      url: widget.item.fileUrl!,
      fileName: fileName,
      title: widget.item.title,
      type: 'pdf',
      onProgress: (p) => _progress.value = p,
    );

    _isDownloading.value = false;
    if (path != null) {
      _localPath = path;
      if (mounted) setState(() {});
    }
  }

  Future<void> _open() async {
    if (_localPath != null) {
      await _downloadService.openFile(_localPath!);
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.event, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (widget.item.description != null && widget.item.description!.isNotEmpty)
                        Text(widget.item.description!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      if (widget.item.dueDate != null)
                        Text('Date: ${_formatDate(widget.item.dueDate!)}',
                            style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _isDownloading,
              builder: (context, isDownloading, _) {
                if (!isDownloading) return const SizedBox.shrink();
                return ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, progress, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(value: progress, minHeight: 4),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_localPath == null && widget.item.fileUrl != null)
                  ValueListenableBuilder<bool>(
                    valueListenable: _isDownloading,
                    builder: (context, isDownloading, _) => TextButton.icon(
                      onPressed: isDownloading ? null : _download,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                    ),
                  ),
                if (_localPath != null)
                  TextButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
