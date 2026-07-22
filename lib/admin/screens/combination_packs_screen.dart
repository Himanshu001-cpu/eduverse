import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../services/test_series_service.dart';
import '../models/admin_models.dart';
import '../models/test_series_models.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/thumbnail_upload_widget.dart';

class CombinationPacksScreen extends StatefulWidget {
  const CombinationPacksScreen({super.key});

  @override
  State<CombinationPacksScreen> createState() => _CombinationPacksScreenState();
}

class _CombinationPacksScreenState extends State<CombinationPacksScreen> {
  final _testService = TestSeriesService();

  @override
  Widget build(BuildContext context) {
    final adminService = context.read<FirebaseAdminService>();

    return AdminScaffold(
      title: 'Combination Packs',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditPackDialog(context, adminService, null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Bundle Pack', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<List<AdminCombinationPack>>(
        stream: adminService.getCombinationPacks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching combination packs: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final packs = snapshot.data!;

          if (packs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Combination Packs yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap "Create Bundle Pack" to start bundling courses and test series!'),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              return _buildPackCard(context, adminService, pack);
            },
          );
        },
      ),
    );
  }

  Widget _buildPackCard(BuildContext context, FirebaseAdminService service, AdminCombinationPack pack) {
    final discountPercent = pack.realPrice > 0
        ? (((pack.realPrice - pack.finalPrice) / pack.realPrice) * 100).round()
        : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / Status Header
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade700, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: pack.thumbnailUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(pack.thumbnailUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: pack.thumbnailUrl.isEmpty
                    ? const Center(child: Icon(Icons.card_giftcard, size: 48, color: Colors.white70))
                    : null,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pack.isActive ? Colors.green.shade800 : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pack.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (discountPercent > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$discountPercent% OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // Info Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pack.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.layers, size: 14, color: Colors.indigo.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${pack.courses.length} Courses',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.quiz, size: 14, color: Colors.purple.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${pack.testSeries.length} Test Series',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${pack.finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(width: 6),
                          if (pack.realPrice > pack.finalPrice)
                            Text(
                              '₹${pack.realPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                            onPressed: () => _showEditPackDialog(context, service, pack),
                            tooltip: 'Edit Bundle',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _showDeleteConfirmation(context, service, pack),
                            tooltip: 'Delete Bundle',
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FirebaseAdminService service, AdminCombinationPack pack) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Combination Pack?'),
        content: Text('Are you sure you want to delete "${pack.title}"?\n\nThis will remove this bundle listing from the store. Existing student enrollments will NOT be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await service.deleteCombinationPack(pack.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPackDialog(BuildContext context, FirebaseAdminService service, AdminCombinationPack? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    String thumbnailUrl = existing?.thumbnailUrl ?? '';
    final realPriceController = TextEditingController(text: existing?.realPrice.toStringAsFixed(0) ?? '0');
    final finalPriceController = TextEditingController(text: existing?.finalPrice.toStringAsFixed(0) ?? '0');
    bool isActive = existing?.isActive ?? true;

    // List of courses currently selected: { 'courseId': '...', 'courseTitle': '...' }
    // We will dynamically fetch names of course list.
    List<String> selectedCourses = List<String>.from(existing?.courses ?? []);
    List<String> selectedTestSeries = List<String>.from(existing?.testSeries ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Create Combination Pack' : 'Edit Combination Pack'),
          content: SizedBox(
            width: 600,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Bundle Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ThumbnailUploadWidget(
                    currentUrl: thumbnailUrl,
                    storagePath: 'combination_packs/thumbnails',
                    onUploaded: (url) {
                      setStateDialog(() {
                        thumbnailUrl = url;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: realPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Real Price (₹)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: finalPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sale Price (₹)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Is Active in Store?'),
                    value: isActive,
                    onChanged: (val) => setStateDialog(() => isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  // Bundled Courses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bundled Courses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Course'),
                        onPressed: () => _showAddCoursePicker(context, service, selectedCourses, (newSelected) {
                          setStateDialog(() {
                            selectedCourses = newSelected;
                          });
                        }),
                      )
                    ],
                  ),
                  if (selectedCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No courses bundled yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    )
                  else
                    StreamBuilder<List<AdminCourse>>(
                      stream: service.getCourses(),
                      builder: (context, coursesSnap) {
                        final courses = coursesSnap.data ?? [];
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedCourses.map((id) {
                            final course = courses.firstWhere((c) => c.id == id,
                                orElse: () => AdminCourse(
                                      id: id,
                                      title: id,
                                      slug: '',
                                      subtitle: '',
                                      description: '',
                                      tags: const [],
                                      language: 'en',
                                      level: 'beginner',
                                      thumbnailUrl: '',
                                      gradientColors: const [],
                                      visibility: 'draft',
                                      createdAt: DateTime.now(),
                                    ));
                            return Chip(
                              backgroundColor: Colors.indigo.shade50,
                              side: BorderSide(color: Colors.indigo.shade200),
                              label: Text('${course.emoji} ${course.title}', style: TextStyle(fontSize: 12, color: Colors.indigo.shade900)),
                              onDeleted: () => setStateDialog(() => selectedCourses.remove(id)),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Bundled Test Series Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bundled Test Series', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Select Test Series'),
                        onPressed: () => _showTestSeriesPicker(context, selectedTestSeries, (newSelected) {
                          setStateDialog(() {
                            selectedTestSeries = newSelected;
                          });
                        }),
                      )
                    ],
                  ),
                  if (selectedTestSeries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No test series bundled yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    )
                  else
                    StreamBuilder<List<AdminTestSeries>>(
                      stream: _testService.getTestSeriesList(),
                      builder: (context, tsSnap) {
                        final tsList = tsSnap.data ?? [];
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedTestSeries.map((id) {
                            final tsItem = tsList.firstWhere((element) => element.id == id,
                                orElse: () => AdminTestSeries(
                                      id: id,
                                      title: id,
                                      description: '',
                                      emoji: '📝',
                                      gradientColors: [],
                                      visibility: 'published',
                                      subject: '',
                                      totalTests: 0,
                                      linkedCourses: [],
                                      createdAt: DateTime.now(),
                                    ));
                            return Chip(
                              backgroundColor: Colors.purple.shade50,
                              side: BorderSide(color: Colors.purple.shade200),
                              label: Text('${tsItem.emoji} ${tsItem.title}', style: TextStyle(fontSize: 12, color: Colors.purple.shade900)),
                              onDeleted: () => setStateDialog(() => selectedTestSeries.remove(id)),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final desc = descController.text.trim();
                if (title.isEmpty) return;

                final pack = AdminCombinationPack(
                  id: existing?.id ?? '',
                  title: title,
                  description: desc,
                  thumbnailUrl: thumbnailUrl,
                  realPrice: double.tryParse(realPriceController.text) ?? 0.0,
                  finalPrice: double.tryParse(finalPriceController.text) ?? 0.0,
                  courses: selectedCourses,
                  testSeries: selectedTestSeries,
                  isActive: isActive,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );

                await service.saveCombinationPack(pack, isNew: existing == null);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Bundle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCoursePicker(
    BuildContext context,
    FirebaseAdminService service,
    List<String> currentSelected,
    void Function(List<String> newSelected) onSaved,
  ) {
    List<String> tempSelected = List<String>.from(currentSelected);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateCourse) => AlertDialog(
          title: const Text('Select Courses'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: StreamBuilder<List<AdminCourse>>(
              stream: service.getCourses(),
              builder: (context, coursesSnap) {
                if (!coursesSnap.hasData) return const Center(child: CircularProgressIndicator());
                final courses = coursesSnap.data!;

                if (courses.isEmpty) {
                  return const Center(child: Text('No courses available.'));
                }

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final c = courses[index];
                    final isChecked = tempSelected.contains(c.id);

                    return CheckboxListTile(
                      title: Text('${c.emoji} ${c.title}'),
                      subtitle: Text(c.subtitle),
                      value: isChecked,
                      onChanged: (val) {
                        setStateCourse(() {
                          if (val == true) {
                            tempSelected.add(c.id);
                          } else {
                            tempSelected.remove(c.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                onSaved(tempSelected);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestSeriesPicker(
    BuildContext context,
    List<String> currentSelected,
    void Function(List<String> newSelected) onSaved,
  ) {
    List<String> tempSelected = List<String>.from(currentSelected);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateTS) => AlertDialog(
          title: const Text('Select Test Series'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: StreamBuilder<List<AdminTestSeries>>(
              stream: _testService.getTestSeriesList(),
              builder: (context, tsSnap) {
                if (!tsSnap.hasData) return const Center(child: CircularProgressIndicator());
                final tsList = tsSnap.data!.where((s) => s.visibility == 'published').toList();

                if (tsList.isEmpty) {
                  return const Center(child: Text('No published test series available.'));
                }

                return ListView.builder(
                  itemCount: tsList.length,
                  itemBuilder: (context, index) {
                    final ts = tsList[index];
                    final isChecked = tempSelected.contains(ts.id);

                    return CheckboxListTile(
                      title: Text('${ts.emoji} ${ts.title}'),
                      subtitle: Text(ts.subject),
                      value: isChecked,
                      onChanged: (val) {
                        setStateTS(() {
                          if (val == true) {
                            tempSelected.add(ts.id);
                          } else {
                            tempSelected.remove(ts.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                onSaved(tempSelected);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
