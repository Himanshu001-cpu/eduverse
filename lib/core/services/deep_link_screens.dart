import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/study/screens/batch_section_page.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/feed/screens/generic_feed_detail_router.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';

/// Screens that handle deep link navigation by loading data asynchronously.
/// These screens show a loading indicator while fetching the required data,
/// then navigate to the actual content screens.

/// Deep link screen for course detail pages.
/// Route: /app/course/{courseId}
class DeepLinkCourseScreen extends StatefulWidget {
  final String courseId;

  const DeepLinkCourseScreen({super.key, required this.courseId});

  @override
  State<DeepLinkCourseScreen> createState() => _DeepLinkCourseScreenState();
}

class _DeepLinkCourseScreenState extends State<DeepLinkCourseScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();

      if (!mounted) return;

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _error = 'Course not found';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      data['id'] = doc.id;

      // Fetch batches subcollection
      final batchesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('batches')
          .get();

      final batches = batchesSnapshot.docs.map((batchDoc) {
        final batchData = batchDoc.data();
        return Batch(
          id: batchDoc.id,
          name: batchData['name'] ?? '',
          startDate: batchData['startDate'] != null 
              ? (batchData['startDate'] as dynamic).toDate() 
              : DateTime.now(),
          realPrice: (batchData['realPrice'] as num?)?.toDouble() ?? (batchData['price'] as num?)?.toDouble() ?? 0.0,
          finalPrice: (batchData['finalPrice'] as num?)?.toDouble() ?? (batchData['price'] as num?)?.toDouble() ?? 0.0,
          seatsLeft: batchData['seatsLeft'] ?? 0,
          duration: batchData['duration'] ?? '',
          thumbnailUrl: batchData['thumbnailUrl'] ?? '',
          isEnrolled: false,
        );
      }).toList();

      final course = Course(
        id: doc.id,
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        description: data['description'] ?? '',
        emoji: data['emoji'] ?? '📚',
        thumbnailUrl: data['thumbnailUrl'] ?? '',
        gradientColors: _parseGradientColors(data['gradientColors']),
        priceDefault: (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
        batches: batches,
      );

      if (!mounted) return;

      // Replace current screen with the course detail page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailPage(course: course),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading course: $e';
        _isLoading = false;
      });
    }
  }

  List<Color> _parseGradientColors(dynamic data) {
    if (data == null) return [Colors.blue, Colors.blueAccent];
    if (data is List) {
      return data.map((c) {
        if (c is int) return Color(c);
        if (c is String) {
          return Color(int.tryParse(c.replaceFirst('#', '0xFF')) ?? 0xFF2196F3);
        }
        return Colors.blue;
      }).toList().cast<Color>();
    }
    return [Colors.blue, Colors.blueAccent];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading course...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deep link screen for batch section pages.
/// Route: /app/batch/{courseId}/{batchId}
class DeepLinkBatchScreen extends StatefulWidget {
  final String courseId;
  final String batchId;

  const DeepLinkBatchScreen({
    super.key,
    required this.courseId,
    required this.batchId,
  });

  @override
  State<DeepLinkBatchScreen> createState() => _DeepLinkBatchScreenState();
}

class _DeepLinkBatchScreenState extends State<DeepLinkBatchScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  Future<void> _loadBatch() async {
    try {
      // First load course data
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();

      if (!mounted) return;

      if (!courseDoc.exists || courseDoc.data() == null) {
        setState(() {
          _error = 'Course not found';
          _isLoading = false;
        });
        return;
      }

      final courseData = courseDoc.data()!;

      // Create StudyCourseModel for BatchSectionPage
      final studyCourse = StudyCourseModel(
        id: widget.courseId,
        title: courseData['title'] ?? '',
        subtitle: courseData['subtitle'] ?? '',
        emoji: courseData['emoji'] ?? '📚',
        gradientColors: _parseGradientColors(courseData['gradientColors']),
        lessonCount: 0,
        progress: 0.0,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider<StudyController>(
            create: (_) => StudyController(
              repository: StudyRepositoryImpl(),
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            child: BatchSectionPage(
              course: studyCourse,
              batchId: widget.batchId,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading batch: $e';
        _isLoading = false;
      });
    }
  }

  List<Color> _parseGradientColors(dynamic data) {
    if (data == null) return [Colors.blue, Colors.blueAccent];
    if (data is List) {
      return data.map((c) {
        if (c is int) return Color(c);
        if (c is String) {
          return Color(int.tryParse(c.replaceFirst('#', '0xFF')) ?? 0xFF2196F3);
        }
        return Colors.blue;
      }).toList().cast<Color>();
    }
    return [Colors.blue, Colors.blueAccent];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading batch...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deep link screen for feed item detail pages.
/// Route: /app/feed/{feedId}
class DeepLinkFeedScreen extends StatefulWidget {
  final String feedId;

  const DeepLinkFeedScreen({super.key, required this.feedId});

  @override
  State<DeepLinkFeedScreen> createState() => _DeepLinkFeedScreenState();
}

class _DeepLinkFeedScreenState extends State<DeepLinkFeedScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    debugPrint('DeepLinkFeedScreen: loading feedId=${widget.feedId}');
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final feedRepository = FeedRepository();
      
      // Add timeout to prevent infinite loading
      final feedItem = await feedRepository.getFeedItem(widget.feedId)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Connection timeout - check your internet connection';
      });

      if (!mounted) return;

      if (feedItem == null) {
        if (mounted) {
          setState(() {
            _error = 'Content not found (ID: ${widget.feedId})';
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('DeepLinkFeedScreen: Item found, navigating to detail page');
      // Use replacement to properly replace loading screen with detail page
      FeedDetailRouter.openWithReplacement(context, feedItem);
    } catch (e) {
      debugPrint('DeepLinkFeedScreen: Error loading feed: $e');
      if (mounted) {
        setState(() {
          _error = 'Unable to load content: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading content...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _loadFeed,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
