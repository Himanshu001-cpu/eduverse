import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduverse/core/firebase/eduverse_firebase.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/study_home_screen.dart';
import 'package:eduverse/study/presentation/screens/study_test_series_screen.dart';
import 'package:eduverse/study/presentation/screens/test_series_detail_screen.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';
import 'package:eduverse/study/presentation/widgets/study_ebooks_content.dart';
import 'package:eduverse/study/presentation/widgets/batch_selector_widget.dart';
import 'package:eduverse/study/presentation/widgets/sticky_tab_pills.dart';
import 'package:eduverse/admin/screens/exam_management_screen.dart';
import '../../common/search/global_search_delegate.dart';

import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/store/models/store_models.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  @override
  Widget build(BuildContext context) {
    final userId = EduverseFirebase.auth.currentUser?.uid ?? '';

    return ChangeNotifierProvider<StudyController>(
      create: (_) =>
          StudyController(repository: StudyRepositoryImpl(), userId: userId),
      child: Consumer<StudyController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: Row(
                children: [
                  Image.asset('assets/icon.png', height: 36),
                  const SizedBox(width: 8),
                  const Text(
                    'The Eduverse',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  key: const Key('admin_panel_nav_link'),
                  icon: const Icon(Icons.admin_panel_settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => ChangeNotifierProvider.value(
                          value: controller,
                          child: const ExamManagementScreen(),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(context: context, delegate: GlobalSearchDelegate());
                  },
                ),
              ],
            ),
            body: CustomScrollView(
              slivers: _buildSlivers(context, controller),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context, StudyController controller) {
    final List<Widget> slivers = [
      const SliverToBoxAdapter(
        child: BatchSelectorWidget(),
      ),
    ];

    if (controller.selectedRoomType == 'test_series') {
      slivers.addAll(_buildTestSeriesSlivers(context, controller));
    } else if (controller.selectedRoomType == 'ebook') {
      slivers.add(_buildEbookSliver(context, controller));
    } else {
      StudyBatch? selectedBatch;
      try {
        selectedBatch = controller.enrolledBatches.firstWhere(
          (b) => b.id == controller.selectedBatchId,
        );
      } catch (_) {}

      final showTabs = selectedBatch == null || selectedBatch.isCombo;

      if (showTabs) {
        slivers.addAll([
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyTabPillHeaderDelegate(
              child: const StickyTabPillsWidget(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            sliver: SliverToBoxAdapter(
              child: _buildTabContent(context, controller.currentTab),
            ),
          ),
        ]);
      } else {
        slivers.add(
          const SliverPadding(
            padding: EdgeInsets.only(top: 12, bottom: 24),
            sliver: SliverToBoxAdapter(
              child: StudyHomeScreen(),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  List<Widget> _buildTestSeriesSlivers(BuildContext context, StudyController controller) {
    final tsId = controller.selectedRoomId;
    if (tsId == null) return [const SliverToBoxAdapter(child: SizedBox.shrink())];

    TestSeriesItem? ts;
    try {
      ts = controller.purchasedTestSeries.firstWhere((item) => item.id == tsId);
    } catch (_) {}

    if (ts == null) {
      return [
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
        )
      ];
    }

    final uid = EduverseFirebase.auth.currentUser?.uid ?? '';

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ts.description.isNotEmpty) ...[
                Text(
                  ts.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
              ],

              // Progress Card
              StreamBuilder<QuerySnapshot>(
                stream: EduverseFirebase.firestore
                    .collection('test_series')
                    .doc(ts.id)
                    .collection('tests')
                    .snapshots(),
                builder: (context, testsSnap) {
                  if (!testsSnap.hasData) return const SizedBox.shrink();
                  final testDocs = testsSnap.data!.docs;
                  final testIds = testDocs.map((d) => d.id).toSet();
                  final actualTotalTests = testDocs.length;

                  return StreamBuilder<QuerySnapshot>(
                    stream: uid.isNotEmpty
                        ? EduverseFirebase.firestore
                              .collection('users')
                              .doc(uid)
                              .collection('test_attempts')
                              .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${ts!.id}_')
                              .where(FieldPath.documentId, isLessThan: '${ts.id}_\uf8ff')
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, attemptsSnap) {
                      int completedCount = 0;
                      if (attemptsSnap.hasData) {
                        completedCount = attemptsSnap.data!.docs.where((d) {
                          final docId = d.id;
                          final prefix = '${ts!.id}_';
                          if (docId.startsWith(prefix)) {
                            final testId = docId.substring(prefix.length);
                            return testIds.contains(testId);
                          }
                          return false;
                        }).length;
                      }
                      final total = actualTotalTests > 0 ? actualTotalTests : 1;
                      final progressVal = (completedCount / total).clamp(0.0, 1.0);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$completedCount/$actualTotalTests completed',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
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
                                  Colors.blue.shade700,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Available Tests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      StreamBuilder<QuerySnapshot>(
        stream: EduverseFirebase.firestore
            .collection('test_series')
            .doc(ts.id)
            .collection('tests')
            .orderBy('order')
            .snapshots(),
        builder: (context, testsSnap) {
          if (testsSnap.hasError) {
            return SliverToBoxAdapter(
              child: Center(child: Text('Error: ${testsSnap.error}')),
            );
          }
          if (!testsSnap.hasData) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final testDocs = testsSnap.data!.docs;
          if (testDocs.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No tests available in this series yet.'),
                ),
              ),
            );
          }

          return MultiSliver(
            children: TestSeriesDetailScreen.buildCategorySlivers(testDocs, ts!.id, uid),
          );
        },
      ),
    ];
  }

  Widget _buildEbookSliver(BuildContext context, StudyController controller) {
    final ebookId = controller.selectedRoomId;
    if (ebookId == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    Ebook? ebook;
    try {
      ebook = controller.ownedEbooks.firstWhere((eb) => eb.id == ebookId);
    } catch (_) {}

    if (ebook == null) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 210,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ebook.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            ebook.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildEbookFallback(ebook!),
                          )
                        : _buildEbookFallback(ebook),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  ebook.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  ebook.subtitle.isNotEmpty ? ebook.subtitle : 'Study E-book',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      PdfNavigationManager.navigateToViewer(
                        context,
                        SecurePdfViewerArgs(
                          pdfUrl: ebook!.pdfUrl,
                          title: ebook.title,
                          isProtected: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text(
                      'READ E-BOOK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEbookFallback(Ebook ebook) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.book,
        size: 64,
        color: Colors.white70,
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String currentTab) {
    switch (currentTab) {
      case 'Courses':
        return const StudyHomeScreen();
      case 'Test Series':
        return const StudyTestSeriesScreen();
      case 'E-books':
        return const StudyEbooksContent();
      default:
        return const SizedBox.shrink();
    }
  }
}
