import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/store/services/test_series_repository.dart';
import 'package:eduverse/study/presentation/screens/test_series_detail_screen.dart';

/// Study tab screen showing the user's purchased/enrolled test series.
class StudyTestSeriesScreen extends StatelessWidget {
  const StudyTestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final repo = TestSeriesRepository();

    return StreamBuilder<List<TestSeriesItem>>(
      stream: repo.getPurchasedTestSeries(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final series = snapshot.data!;
        if (series.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No test series yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Purchase a test series from the Store to start practicing!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: series.length,
          itemBuilder: (context, index) {
            return _StudyTestSeriesCard(item: series[index]);
          },
        );
      },
    );
  }
}

class _StudyTestSeriesCard extends StatelessWidget {
  final TestSeriesItem item;

  const _StudyTestSeriesCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TestSeriesDetailScreen(testSeries: item),
            ),
          );
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                item.gradientColors.first.withValues(alpha: 0.15),
                item.gradientColors.last.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              // Left strip with thumbnail or gradient+emoji
              Container(
                width: 80,
                decoration: BoxDecoration(
                  gradient: item.thumbnailUrl.isEmpty
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: item.gradientColors,
                        )
                      : null,
                ),
                child: item.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: item.gradientColors,
                                ),
                              ),
                              child: Center(
                                child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                      )
                    : Center(
                        child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
                      ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.subject.isNotEmpty) ...[
                            Text(
                              item.subject,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${item.totalTests} tests',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Live progress bar from test_attempts
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid ?? '_')
                            .collection('test_attempts')
                            .snapshots(),
                        builder: (context, attemptsSnap) {
                          int completedCount = 0;
                          if (attemptsSnap.hasData) {
                            final prefix = '${item.id}_';
                            completedCount = attemptsSnap.data!.docs
                                .where((d) => d.id.startsWith(prefix))
                                .length;
                          }
                          final total =
                              item.totalTests > 0 ? item.totalTests : 1;
                          final progressVal =
                              (completedCount / total).clamp(0.0, 1.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressVal,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    item.gradientColors.first,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedCount/${item.totalTests} completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
