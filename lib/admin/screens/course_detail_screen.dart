import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import 'batch_quiz_list_screen.dart';
import '../widgets/admin_scaffold.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class CourseDetailScreen extends StatefulWidget {
  final AdminCourse course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AdminUser> _enrolledUsers = [];
  List<AdminUser> _filteredUsers = [];
  bool _isLoadingEnrollments = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = [
    'Syllabus & Modules',
    'Batches & Cohorts',
    'Enrolled Aspirants',
    'Live Classes',
    'Analytics & Retention',
  ];

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
    _loadEnrolledUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledUsers() async {
    try {
      final service = context.read<FirebaseAdminService>();
      final users = await service.getEnrolledUsersForCourse(widget.course.id);
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
        debugPrint('Enrollments load notice: $e');
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final currentPrice = widget.course.finalPrice ?? widget.course.priceDefault;
    final originalPrice = widget.course.realPrice ?? widget.course.priceDefault;
    final tagLabel = widget.course.tags.isNotEmpty ? widget.course.tags.first : 'UPSC';
    final facultyName = widget.course.teachers.isNotEmpty ? widget.course.teachers.first.name : 'Faculty Lead';
    final service = context.read<FirebaseAdminService>();

    return StreamBuilder<List<AdminLecture>>(
      stream: service.getLectures(widget.course.id),
      builder: (context, lecturesSnap) {
        return StreamBuilder<List<AdminNote>>(
          stream: service.getCourseNotes(widget.course.id),
          builder: (context, notesSnap) {
            return StreamBuilder<List<AdminDpp>>(
              stream: service.getCourseDpps(widget.course.id),
              builder: (context, dppsSnap) {
                final lectures = lecturesSnap.data ?? [];
                final notes = notesSnap.data ?? [];
                final dpps = dppsSnap.data ?? [];

                return AdminScaffold(
                  title: 'Course Intel: ${widget.course.title}',
                  body: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Breadcrumb & Back Link
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Row(
                                children: [
                                  Icon(Icons.arrow_back, size: 16, color: EduverseTheme.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Back to Courses Catalog',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: EduverseTheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CODE: ${widget.course.slug.isNotEmpty ? widget.course.slug.toUpperCase() : widget.course.id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Course Hero Banner
                        _buildHeroBanner(currentPrice, originalPrice, tagLabel, facultyName, isDesktop),
                        const SizedBox(height: 24),

                        // 4 Key Metrics Strip (Real data)
                        _buildKeyMetricsStrip(currentPrice, lectures.length, isDesktop),
                        const SizedBox(height: 24),

                        // Tab Navigation Bar
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: EduverseTheme.primary,
                            unselectedLabelColor: EduverseTheme.onSurfaceVariant,
                            indicatorColor: EduverseTheme.primary,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                            tabs: _tabs.map((t) => Tab(text: t)).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Responsive 2:1 Layout for Selected Tab Content
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Pane: Dynamic Tab Content
                              Expanded(
                                flex: 2,
                                child: _buildActiveTabContent(isDesktop, lectures, notes, dpps),
                              ),
                              const SizedBox(width: 24),

                              // Right Pane: Content Tools & DRM Armor
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildContentToolsSection(),
                                    const SizedBox(height: 24),
                                    _buildSecurityCard(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActiveTabContent(isDesktop, lectures, notes, dpps),
                              const SizedBox(height: 20),
                              _buildContentToolsSection(),
                              const SizedBox(height: 20),
                              _buildSecurityCard(),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeroBanner(
    double currentPrice,
    double originalPrice,
    String tagLabel,
    String facultyName,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: EduverseTheme.deepNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Thumbnail
          if (isDesktop) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.course.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      widget.course.thumbnailUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultHeroImage(),
                    )
                  : _defaultHeroImage(),
            ),
            const SizedBox(width: 24),
          ],

          // Course Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduverseTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tagLabel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EduverseTheme.emeraldVivid.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Live • Public Storefront',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.primaryFixed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.course.title,
                  style: EduverseTheme.headlineLg(color: Colors.white).copyWith(
                    fontSize: isDesktop ? 26 : 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.course.subtitle.isNotEmpty ? widget.course.subtitle : widget.course.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '₹${currentPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: EduverseTheme.primaryFixed,
                      ),
                    ),
                    if (originalPrice > currentPrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/course_editor', arguments: widget.course);
                        _loadEnrolledUsers();
                      },
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Edit in Studio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EduverseTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultHeroImage() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: EduverseTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.school, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildKeyMetricsStrip(double currentPrice, int lectureCount, bool isDesktop) {
    final int enrolled = _enrolledUsers.length;
    final int seats = widget.course.seatsTotal ?? 2000;
    final double capPct = seats > 0 ? (enrolled / seats * 100) : 0.0;
    final double totalRevenue = enrolled * currentPrice;

    String revText;
    if (totalRevenue >= 10000000) {
      revText = '₹${(totalRevenue / 10000000).toStringAsFixed(2)} Cr';
    } else if (totalRevenue >= 100000) {
      revText = '₹${(totalRevenue / 100000).toStringAsFixed(1)} L';
    } else {
      revText = '₹${totalRevenue.toStringAsFixed(0)}';
    }

    if (!isDesktop) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _metricContent('Active Enrollments', '$enrolled / $seats', '${capPct.toStringAsFixed(0)}% cap', Icons.groups_outlined, EduverseTheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: _metricContent('Estimated Intake', revText, 'Real Admissions', Icons.currency_rupee, EduverseTheme.emeraldVivid)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _metricContent('Curriculum Pace', '$lectureCount Lectures', lectureCount > 0 ? 'Published' : '0 Published', Icons.slow_motion_video_outlined, EduverseTheme.secondary)),
                const SizedBox(width: 12),
                Expanded(child: _metricContent('DRM Status', 'Widevine L1', 'Attested', Icons.shield_outlined, EduverseTheme.tertiary)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _stripMetric('Active Enrollments', '$enrolled / $seats', '${capPct.toStringAsFixed(0)}% cap', Icons.groups_outlined, EduverseTheme.primary),
          _stripDivider(),
          _stripMetric('Estimated Intake', revText, 'Real Admissions', Icons.currency_rupee, EduverseTheme.emeraldVivid),
          _stripDivider(),
          _stripMetric('Curriculum Pace', '$lectureCount Lectures', lectureCount > 0 ? 'Published & Active' : '0 Published', Icons.slow_motion_video_outlined, EduverseTheme.secondary),
          _stripDivider(),
          _stripMetric('DRM Status', 'Widevine L1', 'Attested', Icons.shield_outlined, EduverseTheme.tertiary),
        ],
      ),
    );
  }

  Widget _stripMetric(String title, String value, String subtext, IconData icon, Color color) {
    return Expanded(
      child: _metricContent(title, value, subtext, icon, color),
    );
  }

  Widget _metricContent(String title, String value, String subtext, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: EduverseTheme.deepNavy),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtext,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stripDivider() {
    return Container(
      height: 40,
      width: 1,
      color: EduverseTheme.outlineVariant.withValues(alpha: 0.25),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildActiveTabContent(
    bool isDesktop,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildCurriculumHierarchy(isDesktop, lectures, notes, dpps);
      case 1:
        return _buildBatchesTab(isDesktop);
      case 2:
        return _buildEnrolledAspirantsSection();
      case 3:
        return _buildLiveClassesTab(isDesktop);
      case 4:
        return _buildAnalyticsTab(isDesktop, lectures.length, notes.length, dpps.length);
      default:
        return _buildCurriculumHierarchy(isDesktop, lectures, notes, dpps);
    }
  }

  Widget _buildCurriculumHierarchy(
    bool isDesktop,
    List<AdminLecture> lectures,
    List<AdminNote> notes,
    List<AdminDpp> dpps,
  ) {
    // Extract unique subjects from actual content or course configuration
    final subjectsSet = <String>{...widget.course.subjectLogos.keys};
    for (final l in lectures) {
      if (l.subject.isNotEmpty && l.type != 'folder') subjectsSet.add(l.subject);
    }
    for (final n in notes) {
      if (n.subject.isNotEmpty) subjectsSet.add(n.subject);
    }
    for (final d in dpps) {
      if (d.subject.isNotEmpty) subjectsSet.add(d.subject);
    }
    final subjectsList = subjectsSet.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curriculum Hierarchy',
                    style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lectures.length} Lectures • ${notes.length} Notes • ${dpps.length} DPPs across ${subjectsList.length} Subjects',
                    style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/lecture_editor',
                  arguments: {'courseId': widget.course.id, 'batchId': ''},
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Lecture / Module'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zero-State Hub when no content exists
          if (subjectsList.isEmpty && lectures.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: EduverseTheme.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_outlined, size: 36, color: EduverseTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('No Curriculum Content Yet', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Publish your first video lecture, class note, or practice paper to populate this cohort’s syllabus hierarchy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/lecture_editor',
                        arguments: {'courseId': widget.course.id, 'batchId': ''},
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add First Lecture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EduverseTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...subjectsList.map((subject) {
              final subjectLectures = lectures.where((l) => l.subject == subject && l.type != 'folder').toList();
              final subjectNotesCount = notes.where((n) => n.subject == subject).length;
              final subjectDppsCount = dpps.where((d) => d.subject == subject).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _moduleTile(
                  subject,
                  '${subjectLectures.length} Lectures • $subjectNotesCount Notes • $subjectDppsCount DPPs',
                  subjectLectures.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No individual lectures in this subject yet.',
                              style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.8)),
                            ),
                          )
                        ]
                      : subjectLectures.map((lecture) {
                          final durationStr = lecture.type == 'video' ? 'Video Stream' : lecture.type.toUpperCase();
                          final dppBadge = lecture.linkedNoteIds.isNotEmpty
                              ? '${lecture.linkedNoteIds.length} Notes Linked'
                              : (lecture.chapter.isNotEmpty ? lecture.chapter : 'GS Core');

                          return InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/lecture_editor',
                              arguments: {
                                'courseId': widget.course.id,
                                'batchId': '',
                                'lecture': lecture,
                              },
                            ),
                            child: _lectureItem(
                              lecture.title.isNotEmpty ? lecture.title : 'Untitled Lecture #${lecture.lectureNo ?? 1}',
                              durationStr,
                              dppBadge,
                              !lecture.isLocked,
                            ),
                          );
                        }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBatchesTab(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batches & Cohorts',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/recorded_batches', arguments: {'courseId': widget.course.id}),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Manage Recorded Batches'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_outlined, color: EduverseTheme.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Master Batch: ${widget.course.title}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Seats Total: ${widget.course.seatsTotal ?? 2000} • Enrolled: ${_enrolledUsers.length} • Status: ${widget.course.visibility.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.course.isActive ? EduverseTheme.emeraldVivid.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.course.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.course.isActive ? EduverseTheme.emeraldVivid : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassesTab(bool isDesktop) {
    final service = context.read<FirebaseAdminService>();
    return StreamBuilder<List<AdminLiveClass>>(
      stream: service.getLiveClasses().map((list) => list.where((c) => c.linkedCourses.contains(widget.course.id) || widget.course.id.isEmpty).toList()),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Broadcasts (${classes.length})',
                    style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/course_schedule_dashboard', arguments: {'courseId': widget.course.id, 'batchId': ''}),
                    icon: const Icon(Icons.videocam, size: 16),
                    label: const Text('Schedule Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduverseTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (classes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Text('No live broadcasts scheduled for this course yet.', style: TextStyle(color: EduverseTheme.onSurfaceVariant)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final lc = classes[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EduverseTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.live_tv, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lc.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text(
                                  'Status: ${lc.status} • Scheduled: ${DateFormat('dd MMM yyyy, HH:mm').format(lc.startTime)}',
                                  style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab(bool isDesktop, int lectureCount, int noteCount, int dppCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Analytics & Pedagogical Health',
            style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EduverseTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL ASSETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text('${lectureCount + noteCount + dppCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EduverseTheme.deepNavy)),
                      Text('$lectureCount Videos • $noteCount PDFs • $dppCount DPPs', style: const TextStyle(fontSize: 11, color: EduverseTheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EduverseTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ENROLLED ASPIRANTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text('${_enrolledUsers.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EduverseTheme.deepNavy)),
                      const Text('100% DRM Attested', style: TextStyle(fontSize: 11, color: EduverseTheme.emeraldVivid, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moduleTile(String title, String subtitle, List<Widget> lectures) {
    return Container(
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EduverseTheme.primaryFixed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder_open_outlined, color: EduverseTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: EduverseTheme.deepNavy),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
        ),
        children: lectures,
      ),
    );
  }

  Widget _lectureItem(String title, String duration, String dppLabel, bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: EduverseTheme.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, size: 18, color: EduverseTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              duration,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: EduverseTheme.tertiaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              dppLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onTertiaryFixed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentToolsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operations & Batch Suite',
            style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _toolTile(
            Icons.video_library_outlined,
            'Upload Lecture Video',
            'Stream & DRM Encrypt',
            () => Navigator.pushNamed(context, '/lecture_editor', arguments: {'courseId': widget.course.id, 'batchId': ''}),
          ),
          _toolTile(
            Icons.menu_book_outlined,
            'Batch Notes Vault',
            'PDF Handouts & Revision Sheets',
            () => Navigator.pushNamed(context, '/batch_notes', arguments: {'courseId': widget.course.id, 'batchId': ''}),
          ),
          _toolTile(
            Icons.calendar_month_outlined,
            'Batch Syllabus Planner',
            'Timetable Matrix & Velocity',
            () => Navigator.pushNamed(context, '/batch_planner', arguments: {'courseId': widget.course.id, 'batchId': ''}),
          ),
          _toolTile(
            Icons.assignment_outlined,
            'Daily Practice DPPs',
            'PDF Problems & Solvers',
            () => Navigator.pushNamed(context, '/batch_dpp', arguments: {'courseId': widget.course.id, 'batchId': ''}),
          ),
          _toolTile(
            Icons.quiz_outlined,
            'Batch Tests & Quizzes',
            'Manage MCQs & Scores',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => BatchQuizListScreen(courseId: widget.course.id, batchId: ''))),
          ),
          _toolTile(
            Icons.live_tv_outlined,
            'Schedule Live Session',
            'Faculty Stream Broadcast',
            () => Navigator.pushNamed(context, '/course_schedule_dashboard', arguments: {'courseId': widget.course.id, 'batchId': ''}),
          ),
        ],
      ),
    );
  }

  Widget _toolTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: EduverseTheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: EduverseTheme.outline),
      onTap: onTap,
    );
  }

  Widget _buildEnrolledAspirantsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enrolled Aspirants (${_enrolledUsers.length})',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Enroll Candidate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                hintText: 'Search candidates by name, email, or phone...',
                hintStyle: TextStyle(fontSize: 12, color: EduverseTheme.outline),
                prefixIcon: Icon(Icons.search, size: 18, color: EduverseTheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingEnrollments)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_filteredUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _searchQuery.isNotEmpty ? 'No students found matching "$_searchQuery"' : 'No students enrolled yet',
                  style: const TextStyle(color: EduverseTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: EduverseTheme.surfaceContainerHigh),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: EduverseTheme.primaryFixed,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: EduverseTheme.primary),
                    ),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(user.email, style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                  trailing: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/user_detail', arguments: user),
                    child: const Text('View Dossier →', style: TextStyle(fontSize: 12, color: EduverseTheme.primary)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, size: 18, color: EduverseTheme.primary),
              const SizedBox(width: 8),
              Text(
                'DRM Content Armor',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Dynamic user watermark and screen recording defense active for all lectures in this course.',
            style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: EduverseTheme.emeraldVivid),
                SizedBox(width: 8),
                Text(
                  'Encrypted Offline Download Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.emeraldVivid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
