import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/lecture_player_screen.dart';
import 'package:eduverse/study/presentation/screens/study_quiz_screen.dart';
import 'package:eduverse/study/screens/subject_detail_screen.dart';
import 'package:eduverse/common/services/download_service.dart';
import 'package:eduverse/core/firebase/bookmark_service.dart';
import 'package:eduverse/core/firebase/live_viewer_service.dart';
import 'package:eduverse/core/utils/youtube_utils.dart';
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
  bool _isBookmarked = false; // Bookmark state
  final BookmarkService _bookmarkService = BookmarkService();
  final LiveViewerService _liveViewerService = LiveViewerService();

  // Live classes data
  List<StudyLiveClass> _liveClasses = [];
  bool _isLoadingLiveClasses = true;

  // Stats data
  int _totalLectures = 0;
  int _watchedLectures = 0;
  int _quizCount = 0;
  double _avgQuizScore = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _loadLiveClasses();
    _loadStats();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadLiveClasses() async {
    try {
      final controller = Provider.of<StudyController>(context, listen: false);
      final classes = await controller.repository.getBatchLiveClasses(
        widget.batch.courseId,
        widget.batch.id,
      );
      if (mounted) {
        setState(() {
          _liveClasses = classes;
          _isLoadingLiveClasses = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading live classes: $e');
      if (mounted) setState(() => _isLoadingLiveClasses = false);
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final status = await _bookmarkService.isBookmarked(widget.batch.id);
    if (mounted) setState(() => _isBookmarked = status);
  }

  Future<void> _loadStats() async {
    try {
      final controller = Provider.of<StudyController>(context, listen: false);

      // Fetch lectures to get total and watched count
      final lectures = await controller.getLectures(
        widget.batch.courseId,
        widget.batch.id,
      );
      final watched = lectures.where((l) => l.isWatched).length;

      // Fetch quizzes
      final quizzes = await controller.getBatchQuizzes(
        widget.batch.courseId,
        widget.batch.id,
      );

      // Calculate average quiz score from user's quiz results collection
      // Note: For now we calculate from local quiz data, as full quiz results tracking
      // would need additional repository method
      double avgScore = 0.0;
      // Placeholder: In a full implementation, you'd fetch user's quiz scores from Firestore
      // For example: users/{userId}/quizResults where each doc has the quiz score

      if (mounted) {
        setState(() {
          _totalLectures = lectures.length;
          _watchedLectures = watched;
          _quizCount = quizzes.length;
          _avgQuizScore = avgScore;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
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
            title: Text(
              widget.batch.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          SliverToBoxAdapter(child: _buildHeader()),
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
                  Tab(text: 'Quizzes'),
                  Tab(text: 'Planner'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSubjectsTab(),
            _buildQuizzesTab(),
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
                color:
                    (widget.batch.gradientColors.isNotEmpty
                            ? widget.batch.gradientColors.first
                            : Colors.blue)
                        .withValues(alpha: 0.4),
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
                        errorBuilder: (context, error, stackTrace) =>
                            _buildGradientBackground(),
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
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
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
                        },
                      );

                      final result = await _bookmarkService.toggleBookmark(
                        bookmark,
                      );

                      // Sync state
                      if (mounted && result != _isBookmarked) {
                        setState(() => _isBookmarked = result);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result ? 'Batch bookmarked' : 'Bookmark removed',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted)
                        setState(() => _isBookmarked = !_isBookmarked);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
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
                        text:
                            'Check out ${widget.batch.name} - ${widget.batch.courseName} on EduVerse!',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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

        // Info Cards Section (Show Instructor/Schedule only if live classes exist)
        if (_isLoadingLiveClasses)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (isWideScreen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_liveClasses.isNotEmpty) ...[
                  Expanded(child: _buildInstructorCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildScheduleCard()),
                  const SizedBox(width: 12),
                ],
                Expanded(child: _buildProgressSummaryCard()),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (_liveClasses.isNotEmpty) ...[
                  _buildInstructorCard(),
                  const SizedBox(height: 12),
                  _buildScheduleCard(),
                  const SizedBox(height: 12),
                ],
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

      final notes = await controller.getBatchNotes(
        widget.batch.courseId,
        widget.batch.id,
      );
      final plannerItems = await controller.getBatchPlanner(
        widget.batch.courseId,
        widget.batch.id,
      );

      // Filter items with downloadable URLs
      final downloadableNotes = notes
          .where((n) => n.fileUrl != null && n.fileUrl!.isNotEmpty)
          .toList();
      final downloadablePlanner = plannerItems
          .where((p) => p.fileUrl != null && p.fileUrl!.isNotEmpty)
          .toList();

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

        final fileName =
            '${note.id}_${note.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-]'), '')}.pdf';
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

        final fileName =
            '${item.id}_${item.title.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-]'), '')}.pdf';
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
            : Text(widget.batch.emoji, style: const TextStyle(fontSize: 64)),
      ),
    );
  }

  Widget _buildInstructorCard() {
    // Get unique instructor names from live classes
    final instructorNames = _liveClasses
        .map((lc) => lc.instructorName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    final instructorName = instructorNames.isNotEmpty
        ? instructorNames.first
        : 'Instructor';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instructor',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                  radius: 24,
                  child: Text(
                    instructorName.isNotEmpty
                        ? instructorName[0].toUpperCase()
                        : 'I',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_liveClasses.length} live class${_liveClasses.length > 1 ? 'es' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    // Sort live classes: upcoming first, then by date
    // Filter out completed classes
    final upcomingClasses =
        _liveClasses
            .where(
              (lc) =>
                  !lc.isCompleted &&
                  (lc.status == 'upcoming' ||
                      lc.status == 'live' ||
                      lc.startTime.isAfter(DateTime.now())),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final nextClass = upcomingClasses.isNotEmpty ? upcomingClasses.first : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Classes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (nextClass == null)
              Text(
                'No upcoming classes',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildScheduleItemFromClass(
                  nextClass.title,
                  '${nextClass.startTime.day}/${nextClass.startTime.month} ${nextClass.startTime.hour}:${nextClass.startTime.minute.toString().padLeft(2, '0')}',
                  true,
                ),
              ),
            if (nextClass != null) ...[
              // Live viewer count badge - only when class is live
              if (YouTubeUtils.shouldTreatAsLive(
                url: nextClass.youtubeUrl ?? '',
                status: nextClass.status,
                startTime: nextClass.startTime,
                durationMinutes: nextClass.durationMinutes,
              )) ...[
                StreamBuilder<int>(
                  stream: _liveViewerService.viewerCountStream(
                    widget.batch.courseId,
                    widget.batch.id,
                    nextClass.id,
                  ),
                  builder: (context, snapshot) {
                    final viewerCount = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$viewerCount watching',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (nextClass.youtubeUrl != null &&
                        nextClass.youtubeUrl!.isNotEmpty) {
                      // Navigate to player
                      final lecture = StudyLecture(
                        id: nextClass.id,
                        title: nextClass.title,
                        videoUrl: nextClass.youtubeUrl!,
                        description: nextClass.description,
                        order: 0,
                        duration: Duration(minutes: nextClass.durationMinutes),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LecturePlayerScreen(
                            courseId: widget.batch.courseId,
                            batchId: widget.batch.id,
                            lecture: lecture,
                            isLiveStream: YouTubeUtils.shouldTreatAsLive(
                              url: nextClass.youtubeUrl ?? '',
                              status: nextClass.status,
                              startTime: nextClass.startTime,
                              durationMinutes: nextClass.durationMinutes,
                            ),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Class link not available yet'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text(
                    YouTubeUtils.shouldTreatAsLive(
                      url: nextClass.youtubeUrl ?? '',
                      status: nextClass.status,
                      startTime: nextClass.startTime,
                      durationMinutes: nextClass.durationMinutes,
                    ) ? 'Join Now' : 'Join Live Class',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YouTubeUtils.shouldTreatAsLive(
                      url: nextClass.youtubeUrl ?? '',
                      status: nextClass.status,
                      startTime: nextClass.startTime,
                      durationMinutes: nextClass.durationMinutes,
                    )
                        ? Colors.red
                        : Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItemFromClass(String title, String time, bool isNext) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: isNext ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
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
            child: const Text(
              'NEXT',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildScheduleItem(String days, String time, bool isNext) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: isNext ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                days,
                style: TextStyle(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
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
            child: const Text(
              'NEXT',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            const Text(
              'Your Stats',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _isLoadingStats
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '$_watchedLectures/$_totalLectures',
                        'Lessons',
                      ),
                      _buildStatItem('$_quizCount', 'Quizzes'),
                      _buildStatItem(
                        _avgQuizScore > 0
                            ? '${_avgQuizScore.toStringAsFixed(0)}%'
                            : '--',
                        'Avg Score',
                      ),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            controller.getLectures(widget.batch.courseId, widget.batch.id),
            controller.getBatchNotes(widget.batch.courseId, widget.batch.id),
            controller.repository.getBatchDpps(widget.batch.courseId, widget.batch.id),
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
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: SubjectDetailScreen(
                            courseId: widget.batch.courseId,
                            batchId: widget.batch.id,
                            subject: subject,
                          ),
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

  Widget _buildQuizzesTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyQuiz>>(
          future: controller.getBatchQuizzes(
            widget.batch.courseId,
            widget.batch.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
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
                      'No quizzes available.',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.quiz, color: Colors.white),
                    ),
                    title: Text(
                      quiz.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${quiz.questionCount} Questions • ${quiz.durationMinutes} mins',
                    ),
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
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
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

  Widget _buildPlannerTab() {
    return Consumer<StudyController>(
      builder: (context, controller, child) {
        return FutureBuilder<List<StudyPlannerItem>>(
          future: controller.getBatchPlanner(
            widget.batch.courseId,
            widget.batch.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
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
                      'No planner items available.',
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
                return _PlannerCard(item: item);
              },
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
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
  final _isViewing = ValueNotifier<bool>(false);
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

    final fileName =
        '${widget.note.id}_${widget.note.title.replaceAll(' ', '_')}.pdf';
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
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Added ${widget.note.createdAt.day}/${widget.note.createdAt.month}/${widget.note.createdAt.year}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
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
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                    ),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.note.fileUrl != null)
                  ValueListenableBuilder<bool>(
                    valueListenable: _isViewing,
                    builder: (context, isViewing, _) => TextButton.icon(
                      onPressed: isViewing ? null : () async {
                        if (kIsWeb) {
                          final uri = Uri.parse(widget.note.fileUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                          return;
                        }
                        // On mobile: download to temp cache and open in PDF app
                        _isViewing.value = true;
                        try {
                          final dir = await getTemporaryDirectory();
                          final fileName = '${widget.note.id}_${widget.note.title.replaceAll(' ', '_')}.pdf';
                          final filePath = '${dir.path}/$fileName';
                          // Download to temp
                          await Dio().download(widget.note.fileUrl!, filePath);
                          // Open with PDF app
                          await OpenFilex.open(filePath);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open PDF: $e')),
                            );
                          }
                        } finally {
                          _isViewing.value = false;
                        }
                      },
                      icon: isViewing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.visibility, size: 18),
                      label: Text(isViewing ? 'Opening...' : 'View'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ),
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

    final fileName =
        '${widget.item.id}_${widget.item.title.replaceAll(' ', '_')}.pdf';
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
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.item.description != null &&
                          widget.item.description!.isNotEmpty)
                        Text(
                          widget.item.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      if (widget.item.dueDate != null)
                        Text(
                          'Date: ${_formatDate(widget.item.dueDate!)}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                    ),
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
// ignore: unused_element
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
