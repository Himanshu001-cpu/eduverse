import 'package:flutter/material.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

class TestSettingsDrawer extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController instructionsController;
  final TextEditingController marksPerQuestionController;
  final TextEditingController negativeMarkingController;
  final String testCategory;
  final String testSubject;
  final List<String> categories;
  final List<String> subjects;
  final Duration timeLimit;
  final DateTime? scheduledAt;
  final bool saveToLibrary;
  final bool shuffleOptions;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSubjectChanged;
  final VoidCallback onPromptNewSubject;
  final ValueChanged<Duration> onDurationChanged;
  final ValueChanged<DateTime?> onScheduleChanged;
  final ValueChanged<bool> onSaveToLibraryChanged;
  final ValueChanged<bool> onShuffleOptionsChanged;
  final VoidCallback onClose;

  const TestSettingsDrawer({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.instructionsController,
    required this.marksPerQuestionController,
    required this.negativeMarkingController,
    required this.testCategory,
    required this.testSubject,
    required this.categories,
    required this.subjects,
    required this.timeLimit,
    this.scheduledAt,
    required this.saveToLibrary,
    required this.shuffleOptions,
    required this.onCategoryChanged,
    required this.onSubjectChanged,
    required this.onPromptNewSubject,
    required this.onDurationChanged,
    required this.onScheduleChanged,
    required this.onSaveToLibraryChanged,
    required this.onShuffleOptionsChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 440,
      backgroundColor: EduverseColors.surfaceBright,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: EduverseColors.surfaceContainerLowest,
                border: Border(
                  bottom: BorderSide(
                    color: EduverseColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: EduverseColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Test Configuration',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: EduverseColors.deepNavy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    tooltip: 'Close Settings',
                  ),
                ],
              ),
            ),

            // Scrollable Settings Form
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Title
                  _buildFieldLabel('Test Title (Required)'),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Mock #19 — Indian Economy & Fiscal Union',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Category & Subject
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Exam Category'),
                            DropdownButtonFormField<String>(
                              initialValue: testCategory,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: categories
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) onCategoryChanged(v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Subject'),
                            DropdownButtonFormField<String>(
                              initialValue: testSubject.isNotEmpty && subjects.contains(testSubject)
                                  ? testSubject
                                  : null,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              hint: const Text('Subject'),
                              items: [
                                ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                                const DropdownMenuItem(
                                  value: '__add_new__',
                                  child: Text('+ Add New', style: TextStyle(color: Colors.blue)),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == '__add_new__') {
                                  onPromptNewSubject();
                                } else if (v != null) {
                                  onSubjectChanged(v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Marks & Negative Marking
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Marks / Q'),
                            TextFormField(
                              controller: marksPerQuestionController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '2.0',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.star_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Negative Penalty'),
                            TextFormField(
                              controller: negativeMarkingController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0.66',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.remove_circle_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Time Limit Duration Picker
                  _buildFieldLabel('Time Limit Allocation'),
                  _buildDurationPicker(context),
                  const SizedBox(height: 20),

                  // Scheduling Picker
                  _buildFieldLabel('Schedule Broadcast Date & Time'),
                  _buildSchedulingPicker(context),
                  const SizedBox(height: 20),

                  // Description
                  _buildFieldLabel('Description'),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Brief summary of coverage, chapters, and syllabus...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instructions
                  _buildFieldLabel('Student Exam Instructions'),
                  TextFormField(
                    controller: instructionsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Rules, instructions regarding negative marks, rough sheet, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Exam Experience & Security Protocol Toggles
                  Text(
                    'EXAM PROTOCOL & POOLING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: EduverseColors.outline,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Option Shuffle Toggle
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: EduverseColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: SwitchListTile(
                      title: const Text('Option Shuffle / Permutation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Randomize answer option order per student to discourage copying.', style: TextStyle(fontSize: 12)),
                      secondary: const Icon(Icons.shuffle, color: EduverseColors.primary),
                      value: shuffleOptions,
                      onChanged: onShuffleOptionsChanged,
                      dense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Save to Library Toggle
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: EduverseColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: SwitchListTile(
                      title: const Text('Save to Global Quiz Pool', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Makes this test available for import in other batches and courses.', style: TextStyle(fontSize: 12)),
                      secondary: const Icon(Icons.library_books_rounded, color: EduverseColors.secondary),
                      value: saveToLibrary,
                      onChanged: onSaveToLibraryChanged,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: EduverseColors.deepNavy,
        ),
      ),
    );
  }

  Widget _buildDurationPicker(BuildContext context) {
    final hours = timeLimit.inHours;
    final minutes = timeLimit.inMinutes % 60;
    final seconds = timeLimit.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EduverseColors.surfaceContainerLowest,
        border: Border.all(color: EduverseColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: EduverseColors.primary),
          const SizedBox(width: 12),
          _buildDurationField('Hrs', hours, (val) {
            onDurationChanged(Duration(hours: val, minutes: minutes, seconds: seconds));
          }),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          _buildDurationField('Mins', minutes, (val) {
            onDurationChanged(Duration(hours: hours, minutes: val, seconds: seconds));
          }),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          _buildDurationField('Secs', seconds, (val) {
            onDurationChanged(Duration(hours: hours, minutes: minutes, seconds: val));
          }),
          const Spacer(),
          if (timeLimit > Duration.zero)
            TextButton(
              onPressed: () => onDurationChanged(Duration.zero),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationField(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        SizedBox(
          width: 50,
          child: TextFormField(
            key: ValueKey('duration-$label-$value'),
            initialValue: value.toString().padLeft(2, '0'),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSchedulingPicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: scheduledAt ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null) return;

        if (!context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: scheduledAt != null
              ? TimeOfDay.fromDateTime(scheduledAt!)
              : TimeOfDay.now(),
        );
        if (time == null) return;

        onScheduleChanged(
          DateTime(date.year, date.month, date.day, time.hour, time.minute),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EduverseColors.surfaceContainerLowest,
          border: Border.all(color: EduverseColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: EduverseColors.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                scheduledAt != null
                    ? '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year} at ${scheduledAt!.hour.toString().padLeft(2, '0')}:${scheduledAt!.minute.toString().padLeft(2, '0')} IST'
                    : 'Set Broadcast Date & Time',
                style: TextStyle(
                  color: scheduledAt != null ? EduverseColors.deepNavy : EduverseColors.outline,
                  fontWeight: scheduledAt != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (scheduledAt != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => onScheduleChanged(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
