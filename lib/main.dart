import 'package:flutter/material.dart';
import 'store/store_page.dart';
import 'feed/feed_page.dart';
import 'study/study_page.dart';
import 'profile/profile_page.dart';

void main() {
  runApp(const LearningApp());
}

class LearningApp extends StatelessWidget {
  const LearningApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FeedPage(),
    StudyPage(),
    StorePage(),
    ProfilePage(),  
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.feed_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
