import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduverse/admin/widgets/admin_scaffold.dart';
import 'package:eduverse/admin/widgets/thumbnail_upload_widget.dart';
import 'package:eduverse/admin/models/admin_models.dart';
import 'package:eduverse/admin/services/firebase_admin_service.dart';
import 'package:eduverse/store/models/poster_model.dart';
import 'package:eduverse/core/notifications/notification_model.dart';
import 'package:eduverse/core/notifications/notification_repository.dart';

class PosterEditorScreen extends StatefulWidget {
  final Poster? poster;

  const PosterEditorScreen({super.key, this.poster});

  @override
  State<PosterEditorScreen> createState() => _PosterEditorScreenState();
}

class _PosterEditorScreenState extends State<PosterEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _externalUrlController = TextEditingController();
  final TextEditingController _orderController = TextEditingController(text: '0');

  String _aspectRatio = '16:9';
  String? _thumbnailUrl;
  bool _isActive = true;
  bool _sendNotification = false;
  bool _isSaving = false;

  // In-app deep link selection state
  NotificationTargetType? _inAppTargetType;
  String? _selectedLinkCourseId;
  String? _selectedLinkLectureId;
  String? _selectedLinkFeedItemId;
  String? _selectedLinkLiveClassId;
  String? _inAppTargetId;

  // Interactive buttons list
  final List<PosterButton> _buttons = [];

  @override
  void initState() {
    super.initState();
    if (widget.poster != null) {
      final p = widget.poster!;
      _titleController.text = p.title;
      _subtitleController.text = p.subtitle;
      _externalUrlController.text = p.externalUrl ?? '';
      _orderController.text = p.order.toString();
      _aspectRatio = p.aspectRatio;
      _thumbnailUrl = p.thumbnailUrl;
      _isActive = p.isActive;
      _sendNotification = p.sendNotification;
      
      if (p.inAppTargetType != null) {
        _inAppTargetType = NotificationTargetType.values.firstWhere(
          (e) => e.name == p.inAppTargetType,
          orElse: () => NotificationTargetType.course,
        );
        _inAppTargetId = p.inAppTargetId;

        // Populate dynamic link selections
        if (_inAppTargetType == NotificationTargetType.course || _inAppTargetType == NotificationTargetType.batch) {
          _selectedLinkCourseId = p.inAppTargetId;
        } else if (_inAppTargetType == NotificationTargetType.lecture) {
          _selectedLinkLectureId = p.inAppTargetId;
        } else if (_inAppTargetType == NotificationTargetType.feedItem || _inAppTargetType == NotificationTargetType.quiz) {
          _selectedLinkFeedItemId = p.inAppTargetId;
        } else if (_inAppTargetType == NotificationTargetType.liveClass) {
          _selectedLinkLiveClassId = p.inAppTargetId;
        }
      }

      _buttons.addAll(p.buttons);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _externalUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _savePoster() async {
    if (!_formKey.currentState!.validate()) return;

    if (_thumbnailUrl == null || _thumbnailUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a poster image thumbnail'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final subtitle = _subtitleController.text.trim();
      final externalUrl = _externalUrlController.text.trim().isNotEmpty ? _externalUrlController.text.trim() : null;
      final order = int.tryParse(_orderController.text.trim()) ?? 0;

      final data = {
        'title': title,
        'subtitle': subtitle,
        'thumbnailUrl': _thumbnailUrl,
        'aspectRatio': _aspectRatio,
        'externalUrl': externalUrl,
        'inAppTargetType': _inAppTargetType?.name,
        'inAppTargetId': _inAppTargetId,
        'inAppRoute': _generateInAppRoute(_inAppTargetType, _inAppTargetId),
        'buttons': _buttons.map((b) => b.toMap()).toList(),
        'sendNotification': _sendNotification,
        'isActive': _isActive,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.poster == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance.collection('posters').add(data);

        // Send notification optionally
        if (_sendNotification) {
          await _broadcastNotification(title, subtitle, docRef.id);
        }
      } else {
        await FirebaseFirestore.instance.collection('posters').doc(widget.poster!.id).update(data);

        if (_sendNotification) {
          await _broadcastNotification(title, subtitle, widget.poster!.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poster saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save poster: $e'), backgroundColor: Colors.red),
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

  String? _generateInAppRoute(NotificationTargetType? type, String? id) {
    if (type == null || id == null || id.isEmpty) return null;
    switch (type) {
      case NotificationTargetType.course:
        return '/app/course/$id';
      case NotificationTargetType.batch:
        return '/app/batch/$id'; // Legacy fallback
      case NotificationTargetType.feedItem:
        return '/app/feed/$id';
      default:
        return null;
    }
  }

  Future<void> _broadcastNotification(String title, String body, String posterId) async {
    final notificationRepo = NotificationRepository();
    // Default to feed target redirect pointing to the new poster promotion, or simple course deep link
    await notificationRepo.createGlobalNotification(
      title: title,
      body: body.isNotEmpty ? body : 'Tap to check out our new promo poster!',
      targetType: _inAppTargetType ?? NotificationTargetType.course,
      targetId: _inAppTargetId ?? '',
      imageUrl: _thumbnailUrl,
    );
  }

  void _addButton() {
    String label = '';
    String actionType = 'External';
    String? tempExternalUrl;
    NotificationTargetType? tempInAppTargetType;
    String? tempInAppTargetId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add Interactive Button'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Button Label * (e.g. Enroll Now)'),
                      onChanged: (val) => label = val,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: actionType,
                      decoration: const InputDecoration(labelText: 'Action Type'),
                      items: const [
                        DropdownMenuItem(value: 'External', child: Text('External App/URL')),
                        DropdownMenuItem(value: 'InApp', child: Text('In-App Redirect')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            actionType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (actionType == 'External')
                      TextField(
                        decoration: const InputDecoration(labelText: 'External URL (http/https)'),
                        onChanged: (val) => tempExternalUrl = val,
                      )
                    else ...[
                      DropdownButtonFormField<NotificationTargetType>(
                        initialValue: tempInAppTargetType,
                        decoration: const InputDecoration(labelText: 'In-App Target Screen'),
                        items: NotificationTargetType.values.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type.name));
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            tempInAppTargetType = val;
                            tempInAppTargetId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (tempInAppTargetType != null)
                        _buildModalTargetItemSelector(tempInAppTargetType!, (itemId) {
                          tempInAppTargetId = itemId;
                        }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (label.trim().isEmpty) return;
                    Navigator.pop(
                      context,
                      PosterButton(
                        label: label.trim(),
                        externalUrl: actionType == 'External' ? tempExternalUrl : null,
                        inAppTargetType: actionType == 'InApp' ? tempInAppTargetType?.name : null,
                        inAppTargetId: actionType == 'InApp' ? tempInAppTargetId : null,
                        inAppRoute: actionType == 'InApp' ? _generateInAppRoute(tempInAppTargetType, tempInAppTargetId) : null,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    ).then((button) {
      if (button != null && button is PosterButton) {
        setState(() {
          _buttons.add(button);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminService = context.watch<FirebaseAdminService>();

    return AdminScaffold(
      title: widget.poster == null ? 'Create Poster' : 'Edit Poster',
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
                    widget.poster == null ? 'Create New Promo Poster' : 'Edit Promo Poster',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Promote courses, events, or external websites in the main store hero slider.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Aspect Ratio Selection
                  const Text('Poster Aspect Ratio *', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: ['16:9', '4:3', '1:1', '9:16'].map((ratio) {
                      final isSelected = _aspectRatio == ratio;
                      return ChoiceChip(
                        label: Text(ratio),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _aspectRatio = ratio;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Image Upload
                  ThumbnailUploadWidget(
                    currentUrl: _thumbnailUrl,
                    storagePath: 'posters/thumbnails',
                    height: _aspectRatio == '9:16' ? 240 : 150,
                    width: _aspectRatio == '1:1' ? 150 : (_aspectRatio == '9:16' ? 135 : 266),
                    onUploaded: (url) {
                      setState(() {
                        _thumbnailUrl = url;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Title Input
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Poster Heading Title *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Heading title is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subtitle Input
                  TextFormField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Poster Description Subtitle (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.subtitles),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Order Input
                  TextFormField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Display Order Weight',
                      helperText: 'Smaller numbers display first (e.g. 0, 1, 2)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Navigation Link Section
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
                          const Text('Primary Poster Tap Link Action (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          
                          // External Link
                          TextFormField(
                            controller: _externalUrlController,
                            decoration: const InputDecoration(
                              labelText: 'External URL (e.g. https://google.com)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(child: Text('- OR -', style: TextStyle(color: Colors.grey))),
                          const SizedBox(height: 16),

                          // In-App Link Target Screen
                          DropdownButtonFormField<NotificationTargetType>(
                            initialValue: _inAppTargetType,
                            decoration: const InputDecoration(
                              labelText: 'In-App Redirect Screen Target',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.screen_share_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('No In-App Route (None)')),
                              ...NotificationTargetType.values.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type.name));
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _inAppTargetType = val;
                                _selectedLinkCourseId = null;
                                _selectedLinkLectureId = null;
                                _selectedLinkFeedItemId = null;
                                _selectedLinkLiveClassId = null;
                                _inAppTargetId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Target Selector
                          if (_inAppTargetType != null) ...[
                            _buildTargetItemSelector(adminService),
                            const SizedBox(height: 16),
                            Text(
                              'Selected target document ID: ${_inAppTargetId ?? "None"}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interactive Buttons Builder
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
                              const Text('Interactive CTA Buttons', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: _addButton,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Button'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_buttons.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No interactive buttons added yet. Entire poster card will be clickable.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _buttons.length,
                              itemBuilder: (context, idx) {
                                final btn = _buttons[idx];
                                return ListTile(
                                  leading: const Icon(Icons.smart_button),
                                  title: Text(btn.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    btn.externalUrl != null
                                        ? 'Link: ${btn.externalUrl}'
                                        : 'Redirect: ${btn.inAppTargetType ?? "App"} (${btn.inAppTargetId ?? ""})',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _buttons.removeAt(idx);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggles
                  SwitchListTile(
                    title: const Text('Active Status'),
                    subtitle: const Text('Inactive posters are hidden from the store tab slider.'),
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Send Push Notification?'),
                    subtitle: const Text('Sends a global push alert to all students with this promotion details when saved.'),
                    value: _sendNotification,
                    onChanged: (val) {
                      setState(() {
                        _sendNotification = val;
                      });
                    },
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
                        onPressed: _savePoster,
                        icon: const Icon(Icons.save),
                        label: const Text('Save & Publish Poster'),
                        style: FilledButton.styleFrom(
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
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Saving and publishing poster promotion...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetItemSelector(FirebaseAdminService adminService) {
    if (_inAppTargetType == null) return const SizedBox.shrink();
    switch (_inAppTargetType!) {
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
        final courses = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkCourseId,
          decoration: const InputDecoration(labelText: 'Select Course', border: OutlineInputBorder()),
          items: courses.map((course) {
            return DropdownMenuItem(value: course.id, child: Text(course.title));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkCourseId = val;
              _selectedLinkLectureId = null;
              if ((_inAppTargetType == NotificationTargetType.course || _inAppTargetType == NotificationTargetType.batch)) {
                _inAppTargetId = val;
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
        final lectures = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkLectureId,
          decoration: const InputDecoration(labelText: 'Select Lecture', border: OutlineInputBorder()),
          items: lectures.map((lecture) {
            return DropdownMenuItem(value: lecture.id, child: Text('[${lecture.type.toUpperCase()}] ${lecture.title}'));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkLectureId = val;
              if (_inAppTargetType == NotificationTargetType.lecture) {
                _inAppTargetId = val;
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
        final docs = snapshot.data?.docs ?? [];
        var filteredDocs = docs;
        if (_inAppTargetType == NotificationTargetType.quiz) {
          filteredDocs = docs.where((doc) => doc.data()['type'] == 'quizzes').toList();
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkFeedItemId,
          decoration: InputDecoration(
            labelText: _inAppTargetType == NotificationTargetType.quiz ? 'Select Quiz' : 'Select Feed Item',
            border: const OutlineInputBorder(),
          ),
          items: filteredDocs.map((doc) {
            final data = doc.data();
            final title = data['title'] ?? 'Untitled';
            return DropdownMenuItem(value: doc.id, child: Text(title));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkFeedItemId = val;
              _inAppTargetId = val;
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
        final docs = snapshot.data?.docs ?? [];
        return DropdownButtonFormField<String>(
          initialValue: _selectedLinkLiveClassId,
          decoration: const InputDecoration(labelText: 'Select Live Class', border: OutlineInputBorder()),
          items: docs.map((doc) {
            final data = doc.data();
            final title = data['title'] ?? 'Untitled';
            return DropdownMenuItem(value: doc.id, child: Text(title));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedLinkLiveClassId = val;
              _inAppTargetId = val;
            });
          },
        );
      },
    );
  }

  // --- Modal version ofselectors for the interactive CTA buttons dialog ---
  Widget _buildModalTargetItemSelector(NotificationTargetType type, ValueChanged<String?> onSelected) {
    switch (type) {
      case NotificationTargetType.course:
      case NotificationTargetType.batch:
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('courses').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final docs = snapshot.data?.docs ?? [];
            return DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Course'),
              items: docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.data()['title'] ?? ''))).toList(),
              onChanged: onSelected,
            );
          },
        );
      case NotificationTargetType.feedItem:
      case NotificationTargetType.quiz:
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('feed').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final docs = snapshot.data?.docs ?? [];
            return DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Feed Item'),
              items: docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.data()['title'] ?? ''))).toList(),
              onChanged: onSelected,
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
