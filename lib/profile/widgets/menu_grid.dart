import 'package:flutter/material.dart';
import 'package:eduverse/profile/screens/free_live_classes_page.dart';
import 'package:eduverse/profile/screens/my_downloads_page.dart';
import 'package:eduverse/profile/screens/transactions_page.dart';
import 'package:eduverse/profile/screens/bookmarks_page.dart';
import 'package:eduverse/profile/screens/notifications_page.dart';
import 'package:eduverse/profile/profile_mock_data.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // small helper to keep code tidy
    Widget card(IconData icon, Color iconColor, String title, VoidCallback onTap, {Widget? badge}) {
      return MenuCard(
        icon: icon,
        iconColor: iconColor,
        title: title,
        backgroundColor: Colors.white,
        onTap: onTap,
        badge: badge,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: card(
                  Icons.live_tv,
                  Colors.red,
                  'Free Live Classes',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FreeLiveClassesPage())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: card(
                  Icons.download,
                  Colors.orange,
                  'My Downloads',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyDownloadsPage())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: card(
                  Icons.receipt_long,
                  Colors.cyan,
                  'My Transactions',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsPage())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: card(
                  Icons.bookmark,
                  Colors.purple,
                  'Bookmarks',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksPage())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: ProfileMockData.unreadNotificationCount,
                  builder: (context, count, _) {
                    return card(
                      Icons.notifications,
                      Colors.blueGrey,
                      'Notifications',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
                      badge: count > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
              // Spacer to keep the Notifications card same width as others in the grid
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), 
            ],
          ),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget? badge;

  const MenuCard({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.backgroundColor,
    required this.onTap,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 28),
                if (badge != null)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: badge!,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
