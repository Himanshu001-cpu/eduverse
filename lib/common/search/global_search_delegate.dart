import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduverse/feed/repository/feed_repository.dart';
import 'package:eduverse/study/data/repositories/study_repository_impl.dart';
import 'package:eduverse/feed/models.dart';
import 'package:eduverse/study/domain/models/study_entities.dart';
import 'package:eduverse/feed/screens/generic_feed_detail_router.dart';
import 'package:eduverse/study/presentation/screens/batch_detail_screen.dart';
import 'package:eduverse/study/presentation/providers/study_controller.dart';
import 'widgets/search_result_item.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final FeedRepository _feedRepository = FeedRepository();
  final StudyRepositoryImpl _studyRepository = StudyRepositoryImpl();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  String get searchFieldLabel => 'Search The Eduverse';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search for courses, videos, and more',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study Results
          if (_currentUserId.isNotEmpty) _buildStudyResults(context),
          
          // Feed Results
          _buildFeedResults(context),
        ],
      ),
    );
  }

  Widget _buildStudyResults(BuildContext context) {
    return StreamBuilder<List<StudyBatch>>(
      stream: _studyRepository.getEnrolledBatches(_currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final results = snapshot.data!.where((batch) => 
          batch.name.toLowerCase().contains(query.toLowerCase()) || 
          batch.courseName.toLowerCase().contains(query.toLowerCase())
        ).toList();

        if (results.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('My Batches'),
            ...results.map((batch) => SearchResultItem(
              title: batch.name,
              subtitle: batch.courseName,
              leadingImageUrl: batch.thumbnailUrl,
              placeholderIcon: Icons.school,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<StudyController>(
                      create: (_) => StudyController(
                        repository: StudyRepositoryImpl(),
                        userId: _currentUserId,
                      ),
                      child: BatchDetailScreen(batch: batch),
                    ),
                  ),
                );
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildFeedResults(BuildContext context) {
    return StreamBuilder<List<FeedItem>>(
      stream: _feedRepository.getFeedItems(limit: 50),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final results = snapshot.data!.where((item) => 
          item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase())
        ).toList();

        if (results.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Content'),
            ...results.map((item) => SearchResultItem(
              title: item.title,
              subtitle: item.description,
              leadingImageUrl: item.thumbnailUrl,
              placeholderIcon: item.buttonIcon,
              iconColor: item.color,
              onTap: () {
                FeedDetailRouter.open(context, item);
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
