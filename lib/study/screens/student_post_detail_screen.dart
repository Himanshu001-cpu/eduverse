import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/community_models.dart';
import '../data/repositories/community_repository.dart';

class StudentPostDetailScreen extends StatefulWidget {
  final String communityId;
  final StudentPost post;
  final String? currentUserId;

  const StudentPostDetailScreen({
    super.key,
    required this.communityId,
    required this.post,
    this.currentUserId,
  });

  @override
  State<StudentPostDetailScreen> createState() => _StudentPostDetailScreenState();
}

class _StudentPostDetailScreenState extends State<StudentPostDetailScreen> {
  final CommunityRepository _repository = CommunityRepository();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserUid;
  String? _currentUserName;
  String? _currentUserRole;
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
        _currentUserName = data['name'] ?? 'Student';
        _currentUserRole = data['role'] ?? 'student';
      }
    }
  }

  Future<void> _submitReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final isTeacherReply = _currentUserRole == 'teacher' || _currentUserRole == 'admin' || _currentUserRole == 'superadmin';
      
      await _repository.createReply(
        communityId: widget.communityId,
        postId: widget.post.id,
        body: body,
        authorId: _currentUserUid ?? '',
        authorName: _currentUserName ?? 'Student',
        authorRole: _currentUserRole ?? 'student',
        isTeacherReply: isTeacherReply,
      );

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
        title: const Text('Doubt Details'),
      ),
      body: StreamBuilder<StudentPost?>(
        stream: _repository.getPostById(widget.communityId, widget.post.id),
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
                                'Pinned doubt',
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      
                      // Main Post
                      _buildMainPostCard(currentPost),
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Discussion & Replies',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // Replies stream
                      StreamBuilder<List<StudentReply>>(
                        stream: _repository.getRepliesForPost(widget.communityId, currentPost.id),
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
                                  'No replies yet. Ask a question or help out!',
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
              
              // Reply Entry
              _buildReplyInputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainPostCard(StudentPost post) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: post.isAnswered ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: post.isAnswered ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Text(
                    post.isAnswered ? 'Resolved' : 'Unresolved',
                    style: TextStyle(
                      color: post.isAnswered ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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

  Widget _buildReplyCard(StudentReply reply) {
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
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
