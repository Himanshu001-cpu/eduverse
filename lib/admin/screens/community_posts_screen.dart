import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import 'community_post_detail_screen.dart';

class CommunityPostsScreen extends StatefulWidget {
  final Community community;

  const CommunityPostsScreen({super.key, required this.community});

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final CommunityService _communityService = CommunityService();
  String _filter = 'all'; // all, unanswered, pinned
  String? _currentUserUid;
  String? _currentUserRole;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserUid = user.uid;
      // Get role and name
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentUserRole = data['role'] ?? 'student';
        _currentUserName = data['name'] ?? 'Admin/Teacher';
      }
    }
  }

  List<CommunityPost> _filterPosts(List<CommunityPost> posts) {
    switch (_filter) {
      case 'unanswered':
        return posts.where((p) => !p.isAnswered).toList();
      case 'pinned':
        return posts.where((p) => p.isPinned).toList();
      default:
        return posts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.community.teacherId == _currentUserUid;
    final isAdmin = _currentUserRole == 'admin' || _currentUserRole == 'superadmin';
    final canPostAnnouncement = isTeacher || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.community.subjectName} Community'),
        actions: [
          if (canPostAnnouncement)
            TextButton.icon(
              onPressed: _showCreateAnnouncementDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Announcement', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('all', 'All Posts', Icons.list),
                _buildFilterTab('unanswered', 'Unanswered', Icons.help_outline),
                _buildFilterTab('pinned', 'Pinned', Icons.push_pin),
              ],
            ),
          ),
          
          // Posts Stream
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _communityService.getPostsForCommunity(widget.community.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading posts: ${snapshot.error}'));
                }

                final allPosts = snapshot.data ?? [];
                final posts = _filterPosts(allPosts);

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No doubts or posts found here.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post, isTeacher || isAdmin);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filterType, String label, IconData icon) {
    final isSelected = _filter == filterType;
    final color = isSelected ? Colors.teal.shade700 : Colors.grey.shade600;

    return InkWell(
      onTap: () => setState(() => _filter = filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.teal.shade700 : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, bool canModerate) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityPostDetailScreen(
                communityId: widget.community.id,
                post: post,
                isTeacherOrAdmin: canModerate,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleChip(post.authorRole),
                          ],
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(post.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    Icon(Icons.push_pin, size: 18, color: Colors.orange.shade700),
                ],
              ),
              const SizedBox(height: 12),
              
              // Post Title & Body
              Text(
                post.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                post.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // Footer Stats and Moderation
              Row(
                children: [
                  Icon(Icons.check_circle_outline, 
                    size: 16, 
                    color: post.isAnswered ? Colors.green : Colors.grey.shade500
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.isAnswered ? 'Resolved' : 'Unresolved',
                    style: TextStyle(
                      fontSize: 12, 
                      color: post.isAnswered ? Colors.green : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${post.replyCount} replies',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (canModerate) ...[
                    IconButton(
                      icon: Icon(
                        post.isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                        size: 18,
                        color: post.isPinned ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () => _communityService.pinPost(
                        widget.community.id, 
                        post.id, 
                        !post.isPinned
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _confirmDeletePost(post.id),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role) {
      case 'admin':
      case 'superadmin':
        color = Colors.purple;
        break;
      case 'teacher':
        color = Colors.teal;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showCreateAnnouncementDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Announcement'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Announcement Message',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter message body' : null,
              ),
            ],
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
                final newPost = CommunityPost(
                  id: '',
                  communityId: widget.community.id,
                  authorId: _currentUserUid ?? '',
                  authorName: _currentUserName ?? 'Admin/Teacher',
                  authorRole: _currentUserRole ?? 'teacher',
                  title: titleController.text.trim(),
                  body: bodyController.text.trim(),
                  isPinned: true, // Announcements pinned by default
                  isAnswered: true, // No doubt to answer
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                
                await _communityService.createPost(widget.community.id, newPost);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement posted successfully!')),
                  );
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to permanently delete this post and all its replies?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _communityService.deletePost(widget.community.id, postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    }
  }
}
