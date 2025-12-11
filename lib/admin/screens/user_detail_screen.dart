import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  AdminUser? _user;
  bool _isLoading = true;
  String? _error;

  // For manual enrollment
  List<AdminCourse> _courses = [];
  String? _selectedCourseId;
  List<AdminBatch> _batches = [];
  String? _selectedBatchId;
  bool _isEnrolling = false;

  // Stream subscriptions
  StreamSubscription? _coursesSub;
  StreamSubscription? _batchesSub;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCourses();
  }

  @override
  void dispose() {
    _coursesSub?.cancel();
    _batchesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final adminService = context.read<FirebaseAdminService>();
      final user = await adminService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _loadCourses() {
    final adminService = context.read<FirebaseAdminService>();
    _coursesSub?.cancel();
    _coursesSub = adminService.getCourses().listen((courses) {
      if (mounted) {
        setState(() => _courses = courses);
      }
    }, onError: (e) {
      debugPrint('Error loading courses: $e');
    });
  }

  void _loadBatches(String courseId) {
    final adminService = context.read<FirebaseAdminService>();
    _batchesSub?.cancel();
    _batchesSub = adminService.getBatches(courseId).listen((batches) {
      if (mounted) {
        setState(() {
          _batches = batches;
          _selectedBatchId = null;
        });
      }
    }, onError: (e) {
      debugPrint('Error loading batches: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'User Details',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_user == null) {
      return const Center(child: Text('User not found'));
    }

    // Responsive layout
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        
        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - User profile
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      _buildEnrolledCoursesCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - Actions and enrollment
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildActionsCard(),
                      const SizedBox(height: 24),
                      _buildManualEnrollmentCard(),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile/Tablet layout - Single Column
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(),
                const SizedBox(height: 16),
                _buildActionsCard(),
                const SizedBox(height: 16),
                _buildEnrolledCoursesCard(),
                const SizedBox(height: 16),
                _buildManualEnrollmentCard(),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadUser();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getRoleColor(_user!.role).withValues(alpha: 0.2),
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      color: _getRoleColor(_user!.role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.name.isNotEmpty ? _user!.name : 'Unnamed User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildRoleChip(_user!.role),
                          _buildStatusChip(_user!.disabled),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.email, 'Email', _user!.email),
            if (_user!.phone != null && _user!.phone!.isNotEmpty)
              _buildInfoRow(Icons.phone, 'Phone', _user!.phone!),
            _buildInfoRow(Icons.badge, 'User ID', _user!.uid),
            if (_user!.createdAt != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Created',
                DateFormat('MMM d, yyyy h:mm a').format(_user!.createdAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCoursesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Enrolled Courses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_user!.enrolledCourses.length} courses'),
                  backgroundColor: Colors.blue.shade50,
                ),
              ],
            ),
            const Divider(height: 24),
            if (_user!.enrolledCourses.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No enrolled courses',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...(_user!.enrolledCourses.map((enrollmentId) => ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.book),
                    ),
                    title: Text(enrollmentId),
                    subtitle: const Text('Enrolled via Admin/Purchase'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Unenroll User',
                      onPressed: () => _confirmUnenroll(enrollmentId),
                    ),
                  ))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, size: 24),
                SizedBox(width: 8),
                Text(
                  'Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Role dropdown
            const Text('Role', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _user!.role,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) async {
                if (value != null && value != _user!.role) {
                  await _updateRole(value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Status toggle
            const Text('Account Status', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(_user!.disabled ? 'Account Disabled' : 'Account Active'),
              subtitle: Text(
                _user!.disabled 
                    ? 'User cannot access the app' 
                    : 'User has full access',
              ),
              value: !_user!.disabled,
              activeThumbColor: Colors.green,
              contentPadding: EdgeInsets.zero,
              onChanged: (enabled) => _toggleDisabled(!enabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEnrollmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle, size: 24, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Manual Enrollment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Course dropdown
            const Text('Select Course', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a course...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _courses.map((course) {
                return DropdownMenuItem(
                  value: course.id,
                  child: Text(course.title),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCourseId = value);
                if (value != null) {
                  _loadBatches(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Batch dropdown
            const Text('Select Batch', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedBatchId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a batch...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _batches.map((batch) {
                return DropdownMenuItem(
                  value: batch.id,
                  child: Text(batch.name),
                );
              }).toList(),
              onChanged: _selectedCourseId == null 
                  ? null 
                  : (value) => setState(() => _selectedBatchId = value),
            ),
            const SizedBox(height: 24),

            // Enroll button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedCourseId != null && _selectedBatchId != null && !_isEnrolling
                    ? _enrollUser
                    : null,
                icon: _isEnrolling 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_isEnrolling ? 'Enrolling...' : 'Enroll User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'student':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRoleChip(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool disabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: disabled ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled ? Colors.red.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        disabled ? 'DISABLED' : 'ACTIVE',
        style: TextStyle(
          color: disabled ? Colors.red : Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateRole(String newRole) async {
    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.updateUserRole(widget.userId, newRole);
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $newRole')),
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

  Future<void> _toggleDisabled(bool disabled) async {
    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.toggleUserDisabled(widget.userId, disabled);
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disabled ? 'User disabled' : 'User enabled'),
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

  Future<void> _enrollUser() async {
    if (_selectedCourseId == null || _selectedBatchId == null) return;

    setState(() => _isEnrolling = true);

    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.manualEnrollUser(
        widget.userId,
        _selectedCourseId!,
        _selectedBatchId!,
      );
      
      await _loadUser();
      
      if (mounted) {
        setState(() {
          _selectedCourseId = null;
          _selectedBatchId = null;
          _batches = [];
          _isEnrolling = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User enrolled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnrolling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmUnenroll(String enrollmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unenrollment'),
        content: Text('Are you sure you want to remove the user from "$enrollmentId"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _unenrollUser(enrollmentId);
    }
  }

  Future<void> _unenrollUser(String enrollmentId) async {
    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.manualUnenrollUser(widget.userId, enrollmentId);
      
      await _loadUser();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unenrolled successfully'),
            backgroundColor: Colors.green,
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
