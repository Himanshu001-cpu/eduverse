import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../../core/firebase/eduverse_firebase.dart';
import '../screens/admin_login_screen.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EduverseTheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<FirebaseAdminService>().signOut();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = EduverseFirebase.auth.currentUser;
    if (user == null) return null;
    final doc = await EduverseFirebase.firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb && screenWidth >= 1024;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isDashboard = currentRoute == '/' || currentRoute == '/dashboard';

    if (isDesktop) {
      return Scaffold(
        backgroundColor: EduverseTheme.surface,
        body: Row(
          children: [
            // Left Categorized Executive Sidebar (Matching Stitch)
            _buildDesktopSidebar(context, currentRoute),

            // Right Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Executive Command Bar (Matching Stitch Header)
                  _buildDesktopTopBar(context, isDashboard),

                  // Main View Body
                  Expanded(
                    child: body,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile / Tablet Responsive Fallback
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EduverseTheme.surfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: !isDashboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Eduverse: $title',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (!isDashboard)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ...?actions,
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final role = data?['role'] ?? 'admin';
            final restrictMenu = role == 'teacher';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: EduverseTheme.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/icon.png', height: 32, width: 32, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                          const SizedBox(width: 8),
                          const Text(
                            'The Eduverse',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: EduverseTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                _mobileNavItem(context, 'Dashboard', '/dashboard', Icons.dashboard),
                _mobileNavItem(context, 'Communities', '/communities', Icons.forum),
                if (!restrictMenu) ...[
                  _mobileNavItem(context, 'Courses', '/courses', Icons.school),
                  _mobileNavItem(context, 'Users', '/users', Icons.people),
                  _mobileNavItem(context, 'Purchases', '/purchases', Icons.shopping_cart),
                  _mobileNavItem(context, 'Enrollments', '/enrollments', Icons.how_to_reg),
                  _mobileNavItem(context, 'Exams', '/exams', Icons.assignment, key: const Key('drawer_admin_link')),
                  _mobileNavItem(context, 'Promo Codes', '/promo_codes', Icons.local_offer),
                  _mobileNavItem(context, 'Test Series', '/test_series', Icons.quiz),
                  _mobileNavItem(context, 'Combo Packs', '/combination_packs', Icons.card_giftcard),
                  _mobileNavItem(context, 'E-books Manager', '/ebooks_manager', Icons.book),
                  _mobileNavItem(context, 'Feed Management', '/feed_list', Icons.feed),
                  _mobileNavItem(context, 'Notification Center', '/notifications', Icons.notification_important),
                  _mobileNavItem(context, 'Poster Manager', '/posters', Icons.photo_library),
                  _mobileNavItem(context, 'Free Live Classes', '/live_classes', Icons.live_tv),
                  _mobileNavItem(context, 'Payment Settings', '/payment_settings', Icons.payment),
                  _mobileNavItem(context, 'Settings', '/settings', Icons.settings),
                ],
              ],
            );
          },
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, String? currentRoute) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceBright,
        border: Border(
          right: BorderSide(
            color: EduverseTheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo & Title
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: EduverseTheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/icon.png',
                  height: 34,
                  width: 34,
                  errorBuilder: (_, _, _) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: EduverseTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Eduverse',
                      style: EduverseTheme.headlineMd(color: EduverseTheme.primary).copyWith(fontSize: 16),
                    ),
                    const Text(
                      'ADMIN CONSOLE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: EduverseTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categorized Navigation Sections (Matching Stitch)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _sidebarSectionHeader('OVERVIEW'),
                _sidebarItem(context, 'Dashboard', '/dashboard', Icons.space_dashboard_outlined, currentRoute),

                _sidebarSectionHeader('USERS & ASPIRANTS'),
                _sidebarItem(context, 'Students', '/students', Icons.people_outline, currentRoute),
                _sidebarItem(context, 'Teachers & Faculty', '/teachers', Icons.co_present_outlined, currentRoute),

                _sidebarSectionHeader('ACADEMIC & STORE'),
                _sidebarItem(context, 'Courses & Programs', '/courses', Icons.auto_stories_outlined, currentRoute),
                _sidebarItem(context, 'Live Sessions', '/live_classes', Icons.live_tv_outlined, currentRoute),
                _sidebarItem(context, 'Test Series', '/test_series', Icons.quiz_outlined, currentRoute),
                _sidebarItem(context, 'Combo Packs', '/combination_packs', Icons.layers_outlined, currentRoute),
                _sidebarItem(context, 'E-books Library', '/ebooks_manager', Icons.menu_book_outlined, currentRoute),

                _sidebarSectionHeader('FINANCIALS'),
                _sidebarItem(context, 'Transactions & Sales', '/purchases', Icons.receipt_long_outlined, currentRoute),
                _sidebarItem(context, 'Enrollments', '/enrollments', Icons.how_to_reg_outlined, currentRoute),
                _sidebarItem(context, 'Coupons & Promos', '/promo_codes', Icons.sell_outlined, currentRoute),

                _sidebarSectionHeader('PLATFORM'),
                _sidebarItem(context, 'Community Forum', '/communities', Icons.forum_outlined, currentRoute),
                _sidebarItem(context, 'Feed Management', '/feed_list', Icons.feed_outlined, currentRoute),
                _sidebarItem(context, 'Notification Center', '/notifications', Icons.notifications_none_outlined, currentRoute),
                _sidebarItem(context, 'Payment Settings', '/payment_settings', Icons.payments_outlined, currentRoute),
                _sidebarItem(context, 'Settings', '/settings', Icons.settings_outlined, currentRoute),
              ],
            ),
          ),

          // Version & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: EduverseTheme.emeraldVivid,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'v4.2.0-core • Synced',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: EduverseTheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // User Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: EduverseTheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: EduverseTheme.primaryFixed,
                  child: const Icon(Icons.person, color: EduverseTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dean / Superadmin',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Academic Affairs',
                        style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: EduverseTheme.onSurfaceVariant),
                  tooltip: 'Logout',
                  onPressed: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: EduverseTheme.outline,
        ),
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    String title,
    String route,
    IconData icon,
    String? currentRoute,
  ) {
    final isSelected = currentRoute == route || (route == '/dashboard' && currentRoute == '/');

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? EduverseTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        leading: Icon(
          icon,
          size: 18,
          color: isSelected ? EduverseTheme.onPrimary : EduverseTheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? EduverseTheme.onPrimary : EduverseTheme.onSurface,
          ),
        ),
        onTap: () {
          if (isSelected) return;
          if (route == '/dashboard') {
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          } else {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context, bool isDashboard) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceBright,
        border: Border(
          bottom: BorderSide(
            color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left: Screen Title / Breadcrumbs
          if (!isDashboard) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 20),
          ),
          const SizedBox(width: 16),

          // Live Systems Normal badge (matching Stitch header)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: EduverseTheme.emeraldVivid,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Systems Normal',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EduverseTheme.emeraldVivid,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Center-right: Search input
          Container(
            width: 240,
            height: 38,
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search console...',
                hintStyle: TextStyle(fontSize: 12, color: EduverseTheme.outline),
                prefixIcon: Icon(Icons.search, size: 16, color: EduverseTheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Notifications bell
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 20, color: EduverseTheme.onSurfaceVariant),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: 8),

          // Custom Actions
          ...?actions,

          // Quick Action button
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/course_editor'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduverseTheme.primary,
              foregroundColor: EduverseTheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileNavItem(
    BuildContext context,
    String title,
    String route,
    IconData icon, {
    Key? key,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route || (route == '/dashboard' && currentRoute == '/');

    return ListTile(
      key: key,
      leading: Icon(icon, color: isSelected ? EduverseTheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? EduverseTheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        if (isSelected) return;
        if (route == '/dashboard') {
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        } else {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
