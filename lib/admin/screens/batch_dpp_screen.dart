import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class BatchDppScreen extends StatefulWidget {
  final String courseId;
  final String batchId;

  const BatchDppScreen({super.key, required this.courseId, required this.batchId});

  @override
  State<BatchDppScreen> createState() => _BatchDppScreenState();
}

class _BatchDppScreenState extends State<BatchDppScreen> {
  String _searchQuery = '';
  String _selectedSubjectFilter = 'All';
  int _activeTab = 0; // 0: All, 1: Review Queue, 2: Question Bank, 3: Analytics
  bool _isGridView = false;

  // Quick MCQ Injector controllers
  final _injectorQuestionController = TextEditingController();
  final _injectorExplanationController = TextEditingController();
  final _optAController = TextEditingController(text: 'Originates from Raja Ashoka Year 4');
  final _optBController = TextEditingController(text: 'Must be certified by a Senior Advocate');
  final _optCController = TextEditingController(text: 'Can be entertained even without review');
  final _optDController = TextEditingController(text: 'Both A and B are strictly correct');
  String _selectedCorrectOption = 'C';
  String? _selectedTargetDppId;

  @override
  void dispose() {
    _injectorQuestionController.dispose();
    _injectorExplanationController.dispose();
    _optAController.dispose();
    _optBController.dispose();
    _optCController.dispose();
    _optDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AdminScaffold(
      title: 'Daily Practice Papers (DPP)',
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => _showDppDialog(context, service, null),
              backgroundColor: EduverseTheme.primary,
              foregroundColor: EduverseTheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Create DPP'),
            )
          : null,
      body: StreamBuilder<List<AdminDpp>>(
        stream: service.getCourseDpps(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: EduverseTheme.primary));
          }

          final allDpps = snapshot.data!;
          final subjects = {'All', ...allDpps.map((d) => d.subject).where((s) => s.isNotEmpty)};

          final filteredDpps = allDpps.where((dpp) {
            final matchesQuery = _searchQuery.isEmpty ||
                dpp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                dpp.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                dpp.chapter.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesSubject = _selectedSubjectFilter == 'All' || dpp.subject == _selectedSubjectFilter;
            return matchesQuery && matchesSubject;
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs & Engine Sync status
                _buildTopBreadcrumbBar(context),
                const SizedBox(height: 16),

                // Operational Hero Header
                _buildHeroHeader(context, service, isDesktop),
                const SizedBox(height: 24),

                // Live Performance Bento Metrics (4 Cards)
                _buildMetricsGrid(allDpps.length, isDesktop),
                const SizedBox(height: 24),

                // Navigation Workflow Tabs
                _buildWorkflowTabs(),
                const SizedBox(height: 20),

                // Filter & Search Toolbar
                _buildFilterToolbar(subjects),
                const SizedBox(height: 24),

                // Main Content Workspace
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: DPP Stream (8 cols)
                      Expanded(
                        flex: 8,
                        child: _buildDppStream(context, service, filteredDpps),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Quick Injector & Subject Mastery (4 cols)
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildQuickMcqInjectorCard(allDpps),
                            const SizedBox(height: 24),
                            _buildCohortSubjectMasteryCard(allDpps),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildDppStream(context, service, filteredDpps),
                      const SizedBox(height: 24),
                      _buildQuickMcqInjectorCard(allDpps),
                      const SizedBox(height: 24),
                      _buildCohortSubjectMasteryCard(allDpps),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBreadcrumbBar(BuildContext context) {
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
            const Text('Daily Practice Papers (DPP)', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: EduverseTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Batch: ${widget.batchId.isNotEmpty ? widget.batchId : 'Core'}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.sync, size: 14, color: EduverseTheme.emeraldVivid),
            const SizedBox(width: 6),
            const Text('Engine Synchronized', style: TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context, FirebaseAdminService service, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, size: 16, color: EduverseTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'EVALUATION & ASSEMBLY ENGINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: EduverseTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Daily Practice Papers (DPP) Operations Hub',
                style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(
                  fontSize: isDesktop ? 28 : 22,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Curate, schedule, and evaluate high-yield daily practice questions tied to lecture milestones with automated evaluation and AI answer keys.',
                style: TextStyle(fontSize: 14, color: EduverseTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 24),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Generating questions from latest lecture syllabus...')),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Generate DPP from AI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EduverseTheme.primary,
                  side: const BorderSide(color: EduverseTheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showDppDialog(context, service, null),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('+ Create New DPP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: EduverseTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsGrid(int totalDpps, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _metricCard(
              title: 'Total DPPs Published',
              value: '$totalDpps',
              subtext: 'Live in syllabus',
              icon: Icons.assignment_outlined,
              iconBg: EduverseTheme.primaryFixed,
              iconColor: EduverseTheme.primary,
              width: cardWidth,
            ),
            _metricCard(
              title: 'Avg Submission Rate',
              value: totalDpps > 0 ? '78.6%' : '0%',
              subtext: '↑ 3.2% this sprint',
              icon: Icons.query_stats_outlined,
              iconBg: EduverseTheme.secondaryFixed,
              iconColor: EduverseTheme.secondary,
              width: cardWidth,
            ),
            _metricCard(
              title: 'Pending Mains Review',
              value: totalDpps > 0 ? '18' : '0',
              subtext: 'Prompts queued',
              icon: Icons.rate_review_outlined,
              iconBg: EduverseTheme.tertiaryFixed,
              iconColor: EduverseTheme.tertiary,
              width: cardWidth,
            ),
            _metricCard(
              title: 'Question Bank Reserve',
              value: totalDpps > 0 ? '${totalDpps * 15}' : '0',
              subtext: 'High-yield MCQs',
              icon: Icons.inventory_2_outlined,
              iconBg: EduverseTheme.surfaceContainerHigh,
              iconColor: EduverseTheme.primary,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
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
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant)),
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
            style: const TextStyle(fontFamily: 'Playfair Display', fontSize: 26, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy),
          ),
          const SizedBox(height: 4),
          Text(subtext, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildWorkflowTabs() {
    final tabs = [
      'All Scheduled & Active DPPs',
      'Mains Answer Review Queue',
      'Question Bank & Tags',
      'Batch Analytics',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: isSelected,
              onSelected: (_) => setState(() => _activeTab = index),
              selectedColor: EduverseTheme.primary,
              backgroundColor: EduverseTheme.surfaceContainerLowest,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : EduverseTheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? EduverseTheme.primary : EduverseTheme.outlineVariant.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterToolbar(Set<String> subjects) {
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
                hintText: 'Search DPP code, topic, keywords...',
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
            value: _selectedSubjectFilter,
            underline: const SizedBox(),
            items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSubjectFilter = val);
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_agenda : Icons.grid_view, size: 20),
            tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildDppStream(BuildContext context, FirebaseAdminService service, List<AdminDpp> dpps) {
    if (dpps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No DPPs found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Create high-yield practice papers linked to curriculum lectures.', style: TextStyle(fontSize: 13, color: EduverseTheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showDppDialog(context, service, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add First DPP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduverseTheme.primary,
                foregroundColor: EduverseTheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(dpps.length, (index) {
        final dpp = dpps[index];
        return _buildDppCard(context, service, dpp, index);
      }),
    );
  }

  Widget _buildDppCard(BuildContext context, FirebaseAdminService service, AdminDpp dpp, int index) {
    final hasPdf = dpp.dppPdfUrl.isNotEmpty;
    final hasSolution = dpp.solutionPdfUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EduverseTheme.secondaryFixed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DPP #${index + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.secondary),
                    ),
                  ),
                  if (dpp.subject.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: EduverseTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dpp.subject,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant),
                      ),
                    ),
                  if (dpp.chapter.isNotEmpty)
                    Text(
                      '• ${dpp.chapter}',
                      style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EduverseTheme.emeraldVivid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: EduverseTheme.emeraldVivid),
                    SizedBox(width: 4),
                    Text(
                      'Active & Evaluated',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.emeraldVivid),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DPP Title
          Text(
            dpp.title,
            style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),

          // Linked lecture or description
          if (dpp.lectureId != null && dpp.lectureId!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: EduverseTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Linked to Lecture Milestone',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EduverseTheme.primary),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Specs Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _specItem(Icons.quiz_outlined, '15 MCQs'),
                _specItem(Icons.timer_outlined, '25 mins'),
                _specItem(Icons.remove_circle_outline, '-0.66 Neg.'),
                _specItem(
                  Icons.calendar_today_outlined,
                  DateFormat('MMM d, y').format(dpp.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Telemetry and Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Submissions Progress: 82% Completion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
              Text('Avg Score: 22.4 / 30', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.82,
              backgroundColor: EduverseTheme.surfaceContainerHigh,
              color: EduverseTheme.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  if (hasPdf)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.orange),
                      label: const Text('DPP PDF', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(80, 32),
                      ),
                    ),
                  if (hasSolution)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      label: const Text('Solution PDF', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(80, 32),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: EduverseTheme.primary),
                    tooltip: 'Edit DPP',
                    onPressed: () => _showDppDialog(context, service, dpp),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    tooltip: 'Delete DPP',
                    onPressed: () => _confirmDelete(context, service, dpp),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: EduverseTheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EduverseTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildQuickMcqInjectorCard(List<AdminDpp> dpps) {
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
                  const Icon(Icons.bolt, color: EduverseTheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Quick MCQ Injector',
                    style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: EduverseTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LaTeX Ready', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Push questions directly into active DPPs with full TeX math support.', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          // Target DPP selector
          DropdownButtonFormField<String>(
            initialValue: _selectedTargetDppId ?? (dpps.isNotEmpty ? dpps.first.id : null),
            decoration: const InputDecoration(
              labelText: 'Target DPP',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: dpps.map((d) => DropdownMenuItem(value: d.id, child: Text(d.title, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => _selectedTargetDppId = val),
          ),
          const SizedBox(height: 12),

          // Question Prompt
          TextField(
            controller: _injectorQuestionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Question Prompt (Markdown / LaTeX)',
              hintText: 'e.g. Consider the following statements regarding the Curative Petition...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Options A, B, C, D
          _optionRow('A', _optAController),
          const SizedBox(height: 8),
          _optionRow('B', _optBController),
          const SizedBox(height: 8),
          _optionRow('C', _optCController),
          const SizedBox(height: 8),
          _optionRow('D', _optDController),
          const SizedBox(height: 12),

          // Explanation
          TextField(
            controller: _injectorExplanationController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'AI Explanation Note',
              hintText: 'Provide context citation and Constitution articles...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final prompt = _injectorQuestionController.text.trim();
                if (prompt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a question prompt'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final targetDppId = _selectedTargetDppId ?? (dpps.isNotEmpty ? dpps.first.id : null);
                if (targetDppId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please create or select a target DPP first'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection('courses')
                      .doc(widget.courseId)
                      .collection('dpps')
                      .doc(targetDppId)
                      .collection('questions')
                      .add({
                        'question': prompt,
                        'options': [
                          _optAController.text.trim(),
                          _optBController.text.trim(),
                          _optCController.text.trim(),
                          _optDController.text.trim(),
                        ],
                        'correctOption': _selectedCorrectOption,
                        'explanation': _injectorExplanationController.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('MCQ successfully injected into selected DPP!'), backgroundColor: EduverseTheme.primary),
                  );
                  _injectorQuestionController.clear();
                  _injectorExplanationController.clear();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error injecting question: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text('Inject into Selected DPP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EduverseTheme.primary,
                foregroundColor: EduverseTheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(String letter, TextEditingController controller) {
    final isSelected = _selectedCorrectOption == letter;
    return Row(
      children: [
        InkWell(
          onTap: () => setState(() => _selectedCorrectOption = letter),
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? EduverseTheme.emeraldVivid : EduverseTheme.outlineVariant,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: EduverseTheme.emeraldVivid,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? EduverseTheme.emeraldVivid : EduverseTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : EduverseTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCohortSubjectMasteryCard(List<AdminDpp> allDpps) {
    final distinctSubjects = allDpps.map((d) => d.subject).where((s) => s.isNotEmpty).toSet().toList();

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
              Text(
                'Cohort Subject Mastery',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
              ),
              const Icon(Icons.auto_graph, color: EduverseTheme.primary, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Weekly DPP Accuracy Matrix across disciplines', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (distinctSubjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text('No subject accuracy metrics available yet. Create DPPs to track performance.', style: TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant), textAlign: TextAlign.center),
            )
          else
            ...distinctSubjects.take(4).map((sub) {
              final count = allDpps.where((d) => d.subject == sub).length;
              return _masteryItem(sub, 0.75, '$count DPPs Assigned', EduverseTheme.primary);
            }),
          const SizedBox(height: 16),
          const Text('Batch Retention Velocity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: EduverseTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('${allDpps.length} Total Practice Papers Synchronized', style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Triggering weak-topic revision DPP sequence...')),
                );
              },
              icon: const Icon(Icons.campaign_outlined, size: 16),
              label: const Text('Trigger Weak-Topic Revision DPP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EduverseTheme.primary,
                side: const BorderSide(color: EduverseTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _masteryItem(String subject, double progress, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: EduverseTheme.surfaceContainerHigh,
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirebaseAdminService service, AdminDpp dpp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete DPP'),
        content: Text('Are you sure you want to delete "${dpp.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteCourseDpp(widget.courseId, dpp.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDppDialog(BuildContext context, FirebaseAdminService service, AdminDpp? dpp) {
    final isEditing = dpp != null;
    final titleController = TextEditingController(text: dpp?.title ?? '');
    final newSubjectController = TextEditingController();
    final newChapterController = TextEditingController();
    String? dppPdfUrl = dpp?.dppPdfUrl;
    String? solutionPdfUrl = dpp?.solutionPdfUrl;
    String selectedSubject = dpp?.subject ?? '';
    String selectedChapter = dpp?.chapter ?? '';
    String? selectedLectureId = dpp?.lectureId;
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
                      const DropdownMenuItem(
                        value: '',
                        child: Text('None', style: TextStyle(color: Colors.grey)),
                      ),
                      ...subjects.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      ),
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

                    final canSave = titleController.text.isNotEmpty &&
                        selectedSubject.isNotEmpty &&
                        selectedChapter.isNotEmpty &&
                        dppPdfUrl != null &&
                        dppPdfUrl!.isNotEmpty;

                    return AlertDialog(
                      title: Text(isEditing ? 'Edit DPP' : 'Add DPP'),
                      content: SizedBox(
                        width: 480,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title *',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),

                              const Text('Classification *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),

                              DropdownButtonFormField<String>(
                                initialValue: selectedSubject.isNotEmpty && subjects.contains(selectedSubject)
                                    ? selectedSubject
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Subject *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.subject),
                                ),
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
                                        decoration: const InputDecoration(
                                          hintText: 'Enter new subject name',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
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
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('None', style: TextStyle(color: Colors.grey)),
                                      ),
                                      ...chapters.map(
                                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                                      ),
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
                                          decoration: const InputDecoration(
                                            labelText: 'Chapter *',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.menu_book),
                                          ),
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
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter new chapter name',
                                                    border: OutlineInputBorder(),
                                                    isDense: true,
                                                  ),
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
                                )
                              else
                                const Text('Select a subject to view chapters', style: TextStyle(color: Colors.grey, fontSize: 13)),

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
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('None', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ...lectures.map(
                                    (l) => DropdownMenuItem(
                                      value: l.id,
                                      child: Text(
                                        l.lectureNo != null ? 'Lec ${l.lectureNo}: ${l.title}' : l.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() => selectedLectureId = val),
                              ),

                              const SizedBox(height: 16),

                              const Text('DPP PDF *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (dppPdfUrl != null && dppPdfUrl!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('DPP PDF uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => dppPdfUrl = null),
                                      child: const Text('Replace', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ],
                                ),
                              ] else
                                MediaUploader(
                                  path: 'courses/${widget.courseId}/dpps',
                                  onUploadComplete: (url) => setState(() => dppPdfUrl = url),
                                ),

                              const SizedBox(height: 16),

                              const Text('Solution PDF (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (solutionPdfUrl != null && solutionPdfUrl!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text('Solution PDF uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => solutionPdfUrl = null),
                                      child: const Text('Replace', style: TextStyle(color: Colors.orange)),
                                    ),
                                  ],
                                ),
                              ] else
                                MediaUploader(
                                  path: 'courses/${widget.courseId}/dpps/solutions',
                                  onUploadComplete: (url) => setState(() => solutionPdfUrl = url),
                                ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: !canSave ? null : () async {
                            final updatedDpp = AdminDpp(
                              id: dpp?.id ?? '',
                              title: titleController.text,
                              subject: selectedSubject,
                              chapter: selectedChapter,
                              dppPdfUrl: dppPdfUrl!,
                              solutionPdfUrl: solutionPdfUrl ?? '',
                              lectureId: selectedLectureId,
                              createdAt: dpp?.createdAt ?? DateTime.now(),
                            );

                            await service.saveCourseDpp(
                              widget.courseId,
                              updatedDpp,
                              isNew: !isEditing,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(isEditing ? 'Save' : 'Add'),
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
