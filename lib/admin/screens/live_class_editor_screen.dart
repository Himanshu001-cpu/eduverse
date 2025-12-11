import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/media_uploader.dart';

class LiveClassEditorScreen extends StatefulWidget {
  final AdminLiveClass? liveClass;
  final String? courseId;
  final String? batchId;

  const LiveClassEditorScreen({super.key, this.liveClass, this.courseId, this.batchId});

  @override
  State<LiveClassEditorScreen> createState() => _LiveClassEditorScreenState();
}

class _LiveClassEditorScreenState extends State<LiveClassEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  // late TextEditingController _instructorController; // Removed
  late TextEditingController _youtubeUrlController;
  late TextEditingController _thumbnailUrlController;
  late TextEditingController _durationController;
  
  late DateTime _startTime;
  late String _status;
  
  bool _isSaving = false;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    final item = widget.liveClass;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    // _instructorController = TextEditingController(text: item?.instructorName ?? ''); // Removed
    _youtubeUrlController = TextEditingController(text: item?.youtubeUrl ?? '');
    _thumbnailUrlController = TextEditingController(text: item?.thumbnailUrl ?? '');
    _durationController = TextEditingController(text: item?.durationMinutes.toString() ?? '60');
    
    _startTime = item?.startTime ?? DateTime.now().add(const Duration(hours: 1));
    _status = item?.status ?? 'scheduled';

    if (_youtubeController == null && _youtubeUrlController.text.isNotEmpty) {
      _loadYoutubePreview(_youtubeUrlController.text);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // _instructorController.dispose(); // Removed
    _youtubeUrlController.dispose();
    _thumbnailUrlController.dispose();
    _durationController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _loadYoutubePreview(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null && videoId.isNotEmpty) {
      setState(() {
         _youtubeController?.dispose();
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      });
    } else {
       setState(() => _youtubeController = null);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final id = widget.liveClass?.id ?? const Uuid().v4();
      
      final newItem = AdminLiveClass(
        id: id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructorName: 'Admin', // Default to Admin since field is removed
        startTime: _startTime,
        durationMinutes: int.tryParse(_durationController.text) ?? 60,
        youtubeUrl: _youtubeUrlController.text.trim(),
        thumbnailUrl: _thumbnailUrlController.text.trim(),
        status: _status,
        createdAt: widget.liveClass?.createdAt ?? DateTime.now(),
      );

      if (widget.courseId != null && widget.batchId != null) {
        await context.read<FirebaseAdminService>().saveBatchLiveClass(
          widget.courseId!, 
          widget.batchId!, 
          newItem, 
          isNew: widget.liveClass == null
        );
      } else {
        await context.read<FirebaseAdminService>().saveLiveClass(newItem, isNew: widget.liveClass == null);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live class saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.liveClass == null ? 'Schedule Live Class' : 'Edit Live Class'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: _isSaving 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    /*
                    TextFormField(
                      controller: _instructorController,
                      decoration: const InputDecoration(
                        labelText: 'Instructor Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    */

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDateTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('yyyy-MM-dd HH:mm').format(_startTime)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (min)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(value: 'live', child: Text('Live Now')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _youtubeUrlController,
                      decoration: const InputDecoration(
                        labelText: 'YouTube Video Link',
                        hintText: 'https://youtube.com/watch?v=...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.video_library),
                      ),
                      onChanged: (val) => _loadYoutubePreview(val),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    if (_youtubeController != null)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                        ),
                      ),

                    const SizedBox(height: 16),
                    
                    const Text('Thumbnail', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        if (_thumbnailUrlController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Image.network(
                              _thumbnailUrlController.text,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => const Icon(Icons.error),
                            ),
                          ),
                        Expanded(
                          child: MediaUploader(
                            path: 'live_classes_thumbnails',
                            onUploadComplete: (url) {
                              setState(() => _thumbnailUrlController.text = url);
                            },
                          ),
                        ),
                      ],
                    ),
                     if (_thumbnailUrlController.text.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _thumbnailUrlController.text = ''),
                        child: const Text('Clear Thumbnail', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
