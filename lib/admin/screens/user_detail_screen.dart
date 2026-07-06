import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_scaffold.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../services/test_series_service.dart';
import '../models/test_series_models.dart';
import '../widgets/student_performance_tab.dart';


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
  bool _isEnrolling = false;

  // For manual test series enrollment
  List<AdminTestSeries> _allTestSeries = [];
  String? _selectedTestSeriesId;
  bool _isEnrollingTS = false;

  // Current logged in admin info (for teacher scoping check)
  String? _currentAdminRole;
  List<TeacherSubject> _currentAdminTeacherSubjects = [];
  bool _isLoadingAdminInfo = true;

  // Stream subscriptions
  StreamSubscription? _coursesSub;
  StreamSubscription? _testSeriesSub;

  // For teacher subjects assignment
  final TextEditingController _subjectController = TextEditingController();
  String? _assignCourseId;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _loadUser();
    _loadCourses();
    _loadTestSeries();
  }

  @override
  void dispose() {
    _coursesSub?.cancel();
    _testSeriesSub?.cancel();
    _subjectController.dispose();
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

  Future<void> _loadAdminInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _currentAdminRole = data['role'] ?? 'student';
            final subjectsRaw = data['teacherSubjects'] as List<dynamic>?;
            _currentAdminTeacherSubjects = subjectsRaw
                ?.map((e) => TeacherSubject.fromMap(Map<String, dynamic>.from(e)))
                .toList() ?? [];
            _isLoadingAdminInfo = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading admin info: $e');
      if (mounted) {
        setState(() {
          _isLoadingAdminInfo = false;
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

  void _loadTestSeries() {
    final tsService = TestSeriesService();
    _testSeriesSub?.cancel();
    _testSeriesSub = tsService.getTestSeriesList().listen((tsList) {
      if (mounted) {
        setState(() => _allTestSeries = tsList);
      }
    }, onError: (e) {
      debugPrint('Error loading test series: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentAdminRole == 'admin' || _currentAdminRole == 'superadmin';
    final isTeacher = _currentAdminRole == 'teacher';

    bool showPerformanceTab = false;
    if (_user != null) {
      if (isAdmin) {
        showPerformanceTab = true;
      } else if (isTeacher) {
        final teacherCourseIds = _currentAdminTeacherSubjects.expand((ts) => ts.courseIds).toSet();
        final studentCourseIds = _user!.enrolledCourses.toSet();
        showPerformanceTab = teacherCourseIds.intersection(studentCourseIds).isNotEmpty;
      }
    }

    if (showPerformanceTab) {
      return DefaultTabController(
        length: 2,
        child: AdminScaffold(
          title: 'User Details',
          body: _buildBody(showPerformance: true),
        ),
      );
    }

    return AdminScaffold(
      title: 'User Details',
      body: _buildBody(showPerformance: false),
    );
  }

  Widget _buildBody({required bool showPerformance}) {
    if (_isLoading || _isLoadingAdminInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_user == null) {
      return const Center(child: Text('User not found'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!showPerformance) {
          return _buildProfileContent(constraints);
        }

        return Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Profile'),
                Tab(icon: Icon(Icons.analytics), text: 'Performance'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildProfileContent(constraints),
                  StudentPerformanceTab(
                    userId: widget.userId,
                    purchasedTestSeriesIds: _user!.purchasedTestSeries,
                    allTestSeries: _allTestSeries,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileContent(BoxConstraints constraints) {
    final isWide = constraints.maxWidth > 900;
    final isTeacherUser = _user!.role == 'teacher' || _user!.isTeacher;

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
                  if (isTeacherUser || _user!.role == 'admin' || _user!.role == 'superadmin') ...[
                    const SizedBox(height: 24),
                    _buildTeacherProfileCard(),
                  ],
                  const SizedBox(height: 24),
                  _buildEnrolledCoursesCard(),
                  const SizedBox(height: 24),
                  _buildEnrolledTestSeriesCard(),
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
                  const SizedBox(height: 24),
                  _buildManualTSEnrollmentCard(),
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
            if (isTeacherUser || _user!.role == 'admin' || _user!.role == 'superadmin') ...[
              const SizedBox(height: 16),
              _buildTeacherProfileCard(),
            ],
            const SizedBox(height: 16),
            _buildEnrolledCoursesCard(),
            const SizedBox(height: 16),
            _buildManualEnrollmentCard(),
            const SizedBox(height: 16),
            _buildEnrolledTestSeriesCard(),
            const SizedBox(height: 16),
            _buildManualTSEnrollmentCard(),
          ],
        ),
      );
    }
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
                          if (_user!.isTeacher && _user!.role != 'teacher')
                            _buildRoleChip('teacher'),
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

  // Helper method to get enrollment display info
  Map<String, String> _getEnrollmentInfo(String enrollmentId) {
    final course = _courses.firstWhere(
      (c) => c.id == enrollmentId,
      orElse: () => AdminCourse(
        id: enrollmentId,
        title: enrollmentId, // Fallback to ID if not found
        slug: '',
        subtitle: '',
        description: '',
        tags: [],
        language: 'en',
        level: 'beginner',
        thumbnailUrl: '',
        gradientColors: [],
        visibility: 'draft',
        createdAt: DateTime.now(),
      ),
    );
    
    return {
      'courseName': course.title,
      'courseId': course.id,
    };
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
              ...(_user!.enrolledCourses.map((enrollmentId) {
                final info = _getEnrollmentInfo(enrollmentId);
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.book),
                  ),
                  title: Text(info['courseName'] ?? enrollmentId),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Unenroll User',
                    onPressed: () => _confirmUnenroll(enrollmentId),
                  ),
                );
              })),
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
              initialValue: (_user!.role == 'superadmin') ? 'admin' : _user!.role,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'student', child: Text('Student')),
                const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                if (_user!.role != 'admin' && _user!.role != 'superadmin')
                  const DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
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
              },
            ),
            const SizedBox(height: 24),
 
            // Enroll button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedCourseId != null && !_isEnrolling
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

  Widget _buildEnrolledTestSeriesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, size: 24, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Enrolled Test Series',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_user!.purchasedTestSeries.length} series'),
                  backgroundColor: Colors.teal.shade50,
                ),
              ],
            ),
            const Divider(height: 24),
            if (_user!.purchasedTestSeries.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No enrolled test series',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...(_user!.purchasedTestSeries.map((tsId) {
                // Resolve title from loaded test series list
                final ts = _allTestSeries.cast<AdminTestSeries?>().firstWhere(
                  (t) => t!.id == tsId,
                  orElse: () => null,
                );
                final title = ts?.title ?? tsId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.15),
                    child: const Icon(Icons.assignment, color: Colors.teal),
                  ),
                  title: Text(title),
                  subtitle: Text('ID: $tsId', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Unenroll from Test Series',
                    onPressed: () => _confirmUnenrollTS(tsId, title),
                  ),
                );
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTSEnrollmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle, size: 24, color: Colors.teal),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Manual Test Series Enrollment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Select Test Series', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedTestSeriesId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a test series...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _allTestSeries.map((ts) {
                return DropdownMenuItem(
                  value: ts.id,
                  child: Text(ts.title),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTestSeriesId = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedTestSeriesId != null && !_isEnrollingTS
                    ? _enrollTestSeries
                    : null,
                icon: _isEnrollingTS
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_isEnrollingTS ? 'Enrolling...' : 'Enroll in Test Series'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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
      case 'superadmin':
        return Colors.purple;
      case 'teacher':
        return Colors.teal;
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
    if (_selectedCourseId == null) return;

    setState(() => _isEnrolling = true);

    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.manualEnrollUser(
        widget.userId,
        _selectedCourseId!,
      );
      
      await _loadUser();
      
      if (mounted) {
        setState(() {
          _selectedCourseId = null;
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
    final info = _getEnrollmentInfo(enrollmentId);
    final courseName = info['courseName'] ?? enrollmentId;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unenrollment'),
        content: Text('Are you sure you want to remove the user from "$courseName"?\nThis action cannot be undone.'),
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

  Future<void> _enrollTestSeries() async {
    if (_selectedTestSeriesId == null) return;

    setState(() => _isEnrollingTS = true);

    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.manualEnrollTestSeries(
        widget.userId,
        _selectedTestSeriesId!,
      );

      await _loadUser();

      if (mounted) {
        setState(() {
          _selectedTestSeriesId = null;
          _isEnrollingTS = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User enrolled in test series successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnrollingTS = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmUnenrollTS(String tsId, String tsTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unenrollment'),
        content: Text('Are you sure you want to remove the user from "$tsTitle"?\nThis action cannot be undone.'),
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
      await _unenrollTestSeries(tsId);
    }
  }

  Future<void> _unenrollTestSeries(String tsId) async {
    try {
      final adminService = context.read<FirebaseAdminService>();
      await adminService.manualUnenrollTestSeries(widget.userId, tsId);

      await _loadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unenrolled from test series successfully!'),
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

  Widget _buildTeacherProfileCard() {
    final isTeacherUser = _user!.role == 'teacher' || _user!.isTeacher;
    final adminService = context.read<FirebaseAdminService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, size: 24, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Teacher Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            
            if (_user!.role == 'admin' || _user!.role == 'superadmin') ...[
              SwitchListTile(
                title: const Text('Mark as Teacher'),
                subtitle: const Text('Allow this admin to teach and manage communities'),
                value: _user!.isTeacher,
                activeThumbColor: Colors.teal,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) async {
                  try {
                    await adminService.setTeacherFlag(_user!.uid, val);
                    await _loadUser();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? 'Marked as teacher' : 'Removed teacher flag')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 24),
            ],

            if (isTeacherUser) ...[
              const Text(
                'Assigned Subjects & Courses',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (_user!.teacherSubjects.isEmpty)
                Text(
                  'Not assigned to any courses or subjects yet.',
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _user!.teacherSubjects.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final ts = _user!.teacherSubjects[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ts.subjectName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: ts.courseIds.map((courseId) {
                            final courseTitle = _courses.firstWhere(
                              (c) => c.id == courseId,
                              orElse: () => AdminCourse(
                                id: courseId,
                                title: courseId,
                                slug: '',
                                subtitle: '',
                                description: '',
                                tags: [],
                                language: 'en',
                                level: 'beginner',
                                thumbnailUrl: '',
                                gradientColors: [],
                                visibility: 'draft',
                                createdAt: DateTime.now(),
                              ),
                            ).title;
                            return Chip(
                              label: Text(courseTitle),
                              onDeleted: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Assignment'),
                                    content: Text('Are you sure you want to remove this teacher from "$courseTitle" for subject "${ts.subjectName}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  try {
                                    await adminService.removeTeacherFromCourse(
                                      courseId,
                                      _user!.uid,
                                      ts.subjectName,
                                    );
                                    await _loadUser();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Assignment removed successfully')),
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
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              const Divider(height: 24),
              _buildAddAssignmentForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddAssignmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign new Course & Subject',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _assignCourseId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select Course',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _courses.map((course) {
            return DropdownMenuItem(
              value: course.id,
              child: Text(course.title),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _assignCourseId = val);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Subject Name (e.g. Mathematics)',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _assignCourseId != null && !_isAssigning
                ? () async {
                    final subjectName = _subjectController.text.trim();
                    if (subjectName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a subject name'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    setState(() => _isAssigning = true);
                    try {
                      final adminService = context.read<FirebaseAdminService>();
                      await adminService.assignTeacherToCourse(
                        _assignCourseId!,
                        _user!.uid,
                        _user!.name,
                        subjectName,
                      );
                      _subjectController.clear();
                      setState(() {
                        _assignCourseId = null;
                        _isAssigning = false;
                      });
                      await _loadUser();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Teacher assigned successfully'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      setState(() => _isAssigning = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Assign Teacher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
