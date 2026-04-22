import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import 'batch_quiz_list_screen.dart';
import '../widgets/admin_scaffold.dart';

class BatchDetailScreen extends StatefulWidget {
  final String courseId;
  final AdminBatch batch;

  const BatchDetailScreen({super.key, required this.courseId, required this.batch});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;

  // Enrolled students state
  List<AdminUser> _enrolledUsers = [];
  List<AdminUser> _filteredUsers = [];
  bool _isLoadingEnrollments = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.batch.name);
    _priceController = TextEditingController(text: widget.batch.price.toString());
    _seatsController = TextEditingController(text: widget.batch.seatsTotal.toString());
    _startDate = widget.batch.startDate;
    _endDate = widget.batch.endDate;
    _isActive = widget.batch.isActive;
    _loadEnrolledUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledUsers() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final users = await service.getEnrolledUsersForBatch(
        widget.courseId,
        widget.batch.id,
      );
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

  Future<void> _saveBatch() async {
    final service = context.read<FirebaseAdminService>();
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final seats = int.tryParse(_seatsController.text) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name required')));
      return;
    }

    final updatedBatch = AdminBatch(
      id: widget.batch.id,
      courseId: widget.courseId,
      name: name,
      startDate: _startDate,
      endDate: _endDate,
      price: price,
      seatsTotal: seats,
      seatsLeft: widget.batch.seatsLeft,
      isActive: _isActive,
    );

    try {
      await service.saveBatch(widget.courseId, updatedBatch, isNew: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Batch: ${widget.batch.name}',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resource Management Section
            const Text('Manage Resources', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    arguments: {'courseId': widget.courseId, 'batchId': widget.batch.id},
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
                        courseId: widget.courseId,
                        batchId: widget.batch.id,
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
                    '/batch_notes',
                    arguments: {'courseId': widget.courseId, 'batchId': widget.batch.id},
                  ),
                ),
                _ResourceCard(
                  icon: Icons.calendar_month,
                  title: 'Planner',
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/batch_planner',
                    arguments: {'courseId': widget.courseId, 'batchId': widget.batch.id},
                  ),
                ),
                _ResourceCard(
                  icon: Icons.video_call,
                  title: 'Scheduler',
                  color: Colors.red,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/live_classes',
                    arguments: {
                      'courseId': widget.courseId,
                      'batchId': widget.batch.id,
                    }
                  ),
                ),
                _ResourceCard(
                  icon: Icons.assignment,
                  title: 'DPP',
                  color: Colors.deepPurple,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/batch_dpps',
                    arguments: {'courseId': widget.courseId, 'batchId': widget.batch.id},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Enrolled Students Section
            _buildEnrolledStudentsSection(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Batch Details Editing
            const Text('Batch Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Batch Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ ', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Seats', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context, 
                        initialDate: _startDate, 
                        firstDate: DateTime(2020), 
                        lastDate: DateTime(2030)
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                       final d = await showDatePicker(
                        context: context, 
                        initialDate: _endDate, 
                        firstDate: DateTime(2020), 
                        lastDate: DateTime(2030)
                      );
                      if (d != null) setState(() => _endDate = d);
                    },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Active (Visible for purchase)'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBatch,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Save Batch Details'),
              ),
            ),
          ],
        ),
      ),
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
            Text(
              'Enrolled Students',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            // Refresh button
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
