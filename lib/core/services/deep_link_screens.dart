import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/store/screens/course_detail_page.dart';
import 'package:eduverse/study/screens/course_section_page.dart';
import 'package:eduverse/study/models/study_models.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/feed/screens/generic_feed_detail_router.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import 'package:eduverse/store/screens/combo_pack_detail_page.dart';
import 'package:eduverse/store/screens/ebook_detail_page.dart';
import 'package:eduverse/store/widgets/store_test_series_content.dart';
import 'package:eduverse/store/services/test_series_repository.dart';

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

      final course = Course(
        id: doc.id,
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        description: data['description'] ?? '',
        emoji: data['emoji'] ?? '📚',
        thumbnailUrl: data['thumbnailUrl'] ?? '',
        gradientColors: _parseGradientColors(data['gradientColors']),
        priceDefault: (data['priceDefault'] as num?)?.toDouble() ?? 0.0,
        realPrice: (data['realPrice'] as num?)?.toDouble() ?? 0.0,
        finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0.0,
        startDate: data['startDate'] != null
            ? (data['startDate'] is Timestamp
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['startDate'].toString()))
            : null,
        endDate: data['endDate'] != null
            ? (data['endDate'] is Timestamp
                ? (data['endDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['endDate'].toString()))
            : null,
        seatsTotal: data['seatsTotal'] ?? 0,
        seatsLeft: data['seatsLeft'] ?? 0,
        duration: data['duration'] ?? '',
        isActive: data['isActive'] ?? true,
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

      // Create StudyCourseModel for CourseSectionPage
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
            child: CourseSectionPage(
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

/// Deep link screen for combo pack detail pages.
/// Route: /app/comboPack/{comboPackId}
class DeepLinkComboPackScreen extends StatefulWidget {
  final String comboPackId;

  const DeepLinkComboPackScreen({super.key, required this.comboPackId});

  @override
  State<DeepLinkComboPackScreen> createState() => _DeepLinkComboPackScreenState();
}

class _DeepLinkComboPackScreenState extends State<DeepLinkComboPackScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComboPack();
  }

  Future<void> _loadComboPack() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('combination_packs')
          .doc(widget.comboPackId)
          .get();

      if (!mounted) return;

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _error = 'Combo pack not found';
          _isLoading = false;
        });
        return;
      }

      final pack = CombinationPack.fromMap(doc.data()!, doc.id);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ComboPackDetailPage(pack: pack),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading combo pack: $e';
        _isLoading = false;
      });
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
              Text('Loading combo pack...'),
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

/// Deep link screen for test series detail pages.
/// Route: /app/testSeries/{testSeriesId}
class DeepLinkTestSeriesScreen extends StatefulWidget {
  final String testSeriesId;

  const DeepLinkTestSeriesScreen({super.key, required this.testSeriesId});

  @override
  State<DeepLinkTestSeriesScreen> createState() => _DeepLinkTestSeriesScreenState();
}

class _DeepLinkTestSeriesScreenState extends State<DeepLinkTestSeriesScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTestSeries();
  }

  Future<void> _loadTestSeries() async {
    try {
      final repo = TestSeriesRepository();
      final item = await repo.getTestSeriesDetail(widget.testSeriesId);

      if (!mounted) return;

      if (item == null) {
        setState(() {
          _error = 'Test series not found';
          _isLoading = false;
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestSeriesDetailPage(testSeries: item),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading test series: $e';
        _isLoading = false;
      });
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
              Text('Loading test series...'),
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

/// Deep link screen for ebook detail pages.
/// Route: /app/ebook/{ebookId}
class DeepLinkEbookScreen extends StatefulWidget {
  final String ebookId;

  const DeepLinkEbookScreen({super.key, required this.ebookId});

  @override
  State<DeepLinkEbookScreen> createState() => _DeepLinkEbookScreenState();
}

class _DeepLinkEbookScreenState extends State<DeepLinkEbookScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEbook();
  }

  Future<void> _loadEbook() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ebooks')
          .doc(widget.ebookId)
          .get();

      if (!mounted) return;

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _error = 'Ebook not found';
          _isLoading = false;
        });
        return;
      }

      final ebook = Ebook.fromMap(doc.data()!, doc.id);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EbookDetailPage(ebook: ebook),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading ebook: $e';
        _isLoading = false;
      });
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
              Text('Loading ebook...'),
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
