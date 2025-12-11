import 'package:flutter/material.dart';
import 'package:eduverse/profile/screens/free_live_classes_page.dart';
import 'package:eduverse/profile/screens/my_downloads_page.dart';
import 'package:eduverse/profile/screens/transactions_page.dart';
import 'package:eduverse/profile/screens/bookmarks_page.dart';
import 'package:eduverse/profile/screens/notifications_page.dart';
import 'package:eduverse/profile/profile_mock_data.dart';
import 'package:eduverse/core/firebase/auth_service.dart';
import 'package:eduverse/admin/admin_entry_page.dart';
import 'package:eduverse/profile/screens/about_page.dart';

class MenuGrid extends StatefulWidget {
  const MenuGrid({super.key});

  @override
  State<MenuGrid> createState() => _MenuGridState();
}

class _MenuGridState extends State<MenuGrid> {
  late Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = AuthService().isAdmin();
  }

  void _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService().signOut();
      // AuthWrapper will automatically redirect to login page
    }
  }

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
              const SizedBox(width: 12),
              Expanded(
                child: card(
                  Icons.info_outline,
                  Colors.indigo,
                  'About Us',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: card(
                  Icons.logout,
                  Colors.red,
                  'Logout',
                  () => _handleLogout(context),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Spacer
            ],
          ),
          
          // Admin Panel - only visible for admin users
          FutureBuilder<bool>(
            future: _isAdminFuture,
            builder: (context, snapshot) {
              debugPrint('Admin FutureBuilder - connectionState: ${snapshot.connectionState}, data: ${snapshot.data}, error: ${snapshot.error}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a small loading indicator while checking admin status
                return const SizedBox.shrink();
              }
              
              if (snapshot.hasError) {
                debugPrint('Error checking admin status: ${snapshot.error}');
                return const SizedBox.shrink();
              }
              
              if (snapshot.data == true) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: card(
                            Icons.admin_panel_settings,
                            Colors.teal,
                            'Admin Panel',
                            () => Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => const AdminEntryPage()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()), // Spacer
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
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
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.backgroundColor,
    required this.onTap,
    this.badge,
  });

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
              color: Colors.black.withValues(alpha: 0.05),
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
