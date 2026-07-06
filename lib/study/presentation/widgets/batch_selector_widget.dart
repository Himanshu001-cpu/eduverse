import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'package:eduverse/study/presentation/screens/batch_detail_screen.dart';
import 'package:eduverse/study/presentation/screens/secure_pdf_viewer_screen.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'batch_selector_bottom_sheet.dart';
import 'batch_thumbnail_widget.dart';

class BatchSelectorWidget extends StatelessWidget {
  const BatchSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);
    
    final hasNoRooms = controller.enrolledBatches.isEmpty &&
        controller.purchasedTestSeries.isEmpty &&
        controller.ownedEbooks.isEmpty;

    if (hasNoRooms) {
      return const SizedBox.shrink();
    }

    String label = 'MY STUDY ROOM';
    String title = '';
    Widget thumbnail;
    VoidCallback? onTap;

    if (controller.selectedRoomType == 'test_series') {
      label = 'MY TEST SERIES';
      TestSeriesItem? ts;
      try {
        ts = controller.purchasedTestSeries.firstWhere((item) => item.id == controller.selectedRoomId);
      } catch (_) {}
      
      title = ts?.title ?? 'Test Series';
      
      final hasThumbnail = ts != null && ts.thumbnailUrl.isNotEmpty && ts.thumbnailUrl.startsWith('http');
      thumbnail = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ts != null && ts.gradientColors.isNotEmpty
                ? ts.gradientColors
                : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: hasThumbnail
              ? Image.network(
                  ts.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      ts?.emoji ?? '📝',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    ts?.emoji ?? '📝',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
        ),
      );
      
      onTap = () {
        // Tapping does not need to navigate, it is shown inline
      };
    } else if (controller.selectedRoomType == 'ebook') {
      label = 'MY E-BOOK';
      Ebook? eb;
      try {
        eb = controller.ownedEbooks.firstWhere((item) => item.id == controller.selectedRoomId);
      } catch (_) {}
      
      title = eb?.title ?? 'E-book';
      
      final hasThumbnail = eb != null && eb.thumbnailUrl.isNotEmpty && eb.thumbnailUrl.startsWith('http');
      thumbnail = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.indigo.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: hasThumbnail
              ? Image.network(
                  eb.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.book,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.book,
                    size: 20,
                    color: Colors.white70,
                  ),
                ),
        ),
      );
      
      onTap = () {
        if (eb != null && eb.pdfUrl.isNotEmpty) {
          PdfNavigationManager.navigateToViewer(
            context,
            SecurePdfViewerArgs(
              pdfUrl: eb.pdfUrl,
              title: eb.title,
              isProtected: true,
            ),
          );
        }
      };
    } else {
      StudyBatch? selectedBatch;
      try {
        selectedBatch = controller.enrolledBatches.firstWhere(
          (b) => b.id == controller.selectedRoomId,
        );
      } catch (_) {}
      
      if (selectedBatch == null && controller.enrolledBatches.isNotEmpty) {
        selectedBatch = controller.enrolledBatches.first;
      }
      
      if (selectedBatch != null) {
        title = selectedBatch.name;
        thumbnail = BatchThumbnailWidget(
          batch: selectedBatch,
          width: 40,
          height: 40,
          borderRadius: 10,
          emojiSize: 20,
        );
        onTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: controller,
                child: BatchDetailScreen(batch: selectedBatch!),
              ),
            ),
          );
        };
      } else {
        title = 'Select Batch';
        thumbnail = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.school, color: Colors.grey),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('batch_selector_navigate'),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        thumbnail,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                key: const Key('selected_batch_name_text'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 32,
              width: 1,
              color: Colors.grey.shade200,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('batch_selector_dropdown'),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) {
                      return ChangeNotifierProvider.value(
                        value: controller,
                        child: const BatchSelectorBottomSheet(),
                      );
                    },
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
