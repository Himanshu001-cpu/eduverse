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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.batch.name);
    _priceController = TextEditingController(text: widget.batch.price.toString());
    _seatsController = TextEditingController(text: widget.batch.seatsTotal.toString());
    _startDate = widget.batch.startDate;
    _endDate = widget.batch.endDate;
    _isActive = widget.batch.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
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
      seatsLeft: widget.batch.seatsLeft, // Don't change seats left manually usually
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
              ],
            ),
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
