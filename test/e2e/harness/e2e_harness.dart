import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'fake_firebase_firestore.dart';
import 'fake_firebase_auth.dart';
import 'fake_url_launcher.dart';

class E2EHarness {
  static final E2EHarness _instance = E2EHarness._internal();
  factory E2EHarness() => _instance;
  E2EHarness._internal();

  late FakeFirebaseFirestore firestore;
  late FakeFirebaseAuth auth;
  late FakeUrlLauncher urlLauncher;

  /// Initializes the E2E mock infrastructure.
  void setup() {
    firestore = FakeFirebaseFirestore();
    auth = FakeFirebaseAuth();
    urlLauncher = FakeUrlLauncher();

    // Inject into EduverseFirebase
    EduverseFirebase.mockFirestore = firestore;
    EduverseFirebase.mockAuth = auth;

    // Inject url launcher override
    UrlLauncherPlatform.instance = urlLauncher;
  }

  /// Resets the mock infrastructure states.
  void reset() {
    firestore.data.clear();
    firestore.listeners.clear();
    auth.changeCurrentUser(null);
    urlLauncher.launchedUrls.clear();
  }

  /// Sets up a logged-in fake user.
  void authenticateUser({String uid = 'test_user', String email = 'test_user@eduverse.com'}) {
    final fakeUser = FakeUser(uid: uid, email: email);
    auth.changeCurrentUser(fakeUser);
    
    // Seed user document in firestore
    firestore.setDoc('users/$uid', {
      'uid': uid,
      'email': email,
      'displayName': 'Test User',
      'enrolledCourses': <String>[],
      'purchasedEbooks': <String>[],
      'purchasedTestSeries': <String>[],
      'cart': <String>[],
    });
  }

  /// Seeds store baseline data (courses, ebooks, test series).
  void seedBaselineData() {
    // 1. Seed courses
    _seedCourse('course_1', 'Flutter Development Masterclass', 49.99);
    _seedCourse('course_2', 'Python for Beginners', 29.99);
    _seedCourse('course_3', 'Advanced AI & Machine Learning', 99.99);

    // 2. Seed ebooks
    _seedEbook('ebook_1', 'Flutter Cookbook', 14.99);
    _seedEbook('ebook_2', 'Python Interview Prep', 9.99);
    _seedEbook('ebook_3', 'Machine Learning Guide', 19.99);

    // 3. Seed test series
    _seedTestSeries('ts_1', 'UPSC Prelims Mock Series', 39.99, subject: 'General Studies');
    _seedTestSeries('ts_2', 'JEE Advanced Physics Test Series', 24.99, subject: 'Physics');
  }

  void _seedCourse(String id, String title, double price) {
    firestore.setDoc('courses/$id', {
      'title': title,
      'description': 'Description for $title',
      'price': price,
      'visibility': 'published',
      'createdAt': Timestamp.now(),
      'category': 'Development',
      'rating': 4.5,
      'duration': '20 hours',
      'thumbnailUrl': 'https://example.com/course_$id.png',
      'gradientColors': [0xFF4CAF50, 0xFF2E7D32],
      'emoji': '💻',
    });
  }

  void _seedEbook(String id, String title, double price) {
    firestore.setDoc('ebooks/$id', {
      'title': title,
      'description': 'Description for $title',
      'price': price,
      'visibility': 'published',
      'isActive': true,
      'createdAt': Timestamp.now(),
      'category': 'Development',
      'author': 'Eduverse Expert',
      'pages': 150,
      'fileSize': '5 MB',
      'downloadUrl': 'https://example.com/ebook_$id.pdf',
      'pdfUrl': 'https://example.com/ebook_$id.pdf',
      'thumbnailUrl': 'https://example.com/ebook_$id.png',
    });
  }

  void _seedTestSeries(String id, String title, double price, {required String subject}) {
    firestore.setDoc('test_series/$id', {
      'title': title,
      'description': 'Description for $title',
      'price': price,
      'visibility': 'published',
      'createdAt': Timestamp.now(),
      'subject': subject,
      'category': 'Full Length',
      'thumbnailUrl': 'https://example.com/ts_$id.png',
      'gradientColors': [0xFF4CAF50, 0xFF2E7D32],
      'emoji': '📝',
      'totalTests': 2,
    });

    // Seed individual tests for the series
    _seedTest(id, 'test_1', 'Mock Test 1', 1, subject: subject);
    _seedTest(id, 'test_2', 'Mock Test 2', 2, subject: subject);
  }

  void _seedTest(String tsId, String testId, String title, int order, {required String subject}) {
    firestore.setDoc('test_series/$tsId/tests/$testId', {
      'title': title,
      'durationMinutes': 60,
      'timeLimitSeconds': 3600,
      'totalQuestions': 3,
      'marksPerQuestion': 2.0,
      'negativeMarking': 0.5,
      'order': order,
      'subject': subject,
      'category': 'Full Length',
      'questions': [
        {
          'question': 'What is the capital of France?',
          'options': [
            {'text': 'London', 'isCorrect': false},
            {'text': 'Paris', 'isCorrect': true},
            {'text': 'Berlin', 'isCorrect': false},
            {'text': 'Rome', 'isCorrect': false},
          ],
          'correctIndex': 1,
          'score': 2,
          'subject': subject,
          'explanation': 'Paris is the capital of France.',
        },
        {
          'question': 'What is 2 + 2?',
          'options': [
            {'text': '3', 'isCorrect': false},
            {'text': '4', 'isCorrect': true},
            {'text': '5', 'isCorrect': false},
            {'text': '6', 'isCorrect': false},
          ],
          'correctIndex': 1,
          'score': 2,
          'subject': subject,
          'explanation': '2 + 2 = 4.',
        },
        {
          'question': 'Which planet is known as the Red Planet?',
          'options': [
            {'text': 'Earth', 'isCorrect': false},
            {'text': 'Mars', 'isCorrect': true},
            {'text': 'Jupiter', 'isCorrect': false},
            {'text': 'Venus', 'isCorrect': false},
          ],
          'correctIndex': 1,
          'score': 2,
          'subject': subject,
          'explanation': 'Mars is known as the Red Planet.',
        }
      ],
    });
  }

  /// Sets up pre-purchased items for a user.
  void grantOwnership({
    required String uid,
    List<String> courses = const [],
    List<String> ebooks = const [],
    List<String> testSeries = const [],
  }) {
    final userPath = 'users/$uid';
    final userDoc = firestore.data[userPath] ?? <String, dynamic>{};
    
    if (courses.isNotEmpty) {
      final enrolled = List<String>.from(userDoc['enrolledCourses'] ?? []);
      for (final courseId in courses) {
        if (!enrolled.contains(courseId)) enrolled.add(courseId);
        // Also write enrolledCourse document
        firestore.setDoc('users/$uid/enrolledCourses/$courseId', {
          'courseId': courseId,
          'enrolledAt': Timestamp.now(),
        });
      }
      userDoc['enrolledCourses'] = enrolled;
    }

    if (ebooks.isNotEmpty) {
      final purchased = List<String>.from(userDoc['purchasedEbooks'] ?? []);
      for (final ebookId in ebooks) {
        if (!purchased.contains(ebookId)) purchased.add(ebookId);
        // Also write purchasedEbook subcollection
        firestore.setDoc('users/$uid/purchasedEbooks/$ebookId', {
          'ebookId': ebookId,
          'purchasedAt': Timestamp.now(),
        });
      }
      userDoc['purchasedEbooks'] = purchased;
    }

    if (testSeries.isNotEmpty) {
      final purchased = List<String>.from(userDoc['purchasedTestSeries'] ?? []);
      for (final tsId in testSeries) {
        if (!purchased.contains(tsId)) purchased.add(tsId);
        // Also write purchasedTestSeries subcollection
        firestore.setDoc('users/$uid/purchasedTestSeries/$tsId', {
          'testSeriesId': tsId,
          'purchasedAt': Timestamp.now(),
        });
      }
      userDoc['purchasedTestSeries'] = purchased;
      // Also update standard user profile purchasedTestSeries
      userDoc['purchasedTestSeries'] = purchased;
    }

    firestore.data[userPath] = userDoc;
  }
}
