import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import 'batch_quiz_list_screen.dart';
import '../widgets/admin_scaffold.dart';

class CourseDetailScreen extends StatefulWidget {
  final AdminCourse course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<AdminUser> _enrolledUsers = [];
  List<AdminUser> _filteredUsers = [];
  bool _isLoadingEnrollments = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnrolledUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledUsers() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final users = await service.getEnrolledUsersForCourse(widget.course.id);
      if (mounted) {
        setState(() {
          _enrolledUsers = users;
          _filteredUsers = users;
          _isLoadingEnrollments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEnrollments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enrollments: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _enrolledUsers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _enrolledUsers.where((user) {
          return user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery) ||
              (user.phone ?? '').contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final startColor = widget.course.gradientColors.isNotEmpty
        ? Color(widget.course.gradientColors[0])
        : Colors.blue;
    final endColor = widget.course.gradientColors.length >= 2
        ? Color(widget.course.gradientColors[1])
        : Colors.blueAccent;

    return AdminScaffold(
      title: 'Course: ${widget.course.title}',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Course Details',
          onPressed: () async {
            await Navigator.pushNamed(
              context,
              '/course_editor',
              arguments: widget.course,
            );
            _loadEnrolledUsers();
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [startColor, endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: startColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.course.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.course.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Resource Management Section
            const Text(
              'Manage Content',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ResourceCard(
                  icon: Icons.video_library,
                  title: 'Lectures',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/lecture_editor',
                    arguments: {'courseId': widget.course.id, 'batchId': ''},
                  ),
                ),
                _ResourceCard(
                  icon: Icons.assignment,
                  title: 'Quizzes',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BatchQuizListScreen(
                        courseId: widget.course.id,
                        batchId: '',
                      ),
                    ),
                  ),
                ),
                _ResourceCard(
                  icon: Icons.description,
                  title: 'Notes',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/lecture_editor',
                    arguments: {
                      'courseId': widget.course.id,
                      'batchId': '',
                      'initialResourceType': 'note',
                    },
                  ),
                ),
                _ResourceCard(
                  icon: Icons.calendar_month,
                  title: 'Planner',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/batch_planner',
                    arguments: {'courseId': widget.course.id, 'batchId': ''},
                  ),
                ),
                _ResourceCard(
                  icon: Icons.video_call,
                  title: 'Live Scheduler',
                  color: Colors.red,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/course_schedule_dashboard',
                    arguments: {
                      'courseId': widget.course.id,
                      'batchId': '',
                    },
                  ),
                ),
                _ResourceCard(
                  icon: Icons.assignment,
                  title: 'DPP',
                  color: Colors.deepPurple,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/lecture_editor',
                    arguments: {
                      'courseId': widget.course.id,
                      'batchId': '',
                      'initialResourceType': 'dpp',
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

             // Assigned Teachers Section
            _buildAssignedTeachersSection(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Enrolled Students Section
            _buildEnrolledStudentsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedTeachersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.school, color: Colors.teal, size: 28),
            SizedBox(width: 8),
            Text(
              'Assigned Teachers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.course.teachers.isEmpty)
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No teachers assigned to this course yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.course.teachers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final teacher = widget.course.teachers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    child: Text(
                      teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    teacher.name.isNotEmpty ? teacher.name : 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Subject: ${teacher.subject}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/user_detail', arguments: teacher.uid);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEnrolledStudentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Row(
          children: [
            const Icon(Icons.people, color: Colors.teal, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Enrolled Students',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (!_isLoadingEnrollments)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${_enrolledUsers.length}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.teal),
              tooltip: 'Refresh',
              onPressed: () {
                setState(() => _isLoadingEnrollments = true);
                _loadEnrolledUsers();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingEnrollments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_enrolledUsers.isEmpty)
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No students enrolled yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterUsers('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterUsers,
          ),
          const SizedBox(height: 12),

          // Results count when filtering
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Showing ${_filteredUsers.length} of ${_enrolledUsers.length} students',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),

          // Student list
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name.isNotEmpty ? user.name : 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.email.isNotEmpty)
                        Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      if (user.phone != null && user.phone!.isNotEmpty)
                        Text(user.phone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/user_detail', arguments: user.uid);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
