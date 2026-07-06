import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/study/domain/models/test_series_entities.dart';
import 'package:eduverse/store/models/store_models.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'batch_thumbnail_widget.dart';

class BatchSelectorBottomSheet extends StatefulWidget {
  const BatchSelectorBottomSheet({super.key});

  @override
  State<BatchSelectorBottomSheet> createState() => _BatchSelectorBottomSheetState();
}

class _BatchSelectorBottomSheetState extends State<BatchSelectorBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudyController>(context);

    return DefaultTabController(
      length: 3,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Study Room',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // TabBar
            TabBar(
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Courses'),
                Tab(text: 'Test Series'),
                Tab(text: 'E-books'),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search room...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Lists
            Expanded(
              child: TabBarView(
                children: [
                  _buildCoursesTab(context, controller),
                  _buildTestSeriesTab(context, controller),
                  _buildEbooksTab(context, controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTab(BuildContext context, StudyController controller) {
    final allBatches = controller.enrolledBatches;
    final filteredBatches = allBatches.where((b) {
      final nameMatches = b.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final courseMatches = b.courseName.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || courseMatches;
    }).toList();

    final comboPacks = filteredBatches.where((b) => b.isCombo).toList();
    final individualBatches = filteredBatches.where((b) => !b.isCombo).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        if (comboPacks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'COMBO PACKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...comboPacks.map((batch) => _buildBatchTile(context, controller, batch)),
          const SizedBox(height: 16),
        ],
        if (individualBatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'INDIVIDUAL BATCHES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...individualBatches.map((batch) => _buildBatchTile(context, controller, batch)),
        ],
        if (filteredBatches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No batches found matching "$_searchQuery"',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTestSeriesTab(BuildContext context, StudyController controller) {
    final allSeries = controller.purchasedTestSeries;
    final filteredSeries = allSeries.where((ts) {
      final titleMatches = ts.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final subjectMatches = ts.subject.toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatches || subjectMatches;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        if (filteredSeries.isNotEmpty)
          ...filteredSeries.map((ts) => _buildTestSeriesTile(context, controller, ts))
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                allSeries.isEmpty 
                    ? 'No purchased test series yet.' 
                    : 'No test series matching "$_searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEbooksTab(BuildContext context, StudyController controller) {
    final allEbooks = controller.ownedEbooks;
    final filteredEbooks = allEbooks.where((eb) {
      final titleMatches = eb.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final subtitleMatches = eb.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatches || subtitleMatches;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        if (filteredEbooks.isNotEmpty)
          ...filteredEbooks.map((eb) => _buildEbookTile(context, controller, eb))
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                allEbooks.isEmpty 
                    ? 'No owned e-books yet.' 
                    : 'No e-books matching "$_searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBatchTile(BuildContext context, StudyController controller, StudyBatch batch) {
    final isSelected = batch.id == controller.selectedRoomId && controller.selectedRoomType == 'course';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: Key('batch_item_${batch.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: BatchThumbnailWidget(
            batch: batch,
            width: 44,
            height: 44,
            borderRadius: 12,
            emojiSize: 22,
          ),
          title: Text(
            batch.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              batch.isCombo ? 'Combo Pack' : batch.courseName,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              : null,
          onTap: () {
            controller.selectStudyRoom(batch.id, 'course');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildTestSeriesTile(BuildContext context, StudyController controller, TestSeriesItem ts) {
    final isSelected = ts.id == controller.selectedRoomId && controller.selectedRoomType == 'test_series';
    final hasThumbnail = ts.thumbnailUrl.isNotEmpty && ts.thumbnailUrl.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: Key('test_series_item_${ts.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ts.gradientColors.isNotEmpty
                    ? ts.gradientColors
                    : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasThumbnail
                  ? Image.network(
                      ts.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          ts.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        ts.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
            ),
          ),
          title: Text(
            ts.title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              ts.subject.isNotEmpty ? '${ts.subject} • ${ts.totalTests} tests' : '${ts.totalTests} tests',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              : null,
          onTap: () {
            controller.selectStudyRoom(ts.id, 'test_series');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildEbookTile(BuildContext context, StudyController controller, Ebook eb) {
    final isSelected = eb.id == controller.selectedRoomId && controller.selectedRoomType == 'ebook';
    final hasThumbnail = eb.thumbnailUrl.isNotEmpty && eb.thumbnailUrl.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: Key('ebook_item_${eb.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasThumbnail
                  ? Image.network(
                      eb.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.book,
                          size: 22,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.book,
                        size: 22,
                        color: Colors.white70,
                      ),
                    ),
            ),
          ),
          title: Text(
            eb.title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              eb.subtitle.isNotEmpty ? eb.subtitle : 'Study E-book',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              : null,
          onTap: () {
            controller.selectStudyRoom(eb.id, 'ebook');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
