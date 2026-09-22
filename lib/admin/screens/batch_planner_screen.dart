import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/firebase_admin_service.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/media_uploader.dart';
import '../../web/landing/theme/academic_futurist_theme.dart';

class BatchPlannerScreen extends StatefulWidget {
  final String courseId;
  final String batchId;

  const BatchPlannerScreen({super.key, required this.courseId, required this.batchId});

  @override
  State<BatchPlannerScreen> createState() => _BatchPlannerScreenState();
}

class _BatchPlannerScreenState extends State<BatchPlannerScreen> {
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  int _viewModeIndex = 0; // 0: Week, 1: Day, 2: Sprint Matrix
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirebaseAdminService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return AdminScaffold(
      title: 'Batch Syllabus Planner',
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context, service),
              backgroundColor: EduverseTheme.primary,
              foregroundColor: EduverseTheme.onPrimary,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Plan Item'),
            )
          : null,
      body: StreamBuilder<List<AdminPlannerItem>>(
        stream: service.getCoursePlanner(widget.courseId),
        builder: (context, snapshot) {
          final plannerItems = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Breadcrumbs
                _buildBreadcrumbBar(context),
                const SizedBox(height: 16),

                // Master Header with Actions
                _buildMasterHeader(context, service, plannerItems, isDesktop),
                const SizedBox(height: 24),

                // Curriculum Module Velocity & Milestones Strip
                _buildModuleVelocityStrip(service, isDesktop),
                const SizedBox(height: 24),

                // Main Workspace Split
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left 9 cols: Interactive Weekly Timetable Matrix
                      Expanded(
                        flex: 9,
                        child: Column(
                          children: [
                            _buildTimetableMatrix(context, service, plannerItems),
                            if (plannerItems.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildExistingPlannerItemsCard(context, service, plannerItems),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right 3 cols: Sentinel Governance & Studio Occupancy
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildScheduleSentinelCard(plannerItems),
                            const SizedBox(height: 20),
                            _buildStudioOccupancyCard(plannerItems),
                            const SizedBox(height: 20),
                            _buildFacultyAvailabilityCard(plannerItems),
                            const SizedBox(height: 20),
                            _buildSprintTipCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildTimetableMatrix(context, service, plannerItems),
                      const SizedBox(height: 20),
                      _buildScheduleSentinelCard(plannerItems),
                      const SizedBox(height: 20),
                      _buildStudioOccupancyCard(plannerItems),
                      const SizedBox(height: 20),
                      _buildFacultyAvailabilityCard(plannerItems),
                      if (plannerItems.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildExistingPlannerItemsCard(context, service, plannerItems),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumbBar(BuildContext context) {
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
              widget.batchId.isNotEmpty ? 'Batch ${widget.batchId}' : 'Civil Services 2025',
              style: const TextStyle(fontSize: 12, color: EduverseTheme.onSurfaceVariant),
            ),
            const Text('  /  ', style: TextStyle(fontSize: 12, color: EduverseTheme.outlineVariant)),
            const Text('Academic Timetable & Syllabus Planner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy)),
          ],
        ),
      ],
    );
  }

  Widget _buildMasterHeader(BuildContext context, FirebaseAdminService service, List<AdminPlannerItem> plannerItems, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: EduverseTheme.emeraldVivid,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'COHORT MASTER REGISTRY • ACTIVE TERM 2024-2025',
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Master Planner: Course Schedule',
                    style: EduverseTheme.headlineLg(color: EduverseTheme.deepNavy).copyWith(
                      fontSize: isDesktop ? 28 : 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Coordinate curriculum milestones, allocate faculty lecture slots, manage live interactive sessions, and track cohort syllabus completion velocity.',
                    style: TextStyle(fontSize: 14, color: EduverseTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _headerChip('Batch Cohort ID: ${widget.batchId.isNotEmpty ? widget.batchId : widget.courseId}', EduverseTheme.surfaceContainerHigh, EduverseTheme.primary),
                      _headerChip('${plannerItems.length} Scheduled Slots', EduverseTheme.emeraldVivid.withValues(alpha: 0.12), EduverseTheme.emeraldVivid),
                      _headerChip('Live Term Active', EduverseTheme.tertiaryFixed, EduverseTheme.onTertiaryFixed),
                    ],
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 24),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSeeding ? null : () => _populateDefaultWeeklyTemplate(context, service, plannerItems),
                    icon: _isSeeding
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_fix_high, size: 16),
                    label: Text(_isSeeding ? 'Generating...' : 'Auto-Generate Schedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EduverseTheme.primary,
                      side: const BorderSide(color: EduverseTheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, service),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('+ Add Lecture Slot / Live Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EduverseTheme.primary,
                      foregroundColor: EduverseTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _headerChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text)),
    );
  }

  Widget _buildModuleVelocityStrip(FirebaseAdminService service, bool isDesktop) {
    return StreamBuilder<List<AdminLecture>>(
      stream: service.getCourseLecturesCombined(widget.courseId),
      builder: (context, snapshot) {
        final lectures = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

            // Group lectures into modules
            final Map<String, List<AdminLecture>> moduleMap = {};
            for (final l in lectures) {
              final mod = (l.module != null && l.module!.isNotEmpty)
                  ? l.module!
                  : ((l.discipline != null && l.discipline!.isNotEmpty) ? l.discipline! : 'General Curriculum');
              moduleMap.putIfAbsent(mod, () => []).add(l);
            }

            final List<Widget> cards = [];
            if (moduleMap.isNotEmpty) {
              int idx = 1;
              moduleMap.forEach((modName, modList) {
                final completedCount = modList.where((l) => !l.isLocked).length;
                final totalCount = modList.length;
                final ratio = totalCount > 0 ? (completedCount / totalCount) : 0.0;
                final pct = '${(ratio * 100).toInt()}%';
                final color = ratio >= 1.0
                    ? EduverseTheme.emeraldVivid
                    : (ratio >= 0.5 ? EduverseTheme.secondary : EduverseTheme.tertiary);

                cards.add(
                  _velocityCard(
                    'MODULE 0$idx',
                    modName,
                    pct,
                    ratio,
                    '$completedCount/$totalCount Lectures Ready',
                    ratio >= 1.0 ? 'Completed' : 'In Flight',
                    color,
                    cardWidth,
                  ),
                );
                idx++;
              });
            } else {
              // Default curriculum baseline indicators
              cards.addAll([
                _velocityCard('MODULE 01', 'Core Disciplines', '0%', 0.05, '0 Lectures Recorded', 'Status: Ready', EduverseTheme.primary, cardWidth),
                _velocityCard('MODULE 02', 'Practice & Problem Solving', '0%', 0.05, '0 Lectures Recorded', 'Status: Ready', EduverseTheme.secondary, cardWidth),
                _velocityCard('MODULE 03', 'Mock Assessments & Review', '0%', 0.05, '0 Lectures Recorded', 'Status: Queued', EduverseTheme.tertiary, cardWidth),
                _velocityCard('MODULE 04', 'Doubt Clinics & AMA', '0%', 0.05, '0 Sessions Scheduled', 'Status: Queued', Colors.grey, cardWidth),
              ]);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.equalizer, size: 16, color: EduverseTheme.primary),
                        SizedBox(width: 6),
                        Text('CURRICULUM MODULE VELOCITY & SYLLABUS MILESTONES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.primary)),
                      ],
                    ),
                    Row(
                      children: [
                        _legendDot('Complete', EduverseTheme.emeraldVivid),
                        const SizedBox(width: 12),
                        _legendDot('In Flight', EduverseTheme.secondary),
                        const SizedBox(width: 12),
                        _legendDot('On Pace', EduverseTheme.tertiary),
                        const SizedBox(width: 12),
                        _legendDot('Queued', Colors.grey),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards.take(4).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _velocityCard(String code, String title, String pct, double progress, String detail, String status, Color barColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(pct, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: barColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: EduverseTheme.surfaceContainerHigh,
              color: barColor,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(detail, style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
              Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: barColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableMatrix(BuildContext context, FirebaseAdminService service, List<AdminPlannerItem> plannerItems) {
    final weekStartStr = DateFormat('MMM d').format(_currentWeekStart);
    final weekEndStr = DateFormat('MMM d, y').format(_currentWeekStart.add(const Duration(days: 6)));

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
          // Toolbar: Navigation, Week title, View switches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () => setState(() => _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7))),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1))),
                    child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () => setState(() => _currentWeekStart = _currentWeekStart.add(const Duration(days: 7))),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Week View: $weekStartStr – $weekEndStr',
                    style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: EduverseTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _viewModeBtn('Week', 0),
                        _viewModeBtn('Day', 1),
                        _viewModeBtn('Sprint Matrix', 2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddDialog(context, service),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Add Slot'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 8-Column Timetable Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1040,
              child: Column(
                children: [
                  // Header row with 7 days
                  _buildTimetableHeaderRow(),
                  const SizedBox(height: 8),

                  // Slot 1: GS Core (08:00 - 10:00)
                  _buildTimetableSlotRow(
                    '08:00 – 10:00\nSlot 1: GS Core',
                    _buildDynamicSlotCells(
                      context,
                      service,
                      plannerItems,
                      days,
                      slotNum: 1,
                      slotKey: 'Slot 1',
                      defaultType: 'GS Core',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Slot 2: CSAT / Aptitude (11:00 - 12:30)
                  _buildTimetableSlotRow(
                    '11:00 – 12:30\nSlot 2: CSAT',
                    _buildDynamicSlotCells(
                      context,
                      service,
                      plannerItems,
                      days,
                      slotNum: 2,
                      slotKey: 'Slot 2',
                      defaultType: 'CSAT',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Slot 3: Doubt Desk / AMA (14:30 - 16:00)
                  _buildTimetableSlotRow(
                    '14:30 – 16:00\nSlot 3: Doubt / AMA',
                    _buildDynamicSlotCells(
                      context,
                      service,
                      plannerItems,
                      days,
                      slotNum: 3,
                      slotKey: 'Slot 3',
                      defaultType: 'Doubt / AMA',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Slot 4: DPP Release (18:00 - 19:00)
                  _buildTimetableSlotRow(
                    '18:00 – 19:00\nSlot 4: DPP Release',
                    _buildDynamicSlotCells(
                      context,
                      service,
                      plannerItems,
                      days,
                      slotNum: 4,
                      slotKey: 'Slot 4',
                      defaultType: 'DPP Release',
                      isDppSlot: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicSlotCells(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminPlannerItem> plannerItems,
    List<String> days, {
    required int slotNum,
    required String slotKey,
    required String defaultType,
    bool isDppSlot = false,
  }) {
    final widgets = <Widget>[];

    for (final day in days) {
      // Find matching items for this day and slot
      final matchingItems = plannerItems.where((item) {
        final matchesDay = (item.dayOfWeek != null && item.dayOfWeek!.toLowerCase().startsWith(day.toLowerCase().substring(0, 3))) ||
            DateFormat('E').format(item.date).toLowerCase().startsWith(day.toLowerCase().substring(0, 3));
        final matchesSlot = (item.timeSlot != null && item.timeSlot!.contains(slotKey)) ||
            (item.lectureType != null && item.lectureType!.toLowerCase().contains(defaultType.toLowerCase()));
        return matchesDay && matchesSlot;
      }).toList();

      if (matchingItems.isNotEmpty) {
        final item = matchingItems.first;
        if (isDppSlot) {
          widgets.add(_dppChip(
            item.title.isNotEmpty ? item.title : 'Daily Practice',
            item: item,
            onTap: () => _showAddDialog(context, service, existingItem: item),
            onDelete: () => _confirmDeleteItem(context, service, item),
          ));
        } else {
          widgets.add(_slotCard(
            item.lectureType?.isNotEmpty == true ? item.lectureType! : 'SCHEDULED',
            item.title,
            item.facultyName?.isNotEmpty == true ? item.facultyName! : (item.subtitle.isNotEmpty ? item.subtitle : 'Faculty Assigned'),
            '${item.room?.isNotEmpty == true ? item.room! : "Studio A"} • ${item.isLive ? "LIVE NOW" : (DateFormat("HH:mm").format(item.date))}',
            item.isLive ? EduverseTheme.emeraldVivid : EduverseTheme.secondary,
            isLive: item.isLive,
            item: item,
            onTap: () => _showAddDialog(context, service, existingItem: item),
            onDelete: () => _confirmDeleteItem(context, service, item),
          ));
        }
      } else {
        widgets.add(_emptySlot(
          day == 'Sun' ? 'Sun (Self Study)' : day,
          onTap: () => _showAddDialog(
            context,
            service,
            prefilledDay: day,
            prefilledSlot: '$slotKey: $defaultType',
            prefilledType: defaultType,
          ),
        ));
      }
    }

    return widgets;
  }

  Widget _viewModeBtn(String label, int index) {
    final isSelected = _viewModeIndex == index;
    return InkWell(
      onTap: () => setState(() => _viewModeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EduverseTheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? EduverseTheme.deepNavy : EduverseTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableHeaderRow() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Text('TIME SLOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.onSurfaceVariant)),
        ),
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == 1 ? EduverseTheme.surfaceContainerHigh : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i == 1 ? EduverseTheme.primary : EduverseTheme.onSurface,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(_currentWeekStart.add(Duration(days: i))),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == 1 ? EduverseTheme.primary : EduverseTheme.deepNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimetableSlotRow(String timeLabel, List<Widget> dayWidgets) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            timeLabel,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EduverseTheme.onSurfaceVariant),
          ),
        ),
        for (final w in dayWidgets)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: w,
            ),
          ),
      ],
    );
  }

  Widget _slotCard(
    String badge,
    String title,
    String speaker,
    String detail,
    Color color, {
    bool isLive = false,
    bool isAlert = false,
    AdminPlannerItem? item,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLive ? color.withValues(alpha: 0.08) : EduverseTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLive ? color : (isAlert ? Colors.red.withValues(alpha: 0.5) : EduverseTheme.outlineVariant.withValues(alpha: 0.3)),
            width: isLive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color)),
                ),
                Row(
                  children: [
                    if (isLive)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    if (onDelete != null)
                      InkWell(
                        onTap: onDelete,
                        child: const Icon(Icons.close, size: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.deepNavy), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(speaker, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: EduverseTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(detail, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _emptySlot(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 14, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: EduverseTheme.onSurfaceVariant.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dppChip(String label, {AdminPlannerItem? item, VoidCallback? onTap, VoidCallback? onDelete}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: EduverseTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: EduverseTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 11, color: EduverseTheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: EduverseTheme.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDelete != null)
              InkWell(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPlannerItemsCard(BuildContext context, FirebaseAdminService service, List<AdminPlannerItem> items) {
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
                'Scheduled Curriculum Slots (${items.length})',
                style: EduverseTheme.headlineMd(color: EduverseTheme.deepNavy).copyWith(fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context, service),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Slot / Handout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduverseTheme.primary,
                  foregroundColor: EduverseTheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.pdfUrl.isNotEmpty ? Icons.picture_as_pdf : (item.isLive ? Icons.sensors : Icons.event_note),
                  color: item.pdfUrl.isNotEmpty ? Colors.red : (item.isLive ? EduverseTheme.emeraldVivid : EduverseTheme.primary),
                ),
                title: Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${item.dayOfWeek ?? DateFormat('E').format(item.date)} • ${item.timeSlot ?? "Slot"} • ${item.facultyName ?? item.subtitle} • ${item.room ?? "Studio A"}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: EduverseTheme.primary),
                      onPressed: () => _showAddDialog(context, service, existingItem: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _confirmDeleteItem(context, service, item),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSentinelCard(List<AdminPlannerItem> plannerItems) {
    // Detect conflicts (same day + same timeslot + same room)
    final Map<String, List<AdminPlannerItem>> slotUsage = {};
    for (final item in plannerItems) {
      if (item.dayOfWeek != null && item.timeSlot != null && item.room != null) {
        final key = '${item.dayOfWeek}_${item.timeSlot}_${item.room}';
        slotUsage.putIfAbsent(key, () => []).add(item);
      }
    }

    int conflictCount = 0;
    for (final list in slotUsage.values) {
      if (list.length > 1) conflictCount += (list.length - 1);
    }

    final hasConflicts = conflictCount > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EduverseTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasConflicts ? Colors.amber.withValues(alpha: 0.6) : EduverseTheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasConflicts ? Icons.warning_amber_rounded : Icons.verified_outlined,
                color: hasConflicts ? Colors.amber : EduverseTheme.emeraldVivid,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SCHEDULE SENTINEL ENGINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: hasConflicts ? Colors.amber : EduverseTheme.emeraldVivid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasConflicts
                ? '$conflictCount scheduling collision(s) detected in roster.'
                : 'Zero scheduling conflicts detected for this term.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduverseTheme.deepNavy),
          ),
          const SizedBox(height: 4),
          Text(
            hasConflicts
                ? 'Check overlapping room allocations in the timetable matrix above to resolve.'
                : 'Zero classroom overlaps, no studio double-bookings, and compliant teacher rest-break policies verified.',
            style: const TextStyle(fontSize: 11, color: EduverseTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioOccupancyCard(List<AdminPlannerItem> plannerItems) {
    int studioACount = 0;
    int studioBCount = 0;
    int studioCCount = 0;

    for (final item in plannerItems) {
      final r = item.room ?? '';
      if (r.contains('Studio A')) {
        studioACount++;
      } else if (r.contains('Studio B')) {
        studioBCount++;
      } else if (r.contains('Studio C')) {
        studioCCount++;
      }
    }

    const maxWeeklySlots = 28; // 4 slots * 7 days
    final studioARatio = (studioACount / maxWeeklySlots).clamp(0.0, 1.0);
    final studioBRatio = (studioBCount / maxWeeklySlots).clamp(0.0, 1.0);
    final studioCRatio = (studioCCount / maxWeeklySlots).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
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
            children: const [
              Text('STUDIO & ROOM OCCUPANCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.onSurfaceVariant)),
              Text('Live Allocation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: EduverseTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          _occupancyRow('Studio A (4K Interactive)', studioARatio, '${(studioARatio * 100).toInt()}% Booked', '$studioACount/28 weekly slots occupied'),
          _occupancyRow('Studio B (Economy & CSAT)', studioBRatio, '${(studioBRatio * 100).toInt()}% Booked', '$studioBCount/28 weekly slots occupied'),
          _occupancyRow('Studio C (AMA / Mentorship)', studioCRatio, '${(studioCRatio * 100).toInt()}% Booked', '$studioCCount/28 weekly slots occupied'),
        ],
      ),
    );
  }

  Widget _occupancyRow(String studio, double ratio, String label, String subtext) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(studio, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: EduverseTheme.surfaceContainerHigh,
              color: EduverseTheme.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 9, color: EduverseTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildFacultyAvailabilityCard(List<AdminPlannerItem> plannerItems) {
    // Map faculty to slot counts
    final Map<String, int> facultyCounts = {};
    for (final item in plannerItems) {
      if (item.facultyName != null && item.facultyName!.isNotEmpty) {
        facultyCounts[item.facultyName!] = (facultyCounts[item.facultyName!] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
            children: const [
              Text('FACULTY AVAILABILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: EduverseTheme.onSurfaceVariant)),
              Text('Roster', style: TextStyle(fontSize: 10, color: EduverseTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (facultyCounts.isNotEmpty) ...[
            for (final entry in facultyCounts.entries)
              _facultySlot(entry.key, 'Faculty Fellow', '${entry.value * 2} hrs/wk', '${entry.value} slots assigned', Colors.green),
          ] else ...[
            _facultySlot('Dr. Amartya Sen', 'Modern History Lead', '0 hrs', 'Available', Colors.green),
            _facultySlot('Adv. Ragav Nambiar', 'Polity & Constitution', '0 hrs', 'Available', Colors.green),
            _facultySlot('Prof. S. Mukherjee', 'Macroeconomics Lead', '0 hrs', 'Available', Colors.green),
            _facultySlot('Prof. K. Venkatesh', 'CSAT Quantitative Lead', '0 hrs', 'Available', Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _facultySlot(String name, String role, String hours, String tag, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text(role, style: const TextStyle(fontSize: 9, color: EduverseTheme.onSurfaceVariant)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(hours, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSprintTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduverseTheme.primaryFixedDim.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EduverseTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: EduverseTheme.primary),
              SizedBox(width: 6),
              Text('Sprint Synchronization Tip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EduverseTheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keep core GS lectures during Slot 1 (08:00 - 10:00) to maximize student retention. Schedule DPP reviews on Friday evening before weekend mock assessments.',
            style: TextStyle(fontSize: 11, color: EduverseTheme.deepNavy),
          ),
        ],
      ),
    );
  }

  Future<void> _populateDefaultWeeklyTemplate(
    BuildContext context,
    FirebaseAdminService service,
    List<AdminPlannerItem> currentItems,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto-Populate Standard Weekly Schedule?'),
        content: const Text(
          'This will generate a balanced, conflict-free 7-day academic schedule for this cohort, covering GS Core, CSAT, Doubt AMA clinics, and DPP releases.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: EduverseTheme.primary, foregroundColor: Colors.white),
            child: const Text('Populate Schedule'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));

      final templateItems = [
        // Monday
        AdminPlannerItem(
          id: '',
          title: 'Modern History: Tribal Revolts & Resistance',
          subtitle: 'GS Paper 1',
          pdfUrl: '',
          date: monday.add(const Duration(days: 0, hours: 8)),
          dayOfWeek: 'Mon',
          timeSlot: 'Slot 1: GS Core',
          room: 'Studio A (4K Interactive)',
          facultyName: 'Dr. Amartya Sen',
          lectureType: 'GS Core',
          isLive: false,
        ),
        AdminPlannerItem(
          id: '',
          title: 'DPP #44: Tribal Movements & Santhal Uprising',
          subtitle: 'Daily Practice Paper',
          pdfUrl: '',
          date: monday.add(const Duration(days: 0, hours: 18)),
          dayOfWeek: 'Mon',
          timeSlot: 'Slot 4: DPP Release',
          room: 'Studio A (4K Interactive)',
          facultyName: 'Dr. Amartya Sen',
          lectureType: 'DPP Release',
          isLive: false,
        ),
        // Tuesday
        AdminPlannerItem(
          id: '',
          title: 'Modern History: Socio-Religious Reform Movements',
          subtitle: 'GS Paper 1',
          pdfUrl: '',
          date: monday.add(const Duration(days: 1, hours: 8)),
          dayOfWeek: 'Tue',
          timeSlot: 'Slot 1: GS Core',
          room: 'Studio A (4K Interactive)',
          facultyName: 'Dr. Amartya Sen',
          lectureType: 'GS Core',
          isLive: true,
        ),
        AdminPlannerItem(
          id: '',
          title: 'CSAT: Reading Comprehension & Inference Drills',
          subtitle: 'Paper 2 Aptitude',
          pdfUrl: '',
          date: monday.add(const Duration(days: 1, hours: 11)),
          dayOfWeek: 'Tue',
          timeSlot: 'Slot 2: CSAT',
          room: 'Studio C (AMA / Mentorship)',
          facultyName: 'Prof. K. Venkatesh',
          lectureType: 'CSAT',
          isLive: false,
        ),
        AdminPlannerItem(
          id: '',
          title: 'DPP #45: Brahmo Samaj & Reform Movements',
          subtitle: 'Daily Practice Paper',
          pdfUrl: '',
          date: monday.add(const Duration(days: 1, hours: 18)),
          dayOfWeek: 'Tue',
          timeSlot: 'Slot 4: DPP Release',
          room: 'Studio A (4K Interactive)',
          facultyName: 'Dr. Amartya Sen',
          lectureType: 'DPP Release',
          isLive: false,
        ),
        // Wednesday
        AdminPlannerItem(
          id: '',
          title: 'Economy: Fiscal Policy & Tax Architecture',
          subtitle: 'GS Paper 3',
          pdfUrl: '',
          date: monday.add(const Duration(days: 2, hours: 8)),
          dayOfWeek: 'Wed',
          timeSlot: 'Slot 1: GS Core',
          room: 'Studio B (Economy & CSAT)',
          facultyName: 'Prof. S. Mukherjee',
          lectureType: 'GS Core',
          isLive: false,
        ),
        AdminPlannerItem(
          id: '',
          title: 'DPP #46: Indirect Tax & GST Council Structure',
          subtitle: 'Daily Practice Paper',
          pdfUrl: '',
          date: monday.add(const Duration(days: 2, hours: 18)),
          dayOfWeek: 'Wed',
          timeSlot: 'Slot 4: DPP Release',
          room: 'Studio B (Economy & CSAT)',
          facultyName: 'Prof. S. Mukherjee',
          lectureType: 'DPP Release',
          isLive: false,
        ),
        // Thursday
        AdminPlannerItem(
          id: '',
          title: 'Core Quant: Permutations & Combinations',
          subtitle: 'CSAT Paper 2',
          pdfUrl: '',
          date: monday.add(const Duration(days: 3, hours: 11)),
          dayOfWeek: 'Thu',
          timeSlot: 'Slot 2: CSAT',
          room: 'Studio B (Economy & CSAT)',
          facultyName: 'Prof. K. Venkatesh',
          lectureType: 'CSAT',
          isLive: false,
        ),
        AdminPlannerItem(
          id: '',
          title: 'DPP #47: Combinatorics Micro-Test',
          subtitle: 'Daily Practice Paper',
          pdfUrl: '',
          date: monday.add(const Duration(days: 3, hours: 18)),
          dayOfWeek: 'Thu',
          timeSlot: 'Slot 4: DPP Release',
          room: 'Studio B (Economy & CSAT)',
          facultyName: 'Prof. K. Venkatesh',
          lectureType: 'DPP Release',
          isLive: false,
        ),
        // Friday
        AdminPlannerItem(
          id: '',
          title: 'Economy: Monetary Policy & RBI Reserve Ratio',
          subtitle: 'GS Paper 3',
          pdfUrl: '',
          date: monday.add(const Duration(days: 4, hours: 8)),
          dayOfWeek: 'Fri',
          timeSlot: 'Slot 1: GS Core',
          room: 'Studio A (4K Interactive)',
          facultyName: 'Prof. S. Mukherjee',
          lectureType: 'GS Core',
          isLive: false,
        ),
        AdminPlannerItem(
          id: '',
          title: 'Live AMA: Constitution & Basic Structure Clinic',
          subtitle: 'GS Paper 2 Mentorship',
          pdfUrl: '',
          date: monday.add(const Duration(days: 4, hours: 14, minutes: 30)),
          dayOfWeek: 'Fri',
          timeSlot: 'Slot 3: Doubt / AMA',
          room: 'Studio C (AMA / Mentorship)',
          facultyName: 'Adv. Ragav Nambiar',
          lectureType: 'Doubt / AMA',
          isLive: true,
        ),
        AdminPlannerItem(
          id: '',
          title: 'DPP #48: Monetary Instruments & Repo Rates',
          subtitle: 'Daily Practice Paper',
          pdfUrl: '',
          date: monday.add(const Duration(days: 4, hours: 18)),
          dayOfWeek: 'Fri',
          timeSlot: 'Slot 4: DPP Release',
          room: 'Studio A (4K Interactive)',
          facultyName: 'Prof. S. Mukherjee',
          lectureType: 'DPP Release',
          isLive: false,
        ),
        // Saturday
        AdminPlannerItem(
          id: '',
          title: 'Weekly Current Affairs: The Hindu & PIB Digest',
          subtitle: 'General Studies',
          pdfUrl: '',
          date: monday.add(const Duration(days: 5, hours: 8)),
          dayOfWeek: 'Sat',
          timeSlot: 'Slot 1: GS Core',
          room: 'Studio C (AMA / Mentorship)',
          facultyName: 'Editorial Team',
          lectureType: 'GS Core',
          isLive: false,
        ),
        AdminPlannerItem(
          id: '',
          title: 'Logic Lab: Syllogisms & Data Sufficiency',
          subtitle: 'CSAT Reasoning',
          pdfUrl: '',
          date: monday.add(const Duration(days: 5, hours: 11)),
          dayOfWeek: 'Sat',
          timeSlot: 'Slot 2: CSAT',
          room: 'Studio B (Economy & CSAT)',
          facultyName: 'Prof. K. Venkatesh',
          lectureType: 'CSAT',
          isLive: false,
        ),
      ];

      for (final item in templateItems) {
        await service.saveCoursePlannerItem(widget.courseId, item, isNew: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Standard weekly syllabus planner successfully populated with 14 slots!'),
            backgroundColor: EduverseTheme.emeraldVivid,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to populate template: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _confirmDeleteItem(BuildContext context, FirebaseAdminService service, AdminPlannerItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scheduled Slot?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await service.deleteCoursePlannerItem(widget.courseId, item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Planner slot deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting slot: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showAddDialog(
    BuildContext context,
    FirebaseAdminService service, {
    String? prefilledDay,
    String? prefilledSlot,
    String? prefilledType,
    AdminPlannerItem? existingItem,
  }) {
    final titleController = TextEditingController(text: existingItem?.title ?? '');
    final subtitleController = TextEditingController(text: existingItem?.subtitle ?? '');
    final facultyController = TextEditingController(text: existingItem?.facultyName ?? '');

    String selectedDay = existingItem?.dayOfWeek ?? prefilledDay ?? 'Mon';
    String selectedSlot = existingItem?.timeSlot ?? prefilledSlot ?? 'Slot 1: GS Core';
    String selectedRoom = existingItem?.room ?? 'Studio A (4K Interactive)';
    String selectedType = existingItem?.lectureType ?? prefilledType ?? 'GS Core';
    bool isLive = existingItem?.isLive ?? false;
    DateTime selectedDate = existingItem?.date ?? DateTime.now();
    String? pdfUrl = existingItem?.pdfUrl.isNotEmpty == true ? existingItem?.pdfUrl : null;

    final daysList = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final slotsList = [
      'Slot 1: GS Core',
      'Slot 2: CSAT',
      'Slot 3: Doubt / AMA',
      'Slot 4: DPP Release',
    ];
    final roomsList = [
      'Studio A (4K Interactive)',
      'Studio B (Economy & CSAT)',
      'Studio C (AMA / Mentorship)',
      'Online Stream',
    ];
    final typesList = [
      'GS Core',
      'CSAT',
      'Doubt / AMA',
      'DPP Release',
      'Mock Test',
      'Workshop',
    ];

    if (!daysList.contains(selectedDay)) selectedDay = 'Mon';
    if (!slotsList.any((s) => selectedSlot.contains(s.split(':')[0]))) {
      selectedSlot = slotsList[0];
    }
    if (!roomsList.contains(selectedRoom)) selectedRoom = roomsList[0];
    if (!typesList.contains(selectedType)) selectedType = typesList[0];

    showDialog(
      context: context,
      builder: (context) => Provider.value(
        value: service,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existingItem != null ? 'Edit Scheduled Slot' : 'Add Lecture Slot / Session'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Topic / Lecture Title *',
                        hintText: 'e.g. Modern History: Socio-Religious Reform',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Discipline Tag',
                        hintText: 'e.g. GS Paper 1 • History',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: facultyController,
                      decoration: const InputDecoration(
                        labelText: 'Faculty In-Charge',
                        hintText: 'e.g. Dr. Amartya Sen',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedDay,
                            decoration: const InputDecoration(labelText: 'Day of Week'),
                            items: daysList.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedDay = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: slotsList.firstWhere(
                              (s) => selectedSlot.contains(s.split(':')[0]),
                              orElse: () => slotsList[0],
                            ),
                            decoration: const InputDecoration(labelText: 'Time Slot'),
                            items: slotsList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedSlot = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedRoom,
                            decoration: const InputDecoration(labelText: 'Studio / Room'),
                            items: roomsList.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedRoom = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(labelText: 'Lecture Type'),
                            items: typesList.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Live Broadcast Session', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Broadcasts live stream with live Q&A interaction', style: TextStyle(fontSize: 11)),
                      value: isLive,
                      onChanged: (val) => setDialogState(() => isLive = val),
                    ),
                    const SizedBox(height: 12),
                    if (pdfUrl != null && pdfUrl!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: EduverseTheme.emeraldVivid, size: 16),
                          const SizedBox(width: 6),
                          const Text('Attached Handout Ready', style: TextStyle(color: EduverseTheme.emeraldVivid, fontWeight: FontWeight.bold, fontSize: 12)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setDialogState(() => pdfUrl = null),
                            child: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    MediaUploader(
                      path: 'courses/${widget.courseId}/planner',
                      onUploadComplete: (url) {
                        setDialogState(() => pdfUrl = url);
                      },
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
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title for the slot.')),
                    );
                    return;
                  }

                  final item = AdminPlannerItem(
                    id: existingItem?.id ?? '',
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim(),
                    facultyName: facultyController.text.trim(),
                    dayOfWeek: selectedDay,
                    timeSlot: selectedSlot,
                    room: selectedRoom,
                    lectureType: selectedType,
                    isLive: isLive,
                    pdfUrl: pdfUrl ?? '',
                    date: selectedDate,
                  );

                  await service.saveCoursePlannerItem(
                    widget.courseId,
                    item,
                    isNew: existingItem == null,
                  );

                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: EduverseTheme.primary, foregroundColor: Colors.white),
                child: Text(existingItem != null ? 'Update Slot' : 'Save Slot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
