import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';

class CoursesListScreen extends StatelessWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    
    return AdminScaffold(
      title: 'Courses',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/course_editor'),
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
      body: StreamBuilder<List<AdminCourse>>(
        stream: service.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final courses = snapshot.data!;
          
          // Separate courses by visibility
          final draftCourses = courses.where((c) => c.visibility == 'draft').toList();
          final publishedCourses = courses.where((c) => c.visibility == 'published').toList();
          final archivedCourses = courses.where((c) => c.visibility == 'archived').toList();
          
          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No courses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to create your first course'),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Published Courses Section
                if (publishedCourses.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Published',
                    publishedCourses.length,
                    Colors.green,
                    Icons.public,
                  ),
                  const SizedBox(height: 8),
                  ...publishedCourses.map((course) => _CourseCard(
                    course: course,
                    service: service,
                  )),
                  const SizedBox(height: 24),
                ],
                
                // Draft Courses Section
                if (draftCourses.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Drafts',
                    draftCourses.length,
                    Colors.orange,
                    Icons.edit_note,
                  ),
                  const SizedBox(height: 8),
                  ...draftCourses.map((course) => _CourseCard(
                    course: course,
                    service: service,
                  )),
                  const SizedBox(height: 24),
                ],
                
                // Archived Courses Section
                if (archivedCourses.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Archived',
                    archivedCourses.length,
                    Colors.grey,
                    Icons.archive,
                  ),
                  const SizedBox(height: 8),
                  ...archivedCourses.map((course) => _CourseCard(
                    course: course,
                    service: service,
                    isArchived: true,
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final AdminCourse course;
  final FirebaseAdminService service;
  final bool isArchived;

  const _CourseCard({
    required this.course,
    required this.service,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: course.thumbnailUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  course.thumbnailUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildEmojiPlaceholder(),
                ),
              )
            : _buildEmojiPlaceholder(),
        title: Text(
          course.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isArchived ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            _buildVisibilityBadge(),
            const SizedBox(width: 8),
            Text(
              course.language.toUpperCase(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Text(
              course.level,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!isArchived)
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive, color: Colors.orange),
                  title: Text('Archive'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/course_editor', arguments: course),
      ),
    );
  }

  Widget _buildEmojiPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: course.gradientColors.isNotEmpty
              ? course.gradientColors.map((c) => Color(c)).toList()
              : [Colors.blue, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          course.emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge() {
    Color color;
    String text;
    
    switch (course.visibility) {
      case 'published':
        color = Colors.green;
        text = 'PUBLISHED';
        break;
      case 'archived':
        color = Colors.grey;
        text = 'ARCHIVED';
        break;
      default:
        color = Colors.orange;
        text = 'DRAFT';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(context, '/course_editor', arguments: course);
        break;
        
      case 'archive':
        final confirm = await _showConfirmDialog(
          context,
          title: 'Archive Course',
          content: 'Are you sure you want to archive "${course.title}"?\n\nArchived courses can be restored by editing them.',
          confirmText: 'Archive',
          confirmColor: Colors.orange,
        );
        
        if (confirm == true) {
          await service.archiveCourse(course.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Course archived')),
            );
          }
        }
        break;
        
      case 'delete':
        final confirm = await _showConfirmDialog(
          context,
          title: 'Delete Course Permanently',
          content: 'Are you sure you want to PERMANENTLY delete "${course.title}"?\n\n⚠️ This action cannot be undone!\n\nAll batches, lessons, notes, quizzes, and other data associated with this course will be deleted.',
          confirmText: 'Delete Forever',
          confirmColor: Colors.red,
          isDangerous: true,
        );
        
        if (confirm == true) {
          try {
            await service.permanentlyDeleteCourse(course.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course permanently deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting course: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            if (isDangerous) ...[
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
