import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  final String initialRole;

  const UsersScreen({
    super.key,
    this.initialRole = 'all',
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  late String _roleFilter; // all, student, admin, teacher
  bool _showDisabledOnly = false;

  List<AdminUser> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _roleFilter = widget.initialRole;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialUsers();
    });
  }

  @override
  void didUpdateWidget(UsersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRole != oldWidget.initialRole) {
      setState(() {
        _roleFilter = widget.initialRole;
      });
      _resetAndReload();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadInitialUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastDocument = null;
    });

    try {
      final adminService = context.read<FirebaseAdminService>();
      final result = await adminService.getUsersPaginated(
        limit: 20,
        roleFilter: _roleFilter,
        showDisabledOnly: _showDisabledOnly,
        searchQuery: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _users = result.items;
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore || _isLoading || !mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final adminService = context.read<FirebaseAdminService>();
      final result = await adminService.getUsersPaginated(
        limit: 20,
        startAfter: _lastDocument,
        roleFilter: _roleFilter,
        showDisabledOnly: _showDisabledOnly,
        searchQuery: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(result.items);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more users: $e')),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
      });
      _resetAndReload();
    });
  }

  void _resetAndReload() {
    _lastDocument = null;
    _hasMore = true;
    _loadInitialUsers();
  }

  String _getPageTitle() {
    switch (_roleFilter) {
      case 'student':
        return 'Students';
      case 'teacher':
        return 'Teachers & Faculty';
      case 'admin':
        return 'Administrators';
      default:
        return 'Users & Aspirants';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: _getPageTitle(),
      body: Column(
        children: [
          // Search and filters bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                // Search field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _debounceTimer?.cancel();
                                setState(() => _searchQuery = '');
                                _resetAndReload();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),

                // Role filter dropdown
                DropdownButton<String>(
                  value: _roleFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Roles')),
                    DropdownMenuItem(value: 'student', child: Text('Students')),
                    DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teachers')),
                  ],
                  onChanged: (value) {
                    if (value != null && value != _roleFilter) {
                      setState(() => _roleFilter = value);
                      _resetAndReload();
                    }
                  },
                ),
                const SizedBox(width: 16),

                // Disabled filter
                FilterChip(
                  label: const Text('Disabled Only'),
                  selected: _showDisabledOnly,
                  onSelected: (selected) {
                    setState(() => _showDisabledOnly = selected);
                    _resetAndReload();
                  },
                ),
              ],
            ),
          ),

          // Users table area
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Error loading users: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetAndReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _roleFilter != 'all' || _showDisabledOnly
                  ? 'No users match your filters'
                  : 'No users found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              columns: const [
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Enrolled', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Created', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _users.map((user) {
                return DataRow(
                  onSelectChanged: (_) => _navigateToDetail(user),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(user.name.isNotEmpty ? user.name : 'Unnamed'),
                        ],
                      ),
                    ),
                    DataCell(Text(user.email)),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        children: [
                          _buildRoleChip(user.role),
                          if (user.isTeacher && user.role != 'teacher')
                            _buildRoleChip('teacher'),
                        ],
                      ),
                    ),
                    DataCell(_buildStatusChip(user.disabled)),
                    DataCell(Text('${user.enrolledCourses.length}')),
                    DataCell(Text(
                      user.createdAt != null
                          ? DateFormat('MMM d, yyyy').format(user.createdAt!)
                          : '-',
                    )),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Details',
                            onPressed: () => _navigateToDetail(user),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (action) => _handleAction(action, user),
                            itemBuilder: (context) => [
                              if (user.role != 'student')
                                const PopupMenuItem(
                                  value: 'make_student',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 20),
                                      SizedBox(width: 8),
                                      Text('Make Student'),
                                    ],
                                  ),
                                ),
                              if (user.role != 'admin' && user.role != 'superadmin')
                                const PopupMenuItem(
                                  value: 'make_admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 20),
                                      SizedBox(width: 8),
                                      Text('Make Admin'),
                                    ],
                                  ),
                                ),
                              if (!user.isTeacher)
                                const PopupMenuItem(
                                  value: 'make_teacher',
                                  child: Row(
                                    children: [
                                      Icon(Icons.school, size: 20),
                                      SizedBox(width: 8),
                                      Text('Make Teacher'),
                                    ],
                                  ),
                                ),
                              if (user.isTeacher)
                                const PopupMenuItem(
                                  value: 'remove_teacher',
                                  child: Row(
                                    children: [
                                      Icon(Icons.school_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text('Remove Teacher'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: user.disabled ? 'enable' : 'disable',
                                child: Row(
                                  children: [
                                    Icon(
                                      user.disabled ? Icons.check_circle : Icons.block,
                                      size: 20,
                                      color: user.disabled ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(user.disabled ? 'Enable User' : 'Disable User'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Load More'),
                  onPressed: _loadMoreUsers,
                ),
              ),
            ),
        ],
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

  void _navigateToDetail(AdminUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(userId: user.uid),
      ),
    );
  }

  Future<void> _handleAction(String action, AdminUser user) async {
    final adminService = context.read<FirebaseAdminService>();

    try {
      switch (action) {
        case 'make_admin':
          await adminService.updateUserRole(user.uid, 'admin');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.name} is now an admin')),
            );
          }
          break;
        case 'make_teacher':
          await adminService.setTeacherFlag(user.uid, true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.name} is now a teacher')),
            );
          }
          break;
        case 'remove_teacher':
          await adminService.setTeacherFlag(user.uid, false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.name} is no longer a teacher')),
            );
          }
          break;
        case 'make_student':
          await adminService.updateUserRole(user.uid, 'student');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.name} is now a student')),
            );
          }
          break;
        case 'enable':
          await adminService.toggleUserDisabled(user.uid, false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.name} has been enabled')),
            );
          }
          break;
        case 'disable':
          await adminService.toggleUserDisabled(user.uid, true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.name} has been disabled')),
            );
          }
          break;
      }
      _resetAndReload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
