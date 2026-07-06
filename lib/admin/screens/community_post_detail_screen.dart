import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final String communityId;
  final CommunityPost post;
  final bool isTeacherOrAdmin;

  const CommunityPostDetailScreen({
    super.key,
    required this.communityId,
    required this.post,
    required this.isTeacherOrAdmin,
  });

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserUid;
  String? _currentUserRole;
  String? _currentUserName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserUid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _currentUserRole = data['role'] ?? 'student';
        _currentUserName = data['name'] ?? 'Admin/Teacher';
      }
    }
  }

  Future<void> _submitReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final isTeacherReply = widget.isTeacherOrAdmin || _currentUserRole == 'teacher';
      
      final reply = CommunityReply(
        id: '',
        postId: widget.post.id,
        authorId: _currentUserUid ?? '',
        authorName: _currentUserName ?? 'Admin/Teacher',
        authorRole: _currentUserRole ?? 'teacher',
        body: body,
        isTeacherReply: isTeacherReply,
        createdAt: DateTime.now(),
      );

      await _communityService.createReply(widget.communityId, widget.post.id, reply);
      _replyController.clear();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: StreamBuilder<CommunityPost?>(
        stream: _communityService.getPostById(widget.communityId, widget.post.id),
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final currentPost = postSnapshot.data ?? widget.post;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pinned banner
                      if (currentPost.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.push_pin, size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'This post is pinned',
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      
                      // Main Post Details
                      _buildMainPostCard(currentPost),
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Replies',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Replies list
                      StreamBuilder<List<CommunityReply>>(
                        stream: _communityService.getRepliesForPost(widget.communityId, currentPost.id),
                        builder: (context, repliesSnapshot) {
                          if (repliesSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final replies = repliesSnapshot.data ?? [];
                          
                          if (replies.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No replies yet. Be the first to reply!',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: replies.length,
                            itemBuilder: (context, index) {
                              final reply = replies[index];
                              return _buildReplyCard(reply);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom reply entry bar
              _buildReplyInputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainPostCard(CommunityPost post) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleChip(post.authorRole),
                        ],
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(post.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (widget.isTeacherOrAdmin) ...[
                  // Mark Answered / Unanswered Toggle
                  IconButton(
                    icon: Icon(
                      post.isAnswered ? Icons.check_circle : Icons.check_circle_outline,
                      color: post.isAnswered ? Colors.green : Colors.grey,
                    ),
                    tooltip: post.isAnswered ? 'Mark Unresolved' : 'Mark Resolved',
                    onPressed: () => _communityService.markPostAnswered(
                      widget.communityId, 
                      post.id, 
                      !post.isAnswered
                    ),
                  ),
                  // Pin / Unpin
                  IconButton(
                    icon: Icon(
                      post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: post.isPinned ? Colors.orange : Colors.grey,
                    ),
                    tooltip: post.isPinned ? 'Unpin Post' : 'Pin Post',
                    onPressed: () => _communityService.pinPost(
                      widget.communityId, 
                      post.id, 
                      !post.isPinned
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Text(
              post.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(CommunityReply reply) {
    final isTeacher = reply.isTeacherReply;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: isTeacher ? theme.colorScheme.primaryContainer.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isTeacher 
              ? theme.colorScheme.primary.withValues(alpha: 0.2) 
              : Colors.grey.shade200,
          width: isTeacher ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isTeacher ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.grey.shade200,
                  child: Text(
                    reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 10,
                      color: isTeacher ? theme.colorScheme.primary : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reply.authorName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          _buildRoleChip(reply.authorRole),
                        ],
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(reply.createdAt),
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (widget.isTeacherOrAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    onPressed: () => _deleteReply(reply.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reply.body,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Write a reply...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: _isSubmitting 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.send, color: Colors.teal),
              onPressed: _isSubmitting ? null : _submitReply,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _deleteReply(String replyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
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
      await _communityService.deleteReply(widget.communityId, widget.post.id, replyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply deleted successfully')),
        );
      }
    }
  }
}
