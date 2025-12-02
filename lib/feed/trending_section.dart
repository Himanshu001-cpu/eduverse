import 'dart:async';
import 'package:flutter/material.dart';
import 'trending_card.dart';
import 'feed_data.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({Key? key}) : super(key: key);

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _page = (_page + 1) % FeedData.trending.length;
      if (_controller.hasClients) {
        _controller.animateToPage(_page,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = FeedData.trending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Text('🔥 ', style: TextStyle(fontSize: 20)),
              Text('Trending Posts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: posts.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, index) =>
                TrendingCard(post: posts[index], controller: _controller, index: index),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            posts.length,
                (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _page == i
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
