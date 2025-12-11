import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eduverse/study/study_repository.dart';
import 'package:eduverse/study/models/study_models.dart';

class WorkbooksPage extends StatefulWidget {
  const WorkbooksPage({super.key});

  @override
  State<WorkbooksPage> createState() => _WorkbooksPageState();
}

class _WorkbooksPageState extends State<WorkbooksPage> {
  String _selectedFilter = 'All';
  final StudyRepository _repository = StudyRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workbooks')),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Due Soon'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Overdue'),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<WorkbookModel>>(
                stream: _repository.getWorkbooks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No workbooks assigned.'));
                  }

                  final filteredList = _selectedFilter == 'All'
                      ? snapshot.data!
                      : snapshot.data!.where((w) {
                          if (_selectedFilter == 'Due Soon') {
                            final days = w.dueDate.difference(DateTime.now()).inDays;
                            return days >= 0 && days <= 3;
                          } else if (_selectedFilter == 'Overdue') {
                            return w.dueDate.isBefore(DateTime.now()) && w.status != 'Submitted';
                          }
                          return true;
                        }).toList();
                  
                  if (filteredList.isEmpty) {
                     return const Center(child: Text('No workbooks match filter.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getStatusColor(item.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.assignment, color: _getStatusColor(item.status)),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Due: ${DateFormat('MMM d, yyyy').format(item.dueDate)}'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: item.progress,
                                backgroundColor: Colors.grey[200],
                                color: _getStatusColor(item.status),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.status,
                                style: TextStyle(
                                  color: _getStatusColor(item.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            _showWorkbookDetail(context, item);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkbookDetail(BuildContext context, WorkbookModel workbook) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workbook.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...workbook.tasks.map((task) => CheckboxListTile(
              title: Text(task.title),
              value: task.isCompleted,
              onChanged: (val) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated (mock)')));
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedFilter = label),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Theme.of(context).primaryColor,
      side: BorderSide.none,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Submitted': return Colors.green;
      case 'Overdue': return Colors.red;
      case 'In Progress': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
