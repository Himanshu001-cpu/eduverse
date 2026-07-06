import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/community_models.dart';
import '../data/repositories/community_repository.dart';
import 'student_post_detail_screen.dart';

class StudentCommunityScreen extends StatefulWidget {
  final StudentCommunity community;

  const StudentCommunityScreen({super.key, required this.community});

  @override
  State<StudentCommunityScreen> createState() => _StudentCommunityScreenState();
}

class _StudentCommunityScreenState extends State<StudentCommunityScreen> {
  final CommunityRepository _repository = CommunityRepository();
  String _filter = 'all'; // all, unresolved, mine
  String? _currentUserUid;
  String? _currentUserName;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserUid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentUserName = data['name'] ?? 'Student';
        _currentUserRole = data['role'] ?? 'student';
      }
    }
  }

  List<StudentPost> _filterPosts(List<StudentPost> posts) {
    switch (_filter) {
      case 'unresolved':
        return posts.where((p) => !p.isAnswered).toList();
      case 'mine':
        return posts.where((p) => p.authorId == _currentUserUid).toList();
      default:
        return posts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.community.subjectName} Community'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('all', 'All', Icons.list),
                _buildFilterTab('unresolved', 'Unresolved', Icons.help_outline),
                _buildFilterTab('mine', 'My Doubts', Icons.person_outline),
              ],
            ),
          ),
          
          // Posts Stream
          Expanded(
            child: StreamBuilder<List<StudentPost>>(
              stream: _repository.getPostsForCommunity(widget.community.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                          'No doubts or posts found.',
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
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildFilterTab(String filterType, String label, IconData icon) {
    final isSelected = _filter == filterType;
    final color = isSelected ? Colors.teal.shade700 : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = filterType),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.teal.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildPostCard(StudentPost post) {
    final isOwnPost = post.authorId == _currentUserUid;

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
              builder: (context) => StudentPostDetailScreen(
                communityId: widget.community.id,
                post: post,
                currentUserId: _currentUserUid,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
              
              // Title & Body
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
              
              // Footer
              Row(
                children: [
                  Icon(
                    post.isAnswered ? Icons.check_circle : Icons.check_circle_outline, 
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
                  if (isOwnPost)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _confirmDeletePost(post.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    if (role == 'student') return const SizedBox.shrink();
    
    Color color = role == 'teacher' ? Colors.teal : Colors.purple;

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

  Future<void> _showCreatePostDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask a Doubt'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Topic/Title',
                  hintText: 'e.g. Question from Lecture 3',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe your doubt...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please describe your doubt' : null,
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
                await _repository.createPost(
                  communityId: widget.community.id,
                  title: titleController.text.trim(),
                  body: bodyController.text.trim(),
                  authorId: _currentUserUid ?? '',
                  authorName: _currentUserName ?? 'Student',
                  authorRole: _currentUserRole ?? 'student',
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doubt posted successfully!')),
                  );
                }
              }
            },
            child: const Text('Post Doubt'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doubt'),
        content: const Text('Are you sure you want to delete your doubt? This will delete all replies too.'),
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
      await _repository.deleteOwnPost(widget.community.id, postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doubt deleted successfully')),
        );
      }
    }
  }
}
