import 'package:flutter/material.dart';
import 'widgets/profile_header.dart';
import 'widgets/version_card.dart';
import 'widgets/menu_grid.dart';
import 'widgets/stats_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use SafeArea so the purple header doesn't clash with status bar on some phones
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            ProfileHeader(),
            SizedBox(height: 16),
            VersionCard(),
            SizedBox(height: 16),
            MenuGrid(),
            SizedBox(height: 24),
            StatsSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
