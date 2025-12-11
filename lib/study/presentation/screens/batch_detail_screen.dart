import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_screen.dart';
import 'package:eduverse/common/services/download_service.dart';
import 'package:eduverse/core/firebase/bookmark_service.dart';
import 'package:eduverse/profile/models/bookmark_model.dart';

class BatchDetailScreen extends StatefulWidget {
  final StudyBatch batch;

  const BatchDetailScreen({super.key, required this.batch});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0; // Used to force FutureBuilder refresh
  bool _isBookmarked = false; // Bookmark state
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await _bookmarkService.isBookmarked(widget.batch.id);
    if (mounted) setState(() => _isBookmarked = status);
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
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    
    return Column(
      children: [
        // Header / Banner
        Container(
          width: double.infinity,
          height: 180,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (widget.batch.gradientColors.isNotEmpty ? widget.batch.gradientColors.first : Colors.blue).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background: Thumbnail or Gradient
                widget.batch.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        widget.batch.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildGradientBackground(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildGradientBackground(showLoader: true);
                        },
                      )
                    : _buildGradientBackground(),
                // Overlay gradient for text readability
                if (widget.batch.thumbnailUrl.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                // Course name at bottom
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
                ),
              ],
            ),
          ),
        ),
        
        // Quick Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Bookmark',
                  onTap: () async {
                    // Optimistic update
                    setState(() => _isBookmarked = !_isBookmarked);
                    
                    try {
                      final bookmark = BookmarkItem(
                        id: widget.batch.id,
                        title: widget.batch.name,
                        type: BookmarkType.batch,
                        dateAdded: DateTime.now(),
                        metadata: {
                           'courseId': widget.batch.courseId,
                           'batchName': widget.batch.courseName,
                           'thumbnailUrl': widget.batch.thumbnailUrl,
                        }
                      );
                      
                      final result = await _bookmarkService.toggleBookmark(bookmark);
                      
                      // Sync state
                      if (mounted && result != _isBookmarked) {
                        setState(() => _isBookmarked = result);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result ? 'Batch bookmarked' : 'Bookmark removed'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.download_rounded,
                  label: 'Download All',
                  onTap: _handleDownloadAll,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Check out ${widget.batch.name} - ${widget.batch.courseName} on EduVerse!',
                        subject: widget.batch.name,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
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
                  color: Colors.green.withValues(alpha: 0.1),
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
        
        // Info Cards Section (Instructor, Schedule, Progress Summary)
        if (isWideScreen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInstructorCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildScheduleCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildProgressSummaryCard()),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInstructorCard(),
                const SizedBox(height: 12),
                _buildScheduleCard(),
                const SizedBox(height: 12),
                _buildProgressSummaryCard(),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _handleDownloadAll() async {
    final controller = Provider.of<StudyController>(context, listen: false);
    final downloadService = DownloadService();
    
    // Show enhanced progress dialog
    final progressNotifier = ValueNotifier<double>(0.0);
    final statusNotifier = ValueNotifier<String>('Fetching resources...');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DownloadAllProgressDialog(
        progressNotifier: progressNotifier,
        statusNotifier: statusNotifier,
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );

    try {
      // Fetch notes and planner items
      statusNotifier.value = 'Loading notes and planner items...';
      
      final notes = await controller.getBatchNotes(widget.batch.courseId, widget.batch.id);
      final plannerItems = await controller.getBatchPlanner(widget.batch.courseId, widget.batch.id);
      
      // Filter items with downloadable URLs
      final downloadableNotes = notes.where((n) => n.fileUrl != null && n.fileUrl!.isNotEmpty).toList();
      final downloadablePlanner = plannerItems.where((p) => p.fileUrl != null && p.fileUrl!.isNotEmpty).toList();
      
      final totalItems = downloadableNotes.length + downloadablePlanner.length;
      
      if (totalItems == 0) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No downloadable files found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      int downloadedCount = 0;
      int failedCount = 0;
      
      // Download notes
      for (final note in downloadableNotes) {
        statusNotifier.value = 'Downloading: ${note.title}';
        
        // Check if already downloaded
        final existingPath = await downloadService.getLocalPath(note.fileUrl!);
        if (existingPath != null) {
          downloadedCount++;
          progressNotifier.value = downloadedCount / totalItems;
          continue;
        }
        
        final fileName = '${note.id}_${note.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-]'), '')}.pdf';
        final result = await downloadService.downloadFile(
          url: note.fileUrl!,
          fileName: fileName,
          title: note.title,
          type: 'pdf',
          onProgress: (p) {
            // Sub-progress within current item
            progressNotifier.value = (downloadedCount + p) / totalItems;
          },
        );
        
        if (result != null) {
          downloadedCount++;
        } else {
          failedCount++;
        }
        progressNotifier.value = downloadedCount / totalItems;
      }
      
      // Download planner items
      for (final item in downloadablePlanner) {
        statusNotifier.value = 'Downloading: ${item.title}';
        
        // Check if already downloaded
        final existingPath = await downloadService.getLocalPath(item.fileUrl!);
        if (existingPath != null) {
          downloadedCount++;
          progressNotifier.value = downloadedCount / totalItems;
          continue;
        }
        
        final fileName = '${item.id}_${item.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-]'), '')}.pdf';
        final result = await downloadService.downloadFile(
          url: item.fileUrl!,
          fileName: fileName,
          title: item.title,
          type: 'pdf',
          onProgress: (p) {
            progressNotifier.value = (downloadedCount + p) / totalItems;
          },
        );
        
        if (result != null) {
          downloadedCount++;
        } else {
          failedCount++;
        }
        progressNotifier.value = downloadedCount / totalItems;
      }
      
      if (mounted) {
        Navigator.pop(context);
        
        final successCount = downloadedCount;
        String message;
        Color bgColor;
        
        if (failedCount == 0) {
          message = '$successCount files downloaded successfully!';
          bgColor = Colors.green;
        } else if (successCount > 0) {
          message = '$successCount downloaded, $failedCount failed';
          bgColor = Colors.orange;
        } else {
          message = 'Download failed';
          bgColor = Colors.red;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: bgColor),
        );
      }
    } catch (e) {
      debugPrint('Download all error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGradientBackground({bool showLoader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.batch.gradientColors.isNotEmpty
              ? widget.batch.gradientColors
              : [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: showLoader
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              )
            : Text(
                widget.batch.emoji,
                style: const TextStyle(fontSize: 64),
              ),
      ),
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
            const Text('Instructor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Expert educator with 10+ years of experience.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildScheduleItem('Mon, Wed, Fri', '10:00 AM - 11:30 AM', true),
            const Divider(height: 16),
            _buildScheduleItem('Saturday', '02:00 PM - 04:00 PM', false),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joining live class...')),
                  );
                },
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join Live Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String days, String time, bool isNext) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: isNext ? Colors.blue : Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(days, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        if (isNext)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('NEXT', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
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
            const Text('Your Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('${widget.batch.completedLectures}/${widget.batch.totalLectures}', 'Lessons'),
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
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          debugPrint('Opening lecture: ${lecture.title}, videoUrl: ${lecture.videoUrl}');
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
          if (mounted) setState(() => _refreshKey++);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: lecture.isWatched ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
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

/// Quick Action Button widget for Bookmark, Download All, Share actions
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey[700], size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Download Progress Dialog for "Download All" action
class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Downloading resources...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we prepare your offline content.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Download All Progress Dialog with real-time updates
class _DownloadAllProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progressNotifier;
  final ValueNotifier<String> statusNotifier;
  final VoidCallback onCancel;

  const _DownloadAllProgressDialog({
    required this.progressNotifier,
    required this.statusNotifier,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated progress indicator
            ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Downloading Resources',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: statusNotifier,
              builder: (context, status, _) {
                return Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            const SizedBox(height: 16),
            // Linear progress bar
            ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
