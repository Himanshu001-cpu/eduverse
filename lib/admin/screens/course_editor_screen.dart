import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../utils/validators.dart';

class CourseEditorScreen extends StatefulWidget {
  final AdminCourse? course;
  const CourseEditorScreen({Key? key, this.course}) : super(key: key);

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title, _slug, _description;
  
  @override
  void initState() {
    super.initState();
    _title = widget.course?.title ?? '';
    _slug = widget.course?.slug ?? '';
    _description = widget.course?.description ?? '';
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newCourse = AdminCourse(
        id: widget.course?.id ?? '',
        title: _title,
        slug: _slug,
        subtitle: '',
        description: _description,
        tags: [],
        language: 'en',
        level: 'beginner',
        thumbnailUrl: '',
        coverGradient: [],
        visibility: 'draft',
        createdAt: widget.course?.createdAt ?? DateTime.now(),
      );
      
      await context.read<FirebaseAdminService>().saveCourse(newCourse, isNew: widget.course == null);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.course == null ? 'New Course' : 'Edit Course',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: Validators.required,
                onSaved: (v) => _title = v!,
              ),
              TextFormField(
                initialValue: _slug,
                decoration: const InputDecoration(labelText: 'Slug'),
                validator: Validators.required,
                onSaved: (v) => _slug = v!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 20),
              if (widget.course != null)
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/batch_editor', arguments: widget.course!.id),
                  child: const Text('Manage Batches'),
                ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Save Course')),
            ],
          ),
        ),
      ),
    );
  }
}
