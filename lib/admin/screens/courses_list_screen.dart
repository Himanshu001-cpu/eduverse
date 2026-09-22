import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_admin_service.dart';
import '../models/admin_models.dart';
import '../widgets/admin_scaffold.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  String _selectedStatus = 'all'; // all, published, draft, archived
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isTableView = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'UPSC',
    'State PSC',
    'SSC & Banking',
    'Foundation',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AdminScaffold(
      title: 'Course Catalog & Programs',
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/course_editor'),
              backgroundColor: EduverseTheme.primary,
              foregroundColor: EduverseTheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('New Course'),
            )
          : null,
      body: StreamBuilder<List<AdminCourse>>(
        stream: service.getCourses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: EduverseTheme.primary));
          }

          final allCourses = snapshot.data!;
          final publishedCount = allCourses.where((c) => c.visibility == 'published').length;
          final draftCount = allCourses.where((c) => c.visibility == 'draft').length;
          final archivedCount = allCourses.where((c) => c.visibility == 'archived').length;

          // Filter by status, category, and search
          final filteredCourses = allCourses.where((c) {
            final matchesStatus = _selectedStatus == 'all' || c.visibility == _selectedStatus;
            final matchesCategory = _selectedCategory == 'All' ||
                c.tags.any((t) => t.toLowerCase().contains(_selectedCategory.toLowerCase())) ||
                c.title.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                c.subtitle.toLowerCase().contains(_selectedCategory.toLowerCase());
            final teacherNames = c.teachers.map((t) => t.name.toLowerCase()).join(' ');
            final matchesSearch = _searchQuery.isEmpty ||
                c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                teacherNames.contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesCategory && matchesSearch;
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catalog Header Title & Description
                _buildCatalogHeader(isDesktop),
                const SizedBox(height: 20),

                // Status Tabs Bar (Matching Stitch: Published (28), Draft (4), Archived (2))
                _buildStatusTabs(allCourses.length, publishedCount, draftCount, archivedCount, isDesktop),
                const SizedBox(height: 20),

                // Search & Filter Toolbar
                _buildToolbar(isDesktop),
                const SizedBox(height: 20),

                // Main Courses Presentation (Table View or Grid View)
                if (filteredCourses.isEmpty)
                  _buildEmptyState()
                else if (isDesktop && _isTableView)
                  _buildCoursesTable(filteredCourses, service)
                else
                  _buildCoursesGrid(filteredCourses, service, isDesktop),

                const SizedBox(height: 32),

                // 3 Bottom Feature / Sentinel Cards (Matching Stitch)
                _buildBottomSentinelCards(isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatalogHeader(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Academic Management • Catalog',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: EduverseTheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Course Catalog & Programs',
          style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(
            fontSize: isDesktop ? 28 : 22,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage published courses, curriculum syllabi, batch cohorts, and storefront monetization rules.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: EduverseTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(int total, int published, int draft, int archived, bool isDesktop) {
    return Row(
      children: [
        _tabButton('all', 'All ($total)'),
        const SizedBox(width: 8),
        _tabButton('published', 'Published ($published)'),
        const SizedBox(width: 8),
        _tabButton('draft', 'Draft ($draft)'),
        const SizedBox(width: 8),
        _tabButton('archived', 'Archived ($archived)'),
        const Spacer(),
        if (isDesktop) ...[
          IconButton(
            icon: Icon(
              Icons.table_rows_outlined,
              color: _isTableView ? EduverseTheme.primary : EduverseTheme.outline,
            ),
            tooltip: 'Table View',
            onPressed: () => setState(() => _isTableView = true),
          ),
          IconButton(
            icon: Icon(
              Icons.grid_view_outlined,
              color: !_isTableView ? EduverseTheme.primary : EduverseTheme.outline,
            ),
            tooltip: 'Grid View',
            onPressed: () => setState(() => _isTableView = false),
          ),
        ],
      ],
    );
  }

  Widget _tabButton(String key, String label) {
    final isSelected = _selectedStatus == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EduverseTheme.primary : EduverseTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? EduverseTheme.primary : EduverseTheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : EduverseTheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search courses by title, faculty, or program code...',
                hintStyle: TextStyle(fontSize: 12, color: EduverseTheme.outline),
                prefixIcon: Icon(Icons.search, size: 18, color: EduverseTheme.onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Category Dropdown Filter
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: EduverseTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/course_editor'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create New Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EduverseTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCoursesTable(List<AdminCourse> courses, FirebaseAdminService service) {
    return Container(
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3.0), // Program & Code
          1: FlexColumnWidth(1.2), // Format
          2: FlexColumnWidth(1.5), // Lead Faculty
          3: FlexColumnWidth(1.8), // Enrollment Ratio
          4: FlexColumnWidth(1.2), // Pricing
          5: FlexColumnWidth(1.2), // Status
          6: FlexColumnWidth(1.0), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Table Header
          TableRow(
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            children: [
              _th('Course Program & Code'),
              _th('Format'),
              _th('Lead Faculty'),
              _th('Enrollment Ratio'),
              _th('Pricing'),
              _th('Status'),
              _th('Actions'),
            ],
          ),
          // Data Rows
          ...courses.map((course) => _buildTableRow(course)),
        ],
      ),
    );
  }

  Widget _th(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: EduverseTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  TableRow _buildTableRow(AdminCourse course) {
    final currentPrice = course.finalPrice ?? course.priceDefault;
    final originalPrice = course.realPrice ?? course.priceDefault;
    final facultyName = course.teachers.isNotEmpty ? course.teachers.first.name : 'Faculty Lead';
    final isPublished = course.visibility == 'published';
    final isDraft = course.visibility == 'draft';

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EduverseTheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      children: [
        // Course Program & Code
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: course.thumbnailUrl.isNotEmpty
                    ? Image.network(course.thumbnailUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _tablePlaceholder())
                    : _tablePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: EduverseTheme.deepNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      course.slug.isNotEmpty ? course.slug : 'CODE: ${course.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: EduverseTheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Format
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              course.isCourseBatch ? 'Online Live' : 'Recorded',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
            ),
          ),
        ),

        // Lead Faculty
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            facultyName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Enrollment Ratio
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1,240 / 1,500 seats',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.82,
                  backgroundColor: EduverseTheme.surfaceContainerHigh,
                  color: EduverseTheme.primary,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        // Pricing
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${currentPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: EduverseTheme.primary),
              ),
              if (originalPrice > currentPrice)
                Text(
                  '₹${originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: EduverseTheme.outline),
                ),
            ],
          ),
        ),

        // Status
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPublished
                  ? EduverseTheme.emeraldVivid.withValues(alpha: 0.12)
                  : (isDraft ? EduverseTheme.tertiaryContainer.withValues(alpha: 0.15) : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              course.visibility.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isPublished ? EduverseTheme.emeraldVivid : (isDraft ? EduverseTheme.tertiary : Colors.grey.shade700),
              ),
            ),
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: EduverseTheme.primary),
                tooltip: 'Edit in Studio',
                onPressed: () => Navigator.pushNamed(context, '/course_editor', arguments: course),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 16, color: EduverseTheme.deepNavy),
                tooltip: 'View Details',
                onPressed: () => Navigator.pushNamed(context, '/course_detail', arguments: course),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tablePlaceholder() {
    return Container(
      width: 44,
      height: 44,
      color: EduverseTheme.surfaceContainerHigh,
      child: const Icon(Icons.school, size: 20, color: EduverseTheme.primary),
    );
  }

  Widget _buildCoursesGrid(List<AdminCourse> courses, FirebaseAdminService service, bool isDesktop) {
    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) => _CourseCardAcademic(course: courses[index], service: service),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _CourseCardAcademic(course: courses[index], service: service),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 64, color: EduverseTheme.outlineVariant),
            const SizedBox(height: 16),
            const Text(
              'No courses found matching your criteria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _selectedCategory = 'All';
                _selectedStatus = 'all';
                _searchQuery = '';
                _searchController.clear();
              }),
              child: const Text('Clear Filters', style: TextStyle(color: EduverseTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSentinelCards(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: _sentinelCard(
            Icons.bolt,
            'Auto-Publish Next Batch',
            'When enrollment reaches 95%, the system automatically opens subsequent intake batches with standard quota tiers.',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _sentinelCard(
            Icons.payments_outlined,
            'Razorpay Bulk Split',
            'Direct settlement routing configured for faculty honorarium disbursements and institutional platform accounts.',
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 16),
          Expanded(
            child: _sentinelCard(
              Icons.lock_outline,
              'DRM Content Encryption',
              'All lecture videos and PDF DPP handouts utilize dynamic watermarking and device hardware encryption keys.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _sentinelCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EduverseTheme.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: EduverseTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: EduverseTheme.deepNavy),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCardAcademic extends StatelessWidget {
  final AdminCourse course;
  final FirebaseAdminService service;

  const _CourseCardAcademic({
    required this.course,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final isPublished = course.visibility == 'published';
    final isDraft = course.visibility == 'draft';
    final facultyName = course.teachers.isNotEmpty ? course.teachers.first.name : 'Faculty Lead';
    final currentPrice = course.finalPrice ?? course.priceDefault;
    final originalPrice = course.realPrice ?? course.priceDefault;
    final tagLabel = course.tags.isNotEmpty ? course.tags.first : 'UPSC';

    return Container(
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Header with Category & Status Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: course.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        course.thumbnailUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultImage(),
                      )
                    : _defaultImage(),
              ),
              // Category Chip
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tagLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Status Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? EduverseTheme.primary
                        : (isDraft ? EduverseTheme.tertiaryContainer : EduverseTheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course.visibility.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Course Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: EduverseTheme.deepNavy,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: EduverseTheme.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          facultyName,
                          style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Pricing & Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${currentPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: EduverseTheme.primary,
                            ),
                          ),
                          if (originalPrice > currentPrice)
                            Text(
                              '₹${originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: EduverseTheme.outline,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: EduverseTheme.primary),
                            tooltip: 'Edit in Studio',
                            onPressed: () => Navigator.pushNamed(context, '/course_editor', arguments: course),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, size: 18, color: EduverseTheme.deepNavy),
                            tooltip: 'View Details',
                            onPressed: () => Navigator.pushNamed(context, '/course_detail', arguments: course),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultImage() {
    return Container(
      height: 140,
      width: double.infinity,
      color: EduverseTheme.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.school, size: 40, color: EduverseTheme.primary),
      ),
    );
  }
}
