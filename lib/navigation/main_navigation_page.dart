import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../feed/feed_page.dart';
import '../study/study_page.dart';
import '../store/store_page.dart';
import '../profile/profile_page.dart';
import 'package:eduverse/core/services/live_class_notifier_service.dart';
import 'package:eduverse/common/widgets/live_class_popup.dart';
import 'package:eduverse/core/services/new_batch_promotion_service.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final NewBatchPromotionService _newBatchPromotionService = NewBatchPromotionService();

  final List<Widget> _pages = const [
    FeedPage(),
    StudyPage(),
    StorePage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final result = await _newBatchPromotionService.getEligiblePromotion();
        if (result != null && mounted) {
          await _newBatchPromotionService.showPromoDialog(context, result);
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiveClassNotifierService>(
      create: (_) => LiveClassNotifierService(
        uid: FirebaseAuth.instance.currentUser!.uid,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            const LiveClassPopup(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Study',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store),
              label: 'Store',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

