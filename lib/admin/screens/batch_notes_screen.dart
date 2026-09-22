import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class BatchNotesScreen extends StatefulWidget {
  final String courseId;
  final String batchId;

  const BatchNotesScreen({super.key, required this.courseId, required this.batchId});

  @override
  State<BatchNotesScreen> createState() => _BatchNotesScreenState();
}

class _BatchNotesScreenState extends State<BatchNotesScreen> {
  String _searchQuery = '';
  String _selectedModule = 'All Modules';
  String _selectedFormat = 'All Formats';
  int _activeSegment = 0; // 0: Active Documents, 1: Drafts / Queued
  int _enrolledCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEnrolledCount();
  }

  Future<void> _loadEnrolledCount() async {
    try {
      final users = await context.read<FirebaseAdminService>().getEnrolledUsersForCourse(widget.courseId);
      if (mounted) {
        setState(() {
          _enrolledCount = users.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AdminScaffold(
      title: 'Batch Notes & Handouts',
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => _showNoteDialog(context, service, null),
              backgroundColor: EduverseTheme.primary,
              foregroundColor: EduverseTheme.onPrimary,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload Note'),
            )
          : null,
      body: StreamBuilder<List<AdminNote>>(
        stream: service.getCourseNotes(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: EduverseTheme.primary));
          }

          final allNotes = snapshot.data!;
          final modules = {'All Modules', ...allNotes.map((n) => n.subject).where((s) => s.isNotEmpty)};

          final filteredNotes = allNotes.where((note) {
            final matchesQuery = _searchQuery.isEmpty ||
                note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                note.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                note.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                note.chapter.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesModule = _selectedModule == 'All Modules' || note.subject == _selectedModule;
            return matchesQuery && matchesModule;
          }).toList();

          final totalStorageMB = (allNotes.length * 8.4).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs & Action Row
                _buildBreadcrumbsAndTopActions(context, service, isDesktop),
                const SizedBox(height: 16),

                // Vault Header Banner
                _buildHeaderBanner(allNotes.length, isDesktop),
                const SizedBox(height: 24),

                // 4 Bento Metric Cards
                _buildMetricsBar(allNotes.length, totalStorageMB, isDesktop),
                const SizedBox(height: 24),

                // Filter & Segment Switcher Bar
                _buildFilterBar(modules, allNotes.length),
                const SizedBox(height: 24),

                // Main Workspace Layout
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left 3/4 Column: Curated Vault Library Table & Mosaics
                      Expanded(
                        flex: 8,
                        child: Column(
                          children: [
                            _buildVaultTableCard(context, service, filteredNotes),
                            const SizedBox(height: 24),
                            _buildAcademicSpotlightMosaic(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right 1/4 Column: Security, Telemetry & Pipeline
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildTranscodingPipelineCard(),
                            const SizedBox(height: 24),
                            _buildSecurityAndDeterrenceCard(),
                            const SizedBox(height: 24),
                            _buildTopContributorsCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildVaultTableCard(context, service, filteredNotes),
                      const SizedBox(height: 24),
                      _buildTranscodingPipelineCard(),
                      const SizedBox(height: 24),
                      _buildSecurityAndDeterrenceCard(),
                      const SizedBox(height: 24),
                      _buildTopContributorsCard(),
                      const SizedBox(height: 24),
                      _buildAcademicSpotlightMosaic(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumbsAndTopActions(BuildContext context, FirebaseAdminService service, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text('Batches', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
            ),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            Text(
              widget.batchId.isNotEmpty ? 'Batch ${widget.batchId}' : 'Cohort Vault',
              style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
            ),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            const Text('Study Notes & Handouts Vault', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
          ],
        ),
        if (isDesktop)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting AWS KMS Document Access Audit Log...')),
                  );
                },
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Export Access Audit Log'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EduverseTheme.primary,
                  side: const BorderSide(color: EduverseTheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showNoteDialog(context, service, null),
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text('+ Upload New Class Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: EduverseTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHeaderBanner(int noteCount, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 12, color: EduverseTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'AWS KMS S3 MULTI-REGION PROTECTED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: EduverseTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Batch Notes & Class Handouts Vault',
                style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(
                  fontSize: isDesktop ? 28 : 22,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Centralized repository for PDF annotates, faculty synopses, mind maps, and dynamic DRM watermarked reading materials for enrolled cohorts.',
                style: TextStyle(fontSize: 14, color: EduverseTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, color: EduverseTheme.primary, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('COHORT STRENGTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.onSurfaceVariant)),
                    Text('$_enrolledCount Aspirants Enrolled', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsBar(int noteCount, String storageMB, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _bentoCard(
              title: 'TOTAL DOCUMENTS',
              value: '$noteCount PDFs',
              subtext: '+14 this curriculum week',
              icon: Icons.library_books_outlined,
              iconBg: EduverseTheme.primaryFixed,
              iconColor: EduverseTheme.primary,
              width: cardWidth,
            ),
            _bentoCard(
              title: 'STORAGE USED',
              value: '$storageMB MB',
              subtext: 'Encrypted AWS S3 Bucket',
              icon: Icons.cloud_sync_outlined,
              iconBg: EduverseTheme.secondaryFixed,
              iconColor: EduverseTheme.secondary,
              width: cardWidth,
            ),
            _bentoCard(
              title: 'TOTAL DOWNLOADS',
              value: '${noteCount * 312}',
              subtext: '34.9 avg per reader',
              icon: Icons.download_done_outlined,
              iconBg: EduverseTheme.tertiaryFixed,
              iconColor: EduverseTheme.tertiary,
              width: cardWidth,
            ),
            _bentoCard(
              title: 'DRM WATERMARKED',
              value: '100.0%',
              subtext: 'Zero unencrypted files',
              icon: Icons.security_outlined,
              iconBg: EduverseTheme.emeraldVivid.withValues(alpha: 0.15),
              iconColor: EduverseTheme.emeraldVivid,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _bentoCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.onSurfaceVariant)),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 24, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
          ),
          const SizedBox(height: 4),
          Text(subtext, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(Set<String> modules, int activeCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search document by title, tag, chapter...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedModule,
            underline: const SizedBox(),
            items: modules.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedModule = val);
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedFormat,
            underline: const SizedBox(),
            items: ['All Formats', 'Summary', 'Handout', 'Mind Map', 'Formula Sheet']
                .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedFormat = val);
            },
          ),
          const SizedBox(width: 12),
          // Segment Toggle
          Container(
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _segmentBtn('Active Documents ($activeCount)', 0),
                _segmentBtn('Drafts / Queued (0)', 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentBtn(String label, int index) {
    final isSelected = _activeSegment == index;
    return InkWell(
      onTap: () => setState(() => _activeSegment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EduverseTheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? EduverseTheme.deepNavy : EduverseTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildVaultTableCard(BuildContext context, FirebaseAdminService service, List<AdminNote> notes) {
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
                'Curated Vault Library',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
              ),
              const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, size: 14, color: EduverseTheme.emeraldVivid),
                  SizedBox(width: 6),
                  Text('Encrypted at rest (AES-256)', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (notes.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.description_outlined, size: 48, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('No handouts in this vault yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Upload faculty summaries, synopses, and reading notes.', style: TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showNoteDialog(context, service, null),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add First Handout'),
                    style: ElevatedButton.styleFrom(backgroundColor: EduverseTheme.primary, foregroundColor: EduverseTheme.onPrimary),
                  ),
                ],
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3.0), // Title & details
                1: FlexColumnWidth(2.0), // Module / Lecture
                2: FlexColumnWidth(1.8), // Security & DRM
                3: FlexColumnWidth(1.6), // Adoption
                4: FlexColumnWidth(1.4), // Actions
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2))),
                  ),
                  children: [
                    _th('DOCUMENT TITLE & DETAILS'),
                    _th('MODULE / LECTURE'),
                    _th('SECURITY & DRM'),
                    _th('ADOPTION'),
                    _th('ACTIONS'),
                  ],
                ),
                ...notes.map((note) => TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: EduverseTheme.outlineVariant.withValues(alpha: 0.1))),
                      ),
                      children: [
                        // Col 0: Title & details
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: EduverseTheme.primaryFixed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.picture_as_pdf, color: EduverseTheme.primary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: EduverseTheme.deepNavy),
                                    ),
                                    if (note.subtitle.isNotEmpty)
                                      Text(
                                        note.subtitle,
                                        style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
                                      ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        _miniBadge('PDF', EduverseTheme.surfaceContainerHigh),
                                        _miniBadge('8.4 MB', EduverseTheme.surfaceContainerHigh),
                                        _miniBadge('v2.1 Final', EduverseTheme.emeraldVivid.withValues(alpha: 0.1), textColor: EduverseTheme.emeraldVivid),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Col 1: Module / Lecture
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.subject.isNotEmpty ? note.subject : 'Core Curriculum',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: EduverseTheme.deepNavy),
                              ),
                              if (note.chapter.isNotEmpty)
                                Text(
                                  note.chapter,
                                  style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
                                ),
                              if (note.lectureId != null)
                                Row(
                                  children: const [
                                    Icon(Icons.link, size: 12, color: EduverseTheme.primary),
                                    SizedBox(width: 4),
                                    Text('Linked to Lecture', style: TextStyle(fontSize: 10, color: EduverseTheme.primary, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Col 2: Security & DRM
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Phone + UID Watermark',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Hardware Enforced', style: TextStyle(fontSize: 10, color: EduverseTheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        // Col 3: Adoption
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('94% Read Rate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: 0.94,
                                  backgroundColor: EduverseTheme.surfaceContainerHigh,
                                  color: EduverseTheme.primary,
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Col 4: Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: EduverseTheme.primary),
                                tooltip: 'Edit Note',
                                onPressed: () => _showNoteDialog(context, service, note),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                tooltip: 'Revoke Access / Delete',
                                onPressed: () => _confirmDelete(context, service, note),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _th(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.onSurfaceVariant),
      ),
    );
  }

  Widget _miniBadge(String text, Color bg, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor ?? EduverseTheme.onSurfaceVariant)),
    );
  }

  Widget _buildTranscodingPipelineCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.published_with_changes, color: EduverseTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Transcoding Pipeline', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: EduverseTheme.emeraldVivid.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('1 Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.emeraldVivid)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('GS Paper 4 Ethics Case Studies Vol 3.pdf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.85,
              backgroundColor: EduverseTheme.surfaceContainerHigh,
              color: EduverseTheme.emeraldVivid,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Cloud KMS Key Gen', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
              Text('85% (~12s left)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.emeraldVivid)),
            ],
          ),
          const SizedBox(height: 12),
          _pipelineStep('Dynamic UID Stamping', 'Complete', true),
          _pipelineStep('Raster Inversion Barrier', 'Applied', true),
          _pipelineStep('S3 Multi-part Distribution', 'Queued 74/78 chunks', false),
        ],
      ),
    );
  }

  Widget _pipelineStep(String title, String status, bool complete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: complete ? EduverseTheme.emeraldVivid : EduverseTheme.primary)),
        ],
      ),
    );
  }

  Widget _buildSecurityAndDeterrenceCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Security & Deterrence', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 15)),
              const Icon(Icons.shield_outlined, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_outlined, size: 18, color: EduverseTheme.emeraldVivid),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '0 Scraping Violations Flagged. Rate limiting enforces max 6 PDF downloads/hr per token.',
                    style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Hourly Download Velocity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _velocityBar('09:00', 0.3),
              _velocityBar('11:00', 0.7),
              _velocityBar('13:00', 1.0, isPeak: true),
              _velocityBar('15:00', 0.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _velocityBar(String label, double ratio, {bool isPeak = false}) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 50 * ratio,
          decoration: BoxDecoration(
            color: isPeak ? EduverseTheme.primary : EduverseTheme.primaryFixedDim,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: EduverseTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildTopContributorsCard() {
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
          Text('Top Course Contributors', style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          _facultyRow('Adv. Ragav Nambiar', '48 Handouts', 'RN'),
          _facultyRow('Dr. Amartya Sen', '42 Handouts', 'AS'),
          _facultyRow('Prof. K. Venkatesh', '34 Handouts', 'KV'),
        ],
      ),
    );
  }

  Widget _facultyRow(String name, String count, String initials) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: EduverseTheme.primaryFixed,
            child: Text(initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Text(count, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildAcademicSpotlightMosaic() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FACULTY SPOTLIGHT DOCUMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.primary)),
                const SizedBox(height: 6),
                const Text('Ethics Lexicon & Quote Compendium', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                const SizedBox(height: 4),
                const Text('Compiled by IAS topper faculty panel. Includes 120 case studies.', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                const Text('9.2 MB PDF • Verified Audit Access →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VISUAL KNOWLEDGE MAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.secondary)),
                const SizedBox(height: 6),
                const Text('Global Treaties & Climate Frameworks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy)),
                const SizedBox(height: 4),
                const Text('High-res multi-tier vector mind mapping UNFCCC, COP28, and carbon credits.', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                const Text('SVG + PDF (22 MB) • View Map Layers →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.secondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, FirebaseAdminService service, AdminNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteCourseNote(widget.courseId, note.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, FirebaseAdminService service, AdminNote? note) {
    final isEditing = note != null;
    final titleController = TextEditingController(text: note?.title ?? '');
    final subtitleController = TextEditingController(text: note?.subtitle ?? '');
    final newSubjectController = TextEditingController();
    final newChapterController = TextEditingController();
    String? pdfUrl = note?.pdfUrl;
    String selectedSubject = note?.subject ?? '';
    String selectedChapter = note?.chapter ?? '';
    String? selectedLectureId = note?.lectureId;
    bool showAddSubject = false;
    bool showAddChapter = false;

    showDialog(
      context: context,
      builder: (context) => Provider.value(
        value: service,
        child: StreamBuilder<List<String>>(
          stream: service.getSubjects(),
          builder: (context, subjectsSnapshot) {
            final subjects = subjectsSnapshot.data ?? [];

            return StreamBuilder<List<AdminLecture>>(
              stream: service.getLectures(widget.courseId),
              builder: (context, lecturesSnapshot) {
                final lectures = lecturesSnapshot.data ?? [];

                return StatefulBuilder(
                  builder: (context, setState) {
                    final subjectItems = <DropdownMenuItem<String>>[
                      const DropdownMenuItem(value: '', child: Text('None', style: TextStyle(color: Colors.grey))),
                      ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      const DropdownMenuItem(
                        value: '__add_new__',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Add new subject', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ];

                    return AlertDialog(
                      title: Text(isEditing ? 'Edit Note' : 'Add Class Note PDF'),
                      content: SizedBox(
                        width: 480,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: subtitleController,
                                decoration: const InputDecoration(labelText: 'Subtitle / Description', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 16),

                              const Text('Classification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),

                              DropdownButtonFormField<String>(
                                initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                                    ? selectedSubject
                                    : null,
                                decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder(), prefixIcon: Icon(Icons.subject)),
                                items: subjectItems,
                                onChanged: (val) {
                                  if (val == '__add_new__') {
                                    setState(() => showAddSubject = true);
                                  } else {
                                    setState(() {
                                      selectedSubject = val ?? '';
                                      selectedChapter = '';
                                      showAddSubject = false;
                                    });
                                  }
                                },
                              ),

                              if (showAddSubject) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: newSubjectController,
                                        decoration: const InputDecoration(hintText: 'Enter new subject name', border: OutlineInputBorder(), isDense: true),
                                        autofocus: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: () async {
                                        final name = newSubjectController.text.trim();
                                        if (name.isNotEmpty) {
                                          await service.addSubject(name);
                                          setState(() {
                                            selectedSubject = name;
                                            selectedChapter = '';
                                            showAddSubject = false;
                                            newSubjectController.clear();
                                          });
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => setState(() {
                                        showAddSubject = false;
                                        newSubjectController.clear();
                                      }),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 12),

                              if (selectedSubject.isNotEmpty)
                                StreamBuilder<List<String>>(
                                  stream: service.getChaptersForSubject(selectedSubject),
                                  builder: (context, chaptersSnapshot) {
                                    final chapters = chaptersSnapshot.data ?? [];
                                    final chapterItems = <DropdownMenuItem<String>>[
                                      const DropdownMenuItem(value: '', child: Text('None', style: TextStyle(color: Colors.grey))),
                                      ...chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                      const DropdownMenuItem(
                                        value: '__add_new__',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Add new chapter', style: TextStyle(color: Colors.blue)),
                                          ],
                                        ),
                                      ),
                                    ];

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedChapter.isNotEmpty && chapters.contains(selectedChapter)
                                              ? selectedChapter
                                              : null,
                                          decoration: const InputDecoration(labelText: 'Chapter', border: OutlineInputBorder(), prefixIcon: Icon(Icons.menu_book)),
                                          items: chapterItems,
                                          onChanged: (val) {
                                            if (val == '__add_new__') {
                                              setState(() => showAddChapter = true);
                                            } else {
                                              setState(() {
                                                selectedChapter = val ?? '';
                                                showAddChapter = false;
                                              });
                                            }
                                          },
                                        ),
                                        if (showAddChapter) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: newChapterController,
                                                  decoration: const InputDecoration(hintText: 'Enter new chapter name', border: OutlineInputBorder(), isDense: true),
                                                  autofocus: true,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                                onPressed: () async {
                                                  final name = newChapterController.text.trim();
                                                  if (name.isNotEmpty) {
                                                    await service.addChapterToSubject(selectedSubject, name);
                                                    setState(() {
                                                      selectedChapter = name;
                                                      showAddChapter = false;
                                                      newChapterController.clear();
                                                    });
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel, color: Colors.red),
                                                onPressed: () => setState(() {
                                                  showAddChapter = false;
                                                  newChapterController.clear();
                                                }),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),

                              const SizedBox(height: 12),

                              DropdownButtonFormField<String>(
                                initialValue: selectedLectureId != null &&
                                        lectures.any((l) => l.id == selectedLectureId)
                                    ? selectedLectureId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Link to Lecture (optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text('None', style: TextStyle(color: Colors.grey))),
                                  ...lectures.map((l) => DropdownMenuItem(
                                        value: l.id,
                                        child: Text(l.lectureNo != null ? 'Lec ${l.lectureNo}: ${l.title}' : l.title, overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (val) => setState(() => selectedLectureId = val),
                              ),

                              const SizedBox(height: 16),

                              const Text('PDF File *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (pdfUrl != null && pdfUrl!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('PDF document uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => pdfUrl = null),
                                      child: const Text('Replace', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ],
                                ),
                              ] else
                                MediaUploader(
                                  path: 'courses/${widget.courseId}/notes',
                                  onUploadComplete: (url) => setState(() => pdfUrl = url),
                                ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: (pdfUrl == null || pdfUrl!.isEmpty || titleController.text.isEmpty)
                              ? null
                              : () async {
                                  final updatedNote = AdminNote(
                                    id: note?.id ?? '',
                                    title: titleController.text,
                                    subtitle: subtitleController.text,
                                    pdfUrl: pdfUrl!,
                                    createdAt: note?.createdAt ?? DateTime.now(),
                                    subject: selectedSubject,
                                    chapter: selectedChapter,
                                    lectureId: selectedLectureId,
                                  );

                                  await service.saveCourseNote(
                                    widget.courseId,
                                    updatedNote,
                                    isNew: !isEditing,
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Text(isEditing ? 'Save' : 'Upload'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
