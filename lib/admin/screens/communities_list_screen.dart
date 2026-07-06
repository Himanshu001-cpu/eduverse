import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_scaffold.dart';
import '../services/community_service.dart';
import '../models/community_models.dart';
import 'community_posts_screen.dart';

class CommunitiesListScreen extends StatefulWidget {
  const CommunitiesListScreen({super.key});

  @override
  State<CommunitiesListScreen> createState() => _CommunitiesListScreenState();
}

class _CommunitiesListScreenState extends State<CommunitiesListScreen> {
  final CommunityService _communityService = CommunityService();
  String? _currentUserUid;
  String? _currentUserRole;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserUid = user.uid;
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _currentUserRole = data['role'] ?? 'student';
        }
      }
    } catch (e) {
      debugPrint('Error loading current user role: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Stream<List<Community>> _getCommunitiesStream() {
    // Admins see all communities, teachers only see their own
    if (_currentUserRole == 'admin' || _currentUserRole == 'superadmin') {
      return _communityService.getCommunities();
    } else {
      return _communityService.getCommunitiesForTeacher(_currentUserUid ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const AdminScaffold(
        title: 'Communities',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = _currentUserRole == 'admin' || _currentUserRole == 'superadmin';

    return AdminScaffold(
      title: 'Communities',
      body: StreamBuilder<List<Community>>(
        stream: _getCommunitiesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading communities: ${snapshot.error}'));
          }

          final communities = snapshot.data ?? [];

          if (communities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    isAdmin 
                        ? 'No communities created yet.\nAssign a teacher to a course to auto-create communities.'
                        : 'You have not been assigned to any communities yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 3
                  : constraints.maxWidth > 800
                      ? 2
                      : 1;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return _buildCommunityCard(community, isAdmin);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(Community community, bool isAdmin) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: community.isActive 
              ? colorScheme.tealContainer.withValues(alpha: 0.2) 
              : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityPostsScreen(community: community),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Color Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: community.isActive
                      ? [Colors.teal.shade700, Colors.teal.shade500]
                      : [Colors.grey.shade700, Colors.grey.shade500],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      community.subjectName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      community.isActive ? 'ACTIVE' : 'INACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher: ${community.teacherName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        community.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatIcon(Icons.forum, '${community.postCount} posts'),
                        const SizedBox(width: 16),
                        _buildStatIcon(Icons.book, '${community.courseIds.length} courses'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isAdmin || community.teacherId == _currentUserUid) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit Description',
                      onPressed: () => _showEditDescriptionDialog(community),
                    ),
                    IconButton(
                      icon: Icon(
                        community.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: community.isActive ? Colors.orange : Colors.green,
                      ),
                      tooltip: community.isActive ? 'Deactivate' : 'Activate',
                      onPressed: () => _toggleCommunityStatus(community),
                    ),
                  ],
                  const TextButton(
                    onPressed: null, // Tap handler is on the parent card InkWell
                    child: Text('View Posts →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDescriptionDialog(Community community) async {
    final controller = TextEditingController(text: community.description);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Community Description - ${community.subjectName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _communityService.updateCommunityDescription(
                  community.id,
                  controller.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description updated successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCommunityStatus(Community community) async {
    try {
      await _communityService.toggleCommunityActiveStatus(
        community.id,
        !community.isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Community ${community.isActive ? 'deactivated' : 'activated'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

extension ColorSchemeExtension on ColorScheme {
  Color get tealContainer => Colors.teal.shade50;
}
