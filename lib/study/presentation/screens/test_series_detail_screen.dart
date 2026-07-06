import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/feed/screens/quiz_page.dart';

/// Category display config: label and emoji.
const Map<String, (String, IconData)> categoryConfig = {
  'General': ('📋 General Tests', Icons.list_alt),
  'Prelims': ('📝 Prelims Tests', Icons.edit_note),
  'Mains': ('🎯 Mains Tests', Icons.gps_fixed),
  'Topic Wise': ('📚 Topic Wise Tests', Icons.menu_book),
  'Full Length': ('🏆 Full Length Tests', Icons.emoji_events),
  'Sectional': ('🧩 Sectional Tests', Icons.extension),
  'Previous Year': ('📅 Previous Year Tests', Icons.calendar_month),
};

/// Student-facing detail screen for a test series.
/// Matches the design pattern of CourseDetailPage.
/// Tests are grouped by category (Full Length / Topic Wise / Sectional).
class TestSeriesDetailScreen extends StatelessWidget {
  final TestSeriesItem testSeries;

  const TestSeriesDetailScreen({super.key, required this.testSeries});

  static List<Widget> buildCategorySlivers(
      List<QueryDocumentSnapshot> tests, String testSeriesId, String uid) {
    // Group tests by category
    final Map<String, List<(QueryDocumentSnapshot, int)>> grouped = {};
    for (var i = 0; i < tests.length; i++) {
      final data = tests[i].data() as Map<String, dynamic>;
      final cat = (data['category'] as String?)?.isNotEmpty == true
          ? data['category'] as String
          : 'General';
      grouped.putIfAbsent(cat, () => []).add((tests[i], i));
    }

    // Order: Full Length, Topic Wise, Sectional, then others
    final orderedKeys = <String>[
      if (grouped.containsKey('Full Length')) 'Full Length',
      if (grouped.containsKey('Topic Wise')) 'Topic Wise',
      if (grouped.containsKey('Sectional')) 'Sectional',
      ...grouped.keys.where(
        (k) =>
            k != 'Full Length' &&
            k != 'Topic Wise' &&
            k != 'Sectional',
      ),
    ];

    // Build slivers for each category
    final List<Widget> slivers = [];
    for (final category in orderedKeys) {
      final items = grouped[category]!;
      final config = categoryConfig[category];
      final label = config?.$1 ?? '📋 $category';

      // Section header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );

      // Test cards for this category
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                final (doc, originalIndex) = items[index];
                final data = doc.data() as Map<String, dynamic>;
                return TestCard(
                  testId: doc.id,
                  testSeriesId: testSeriesId,
                  testData: data,
                  index: originalIndex,
                  uid: uid,
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    final ts = testSeries;
    final uid = EduverseFirebase.auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: EduverseFirebase.firestore
          .collection('test_series')
          .doc(ts.id)
          .collection('tests')
          .orderBy('order')
          .snapshots(),
      builder: (context, testsSnap) {
        if (testsSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(ts.title)),
            body: Center(child: Text('Error: ${testsSnap.error}')),
          );
        }
        if (!testsSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final testDocs = testsSnap.data!.docs;
        final testIds = testDocs.map((d) => d.id).toSet();
        final actualTotalTests = testDocs.length;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(ts.title, style: const TextStyle(fontSize: 16)),
                  background: ts.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          ts.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: ts.gradientColors.isNotEmpty
                                    ? ts.gradientColors
                                    : [Colors.blue, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(ts.emoji, style: const TextStyle(fontSize: 64)),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: ts.gradientColors.isNotEmpty
                                  ? ts.gradientColors
                                  : [Colors.blue, Colors.blueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(ts.emoji, style: const TextStyle(fontSize: 64)),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle / description
                      if (ts.description.isNotEmpty)
                        Text(
                          ts.description,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      if (ts.description.isNotEmpty) const SizedBox(height: 8),

                      // Info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text('$actualTotalTests Tests'),
                            avatar: const Icon(Icons.quiz, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress — live from test_attempts
                      StreamBuilder<QuerySnapshot>(
                        stream: uid.isNotEmpty
                            ? EduverseFirebase.firestore
                                  .collection('users')
                                  .doc(uid)
                                  .collection('test_attempts')
                                  .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${ts.id}_')
                                  .where(FieldPath.documentId, isLessThan: '${ts.id}_\uf8ff')
                                  .snapshots()
                            : const Stream.empty(),
                        builder: (context, attemptsSnap) {
                          // Count attempts that belong to this test series
                          int completedCount = 0;
                          if (attemptsSnap.hasData) {
                            completedCount = attemptsSnap.data!.docs.where((d) {
                              final docId = d.id;
                              final prefix = '${ts.id}_';
                              if (docId.startsWith(prefix)) {
                                final testId = docId.substring(prefix.length);
                                return testIds.contains(testId);
                              }
                              return false;
                            }).length;
                          }
                          final total = actualTotalTests > 0 ? actualTotalTests : 1;
                          final progressVal =
                              (completedCount / total).clamp(0.0, 1.0);

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Your Progress',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$completedCount/$actualTotalTests completed',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressVal,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Available Tests',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Test list — grouped by category
              if (testDocs.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No tests available yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                )
              else
                MultiSliver(
                  children: buildCategorySlivers(testDocs, ts.id, uid),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

/// Helper widget to embed multiple slivers within a single sliver slot.
/// Flutter doesn't natively allow returning multiple slivers from a builder,
/// so we wrap them in a SliverList of SliverToBoxAdapters where needed.
/// However, we can use SliverMainAxisGroup if available, or just flatten.
class MultiSliver extends StatelessWidget {
  final List<Widget> children;
  const MultiSliver({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: children);
  }
}

/// Test card matching the style of batch cards in CourseDetailPage.
/// Now shows a Subject badge next to the questions count.
class TestCard extends StatelessWidget {
  final String testId;
  final String testSeriesId;
  final Map<String, dynamic> testData;
  final int index;
  final String uid;

  const TestCard({
    required this.testId,
    required this.testSeriesId,
    required this.testData,
    required this.index,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final title = testData['title'] ?? 'Test ${index + 1}';
    final totalQs = testData['totalQuestions'] ?? 0;
    final duration = testData['durationMinutes'] ?? 0;
    final subject = testData['subject'] as String? ?? '';
    final scheduledAtStamp = testData['scheduledAt'] as Timestamp?;
    final scheduledAt = scheduledAtStamp?.toDate();
    final isScheduledForFuture =
        scheduledAt != null && scheduledAt.isAfter(DateTime.now());

    return StreamBuilder<DocumentSnapshot>(
      stream: uid.isNotEmpty
          ? EduverseFirebase.firestore
                .collection('users')
                .doc(uid)
                .collection('test_attempts')
                .doc('${testSeriesId}_$testId')
                .snapshots()
          : const Stream.empty(),
      builder: (context, attemptSnap) {
        final hasAttempted = attemptSnap.hasData && attemptSnap.data!.exists;
        Map<String, dynamic>? attemptData;
        if (hasAttempted) {
          attemptData = attemptSnap.data!.data() as Map<String, dynamic>?;
        }
        final score = attemptData?['score'];
        final totalMarks = attemptData?['totalMarks'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasAttempted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$totalQs Questions • $duration min'),
                    if (subject.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          subject,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasAttempted && score != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Score: $score / $totalMarks',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Spacer(),
                    if (isScheduledForFuture)
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.lock_clock, size: 16),
                        label: Text(
                          '${scheduledAt.day}/${scheduledAt.month} at ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _startTest(context),
                        style: hasAttempted
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              )
                            : null,
                        child: Text(hasAttempted ? 'Retake Test' : 'Start Test'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startTest(BuildContext context) {
    // Convert test data to FeedItem quiz format
    final rawQuestions = testData['questions'] as List<dynamic>? ?? [];
    if (rawQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions in this test yet')),
      );
      return;
    }

    // Questions are already in QuizQuestion.toJson() format
    final quizQuestions = rawQuestions.map((q) {
      final map = q as Map<String, dynamic>;
      return QuizQuestion.fromJson(map);
    }).toList();

    final feedItem = FeedItem(
      id: '${testSeriesId}_$testId',
      type: ContentType.quizzes,
      title: testData['title'] ?? 'Test',
      description: testData['description'] ?? '',
      categoryLabel: 'Test Series',
      emoji: '📝',
      color: Theme.of(context).primaryColor,
      quizQuestions: quizQuestions,
      quizInstructions: testData['instructions'] as String?,
      quizTimeLimitMinutes: testData['durationMinutes'] as int?,
      quizTimeLimitSeconds: testData['timeLimitSeconds'] as int?,
      quizMarksPerQuestion: (testData['marksPerQuestion'] as num?)?.toDouble(),
      quizNegativeMarking: (testData['negativeMarking'] as num?)?.toDouble(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizPage(item: feedItem)),
    );
  }
}
