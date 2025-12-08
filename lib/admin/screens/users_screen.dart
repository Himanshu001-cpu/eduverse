import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_scaffold.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all'; // all, student, admin
  bool _showDisabledOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminUser> _filterUsers(List<AdminUser> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.email.toLowerCase().contains(query) &&
            !user.name.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Role filter
      if (_roleFilter != 'all' && user.role != _roleFilter) {
        return false;
      }

      // Disabled filter
      if (_showDisabledOnly && !user.disabled) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.read<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Users',
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
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
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
                  ],
                  onChanged: (value) {
                    setState(() => _roleFilter = value!);
                  },
                ),
                const SizedBox(width: 16),

                // Disabled filter
                FilterChip(
                  label: const Text('Disabled Only'),
                  selected: _showDisabledOnly,
                  onSelected: (selected) {
                    setState(() => _showDisabledOnly = selected);
                  },
                ),
              ],
            ),
          ),

          // Users table
          Expanded(
            child: StreamBuilder<List<AdminUser>>(
              stream: adminService.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text('Error loading users: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];
                final users = _filterUsers(allUsers);

                if (users.isEmpty) {
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
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                      rows: users.map((user) {
                        return DataRow(
                          onSelectChanged: (_) => _navigateToDetail(user),
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
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
                            DataCell(_buildRoleChip(user.role)),
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
                                      PopupMenuItem(
                                        value: user.role == 'admin' ? 'make_student' : 'make_admin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              user.role == 'admin' ? Icons.person : Icons.admin_panel_settings,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(user.role == 'admin' ? 'Make Student' : 'Make Admin'),
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
                );
              },
            ),
          ),
        ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
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
        color: disabled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
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
