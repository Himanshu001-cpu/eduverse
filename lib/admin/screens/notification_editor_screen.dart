import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';

class NotificationEditorScreen extends StatefulWidget {
  const NotificationEditorScreen({super.key});

  @override
  State<NotificationEditorScreen> createState() => _NotificationEditorScreenState();
}

class _NotificationEditorScreenState extends State<NotificationEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final NotificationRepository _repository = NotificationRepository();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _targetIdController = TextEditingController();

  NotificationType _notificationType = NotificationType.feed;
  NotificationTargetType _targetType = NotificationTargetType.feedItem;

  // Image Upload state
  bool _isUploadingImage = false;
  String? _imageUrl;

  // Selected Courses state
  // Each entry is a map of {'courseId': '...', 'courseTitle': '...'}
  final List<Map<String, String>> _selectedCourses = [];

  bool _isSaving = false;

  // Deep Link Document Autofill state
  String? _selectedLinkCourseId;
  String? _selectedLinkLectureId;
  String? _selectedLinkFeedItemId;
  String? _selectedLinkLiveClassId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        var bytes = file.bytes;
        if (bytes == null && file.path != null) {
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        if (bytes != null) {
          // Upload to Firebase Storage
          final adminService = context.read<FirebaseAdminService>();
          final storagePath = 'notifications/images/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          
          // Determine Content Type
          String contentType = 'image/jpeg';
          if (file.name.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          } else if (file.name.toLowerCase().endsWith('.gif')) {
            contentType = 'image/gif';
          } else if (file.name.toLowerCase().endsWith('.webp')) {
            contentType = 'image/webp';
          }

          final downloadUrl = await adminService.uploadMedia(
            storagePath,
            bytes,
            contentType,
          );

          setState(() {
            _imageUrl = downloadUrl;
          });
        } else {
          throw 'Could not read file data. bytes is null.';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
    });
  }

  void _toggleCourseSelection(Map<String, String> courseInfo, bool selected) {
    setState(() {
      if (selected) {
        // Prevent duplicates
        final exists = _selectedCourses.any((c) => c['courseId'] == courseInfo['courseId']);
        if (!exists) {
          _selectedCourses.add(courseInfo);
        }
      } else {
        _selectedCourses.removeWhere((c) => c['courseId'] == courseInfo['courseId']);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_notificationType == NotificationType.batch && _selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one course for course-wise notifications'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final targetId = _targetIdController.text.trim();

      if (_notificationType == NotificationType.feed) {
        // 1. Create a Global Notification
        await _repository.createGlobalNotification(
          title: title,
          body: body,
          targetType: _targetType,
          targetId: targetId,
          imageUrl: _imageUrl,
          courseId: _selectedLinkCourseId,
        );
      } else {
        // 2. Create Course-Wise Notifications
        await _repository.createMultipleCourseNotifications(
          title: title,
          body: body,
          targetType: _targetType,
          targetId: targetId,
          targetCourses: _selectedCourses.map((c) => c['courseId']!).toList(),
          imageUrl: _imageUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate notification: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminService = context.watch<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Create Notification',
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate New Notification',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send manual push alerts and feed updates to students globally or target specific courses.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Title Input
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title *',
                      helperText: 'A catchy title (e.g. "Live Session starting in 10 mins!")',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLength: 80,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Body Input
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message Body *',
                      helperText: 'Enter the main notification body text.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLength: 250,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Message body is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Image Upload Section
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rich Image Banner (Optional)',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (_imageUrl != null)
                                TextButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isUploadingImage)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text('Uploading image to Firebase Storage...'),
                                  ],
                                ),
                              ),
                            )
                          else if (_imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(_imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.teal.shade700),
                                    const SizedBox(height: 8),
                                    Text('Click to pick and upload banner image', style: TextStyle(color: Colors.teal.shade800)),
                                    const SizedBox(height: 4),
                                    Text('Supports JPEG, PNG, WEBP (Max 2MB)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Target Audience Selector
                  DropdownButtonFormField<NotificationType>(
                    initialValue: _notificationType,
                    decoration: const InputDecoration(
                      labelText: 'Target Audience *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: NotificationType.feed,
                        child: Text('Global (All Students)'),
                      ),
                      DropdownMenuItem(
                        value: NotificationType.batch,
                        child: Text('Course-Wise (Enrolled Students Only)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _notificationType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Multi-course Selector (Visible only for Course-Wise notifications)
                  if (_notificationType == NotificationType.batch) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Select Targeted Courses *',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_selectedCourses.length} Courses Selected',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Share this notification across multiple courses simultaneously.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            _buildMultiCourseSelector(adminService),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Deep Link Targeting / Navigation Redirect
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deep Link Navigation Redirect (Optional)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Specify what screen will open when a student taps the notification.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<NotificationTargetType>(
                            initialValue: _targetType,
                            decoration: const InputDecoration(
                              labelText: 'Redirect Target Screen',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.screen_share_outlined),
                            ),
                            items: NotificationTargetType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _targetType = val;
                                  _selectedLinkCourseId = null;
                                  _selectedLinkLectureId = null;
                                  _selectedLinkFeedItemId = null;
                                  _selectedLinkLiveClassId = null;
                                  _targetIdController.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          // Dynamic Autofill Selectors
                          _buildDynamicLinkSelectors(adminService),
                          const SizedBox(height: 16),
                          // Read-only Target ID Indicator
                          TextFormField(
                            controller: _targetIdController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Auto-populated Target ID',
                              helperText: 'Automatically populated based on the selection above',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.key_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Generate & Broadcast'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 16),
                        Text('Broadcasting notifications to students...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildMultiCourseSelector(FirebaseAdminService adminService) {
    return StreamBuilder<List<AdminCourse>>(
      stream: adminService.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Text('Failed to load courses: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return const Text('No courses available to target.');
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final isChecked = _selectedCourses.any((c) => c['courseId'] == course.id);
              return CheckboxListTile(
                title: Text(course.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('ID: ${course.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                value: isChecked,
                dense: true,
                activeColor: Colors.teal,
                onChanged: (bool? val) {
                  if (val != null) {
                    _toggleCourseSelection({
                      'courseId': course.id,
                      'courseTitle': course.title,
                    }, val);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  // ============ DYNAMIC DEEP LINK AUTOFill WIDGETS ============

  Widget _buildDynamicLinkSelectors(FirebaseAdminService adminService) {
    switch (_targetType) {
      case NotificationTargetType.course:
      case NotificationTargetType.batch:
        return _buildCourseSelector(adminService);
      case NotificationTargetType.lecture:
        return Column(
          children: [
            _buildCourseSelector(adminService),
            if (_selectedLinkCourseId != null) ...[
              const SizedBox(height: 16),
              _buildLectureSelector(adminService, _selectedLinkCourseId!),
            ],
          ],
        );
      case NotificationTargetType.feedItem:
      case NotificationTargetType.quiz:
        return _buildFeedItemSelector();
      case NotificationTargetType.liveClass:
        return _buildLiveClassSelector();
    }
  }

  Widget _buildCourseSelector(FirebaseAdminService adminService) {
    return StreamBuilder<List<AdminCourse>>(
      stream: adminService.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Text('Failed to load courses: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        final courses = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkCourseId,
          decoration: const InputDecoration(
            labelText: 'Select Course',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school_outlined),
          ),
          items: courses.map((course) {
            return DropdownMenuItem(
              value: course.id,
              child: Text(course.title),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkCourseId = val;
              _selectedLinkLectureId = null;
              if ((_targetType == NotificationTargetType.course || _targetType == NotificationTargetType.batch) && val != null) {
                _targetIdController.text = val;
              } else {
                _targetIdController.clear();
              }
            });
          },
        );
      },
    );
  }

  Widget _buildLectureSelector(FirebaseAdminService adminService, String courseId) {
    return StreamBuilder<List<AdminLecture>>(
      stream: adminService.getLectures(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Text('Failed to load lectures: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        final lectures = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkLectureId,
          decoration: const InputDecoration(
            labelText: 'Select Lecture',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.auto_stories_outlined),
          ),
          items: lectures.map((lecture) {
            return DropdownMenuItem(
              value: lecture.id,
              child: Text('[${lecture.type.toUpperCase()}] ${lecture.title}'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkLectureId = val;
              if (_targetType == NotificationTargetType.lecture && val != null) {
                _targetIdController.text = val;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildFeedItemSelector() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('feed').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Text('Failed to load feed items: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        final docs = snapshot.data?.docs ?? [];
        var filteredDocs = docs;
        if (_targetType == NotificationTargetType.quiz) {
          filteredDocs = docs.where((doc) => doc.data()['type'] == 'quizzes').toList();
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkFeedItemId,
          decoration: InputDecoration(
            labelText: _targetType == NotificationTargetType.quiz ? 'Select Quiz' : 'Select Feed Item',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.article_outlined),
          ),
          items: filteredDocs.map((doc) {
            final data = doc.data();
            final title = data['title'] ?? 'Untitled';
            final type = data['type'] ?? 'article';
            return DropdownMenuItem(
              value: doc.id,
              child: Text('[$type] $title'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkFeedItemId = val;
              if (val != null) {
                _targetIdController.text = val;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildLiveClassSelector() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('free_live_classes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (snapshot.hasError) {
          return Text('Failed to load live classes: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        final docs = snapshot.data?.docs ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkLiveClassId,
          decoration: const InputDecoration(
            labelText: 'Select Live Class',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.live_tv_outlined),
          ),
          items: docs.map((doc) {
            final data = doc.data();
            final title = data['title'] ?? 'Untitled';
            final instructor = data['instructorName'] ?? 'Unknown';
            return DropdownMenuItem(
              value: doc.id,
              child: Text('$title (by $instructor)'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkLiveClassId = val;
              if (val != null) {
                _targetIdController.text = val;
              }
            });
          },
        );
      },
    );
  }
}
