import 'package:flutter/material.dart';
import 'trending_section.dart';
import 'feed_content.dart';
import 'models.dart';

import 'repository/feed_repository.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Seed/Fix data ensuring isPublic field exists
    FeedRepository().seedFeedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Image.asset('assets/icon.png', height: 30),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          const SliverToBoxAdapter(child: TrendingSection()),
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.grey[50],
            elevation: 0,
            toolbarHeight: 0,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Answer Writing'),
                Tab(text: 'Current Affairs'),
                Tab(text: 'Articles'),
                Tab(text: 'Videos'),
                Tab(text: 'Quizzes'),
                Tab(text: 'Jobs'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            FeedContent(type: ContentType.all),
            FeedContent(type: ContentType.answerWriting),
            FeedContent(type: ContentType.currentAffairs),
            FeedContent(type: ContentType.articles),
            FeedContent(type: ContentType.videos),
            FeedContent(type: ContentType.quizzes),
            FeedContent(type: ContentType.jobs),
          ],
        ),
      ),
    );
  }
}
