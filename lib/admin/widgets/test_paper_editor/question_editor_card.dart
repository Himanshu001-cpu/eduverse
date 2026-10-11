import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/admin/models/test_quiz_models.dart' show TestSection;
import 'package:eduverse/admin/widgets/rich_document_editor.dart';
import 'package:eduverse/core/services/rich_text_service.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

class QuestionEditorCard extends StatelessWidget {
  final QuizQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final List<TestSection> sections;
  final List<String> subjects;
  final ValueChanged<QuizQuestion> onUpdateQuestion;
  final VoidCallback onDuplicateQuestion;
  final VoidCallback onDeleteQuestion;
  final VoidCallback? onPreviousQuestion;
  final VoidCallback onNextOrAddQuestion;
  final bool isLastQuestion;
  final VoidCallback onPromptNewSubject;

  const QuestionEditorCard({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.sections,
    required this.subjects,
    required this.onUpdateQuestion,
    required this.onDuplicateQuestion,
    required this.onDeleteQuestion,
    this.onPreviousQuestion,
    required this.onNextOrAddQuestion,
    required this.isLastQuestion,
    required this.onPromptNewSubject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EduverseColors.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EduverseColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top metadata bar
          _buildQuestionMetaHeader(context),
          const Divider(height: 1),

          // Main editor scrollable content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Question Prompt
                _buildPromptSection(context),
                const SizedBox(height: 24),

                // Section 2: Answer Options
                _buildAnswerOptionsSection(context),
                const SizedBox(height: 24),

                // Section 3: Explanation
                _buildExplanationSection(context),
              ],
            ),
          ),
          const Divider(height: 1),

          // Bottom Navigation & Actions bar
          _buildBottomActionBar(context),
        ],
      ),
    );
  }

  Widget _buildQuestionMetaHeader(BuildContext context) {
    final difficulty = question.difficulty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Left side: Q number badge, Subject, Section, Difficulty, Type
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Q badge
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EduverseColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Q${questionIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),

              // Difficulty selector pill
              _buildDifficultySelector(context, difficulty),

              // Answer Type selector
              DropdownButton<AnswerType>(
                value: question.answerType,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(8),
                items: const [
                  DropdownMenuItem(
                    value: AnswerType.multipleChoice,
                    child: Text('Multiple Choice (MCQ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  DropdownMenuItem(
                    value: AnswerType.trueFalse,
                    child: Text('True / False', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    onUpdateQuestion(question.copyWith(answerType: val));
                  }
                },
              ),

              // Section assignment selector
              if (sections.isNotEmpty)
                DropdownButton<String?>(
                  value: sections.any((s) => s.id == question.sectionId)
                      ? question.sectionId
                      : null,
                  underline: const SizedBox.shrink(),
                  hint: Text(
                    'No Section',
                    style: TextStyle(fontSize: 12, color: EduverseColors.outline),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Section (General)', style: TextStyle(fontSize: 13)),
                    ),
                    ...sections.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                  onChanged: (secId) {
                    onUpdateQuestion(
                      question.copyWith(
                        sectionId: secId,
                        clearSectionId: secId == null,
                      ),
                    );
                  },
                ),

              // Subject dropdown
              DropdownButton<String?>(
                value: question.subject != null && subjects.contains(question.subject)
                    ? question.subject
                    : null,
                underline: const SizedBox.shrink(),
                hint: Text('Subject', style: TextStyle(fontSize: 12, color: EduverseColors.outline)),
                borderRadius: BorderRadius.circular(8),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Subject', style: TextStyle(fontSize: 13)),
                  ),
                  ...subjects.map(
                    (sub) => DropdownMenuItem<String?>(
                      value: sub,
                      child: Text(sub, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const DropdownMenuItem<String?>(
                    value: '__add_new__',
                    child: Text('+ Add Subject', style: TextStyle(fontSize: 13, color: Colors.blue)),
                  ),
                ],
                onChanged: (val) {
                  if (val == '__add_new__') {
                    onPromptNewSubject();
                  } else {
                    onUpdateQuestion(question.copyWith(subject: val));
                  }
                },
              ),
            ],
          ),

          // Right side: Marks score, Flag toggle, Delete
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Score input
              SizedBox(
                width: 90,
                child: TextFormField(
                  key: ValueKey('${question.id}-score'),
                  initialValue: question.score.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) onUpdateQuestion(question.copyWith(score: n));
                  },
                ),
              ),

              // Review flag toggle
              IconButton(
                icon: Icon(
                  question.flaggedForReview
                      ? Icons.flag_rounded
                      : Icons.outlined_flag_rounded,
                  color: question.flaggedForReview
                      ? const Color(0xFFD97706)
                      : EduverseColors.outline,
                ),
                tooltip: question.flaggedForReview
                    ? 'Flagged for Review (tap to unflag)'
                    : 'Flag for Review',
                onPressed: () {
                  onUpdateQuestion(
                    question.copyWith(flaggedForReview: !question.flaggedForReview),
                  );
                },
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: EduverseColors.error),
                tooltip: 'Delete Question',
                onPressed: onDeleteQuestion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(BuildContext context, QuestionDifficulty? diff) {
    return PopupMenuButton<QuestionDifficulty?>(
      initialValue: diff,
      tooltip: 'Set Difficulty',
      onSelected: (selected) {
        onUpdateQuestion(
          question.copyWith(
            difficulty: selected,
            clearDifficulty: selected == null,
          ),
        );
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: null,
          child: Text('Untagged'),
        ),
        const PopupMenuItem(
          value: QuestionDifficulty.easy,
          child: Row(
            children: [
              Icon(Icons.circle, size: 12, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Easy'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: QuestionDifficulty.medium,
          child: Row(
            children: [
              Icon(Icons.circle, size: 12, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Medium'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: QuestionDifficulty.hard,
          child: Row(
            children: [
              Icon(Icons.circle, size: 12, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Hard'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getDifficultyColor(diff).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getDifficultyColor(diff).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: _getDifficultyColor(diff)),
            const SizedBox(width: 6),
            Text(
              diff != null ? diff.name.toUpperCase() : 'DIFFICULTY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _getDifficultyColor(diff),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: _getDifficultyColor(diff)),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(QuestionDifficulty? diff) {
    switch (diff) {
      case QuestionDifficulty.easy:
        return const Color(0xFF10B981);
      case QuestionDifficulty.medium:
        return const Color(0xFFF59E0B);
      case QuestionDifficulty.hard:
        return const Color(0xFFEF4444);
      case null:
        return EduverseColors.outline;
    }
  }

  Widget _buildPromptSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Question Statement Prompt',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: EduverseColors.deepNavy,
              ),
            ),
            Text(
              'Character count: ${question.questionText.length}',
              style: TextStyle(fontSize: 12, color: EduverseColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RichDocumentEditor(
          key: ValueKey('${question.id}-prompt'),
          initialDeltaJson: question.questionDelta,
          initialHtml: question.questionHtml,
          initialText: question.questionText,
          labelText: 'Question Statement',
          autoSaveDebounceDuration: const Duration(milliseconds: 300),
          onSave: (delta, html) {
            onUpdateQuestion(
              question.copyWith(
                questionText: RichTextService.extractPlainText(delta),
                questionDelta: delta,
                questionHtml: html,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnswerOptionsSection(BuildContext context) {
    if (question.answerType == AnswerType.trueFalse) {
      return _buildTrueFalseEditor(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Answer Options & Distractor Rationale',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: EduverseColors.deepNavy,
              ),
            ),
            Text(
              'Select radio button for correct answer key',
              style: TextStyle(fontSize: 12, color: EduverseColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < 4; i++) ...[
          _buildOptionTile(context, i),
          if (i < 3) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildOptionTile(BuildContext context, int optionIndex) {
    final options = question.options;
    final opt = optionIndex < options.length
        ? options[optionIndex]
        : AnswerOption(
            id: 'opt_${optionIndex + 1}',
            text: '',
            isCorrect: optionIndex == 0,
          );

    final optLetter = String.fromCharCode(65 + optionIndex);
    final isCorrect = opt.isCorrect;

    return Container(
      decoration: BoxDecoration(
        color: isCorrect
            ? EduverseColors.primaryContainer.withValues(alpha: 0.08)
            : EduverseColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? EduverseColors.primary
              : EduverseColors.outlineVariant.withValues(alpha: 0.6),
          width: isCorrect ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option Header: Radio & Correct badge
          Row(
            children: [
              InkWell(
                onTap: () {
                  final newOptions = List<AnswerOption>.generate(4, (idx) {
                    final existing = idx < options.length
                        ? options[idx]
                        : AnswerOption(id: 'opt_${idx + 1}', text: '');
                    return existing.copyWith(isCorrect: idx == optionIndex);
                  });
                  onUpdateQuestion(question.copyWith(options: newOptions));
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isCorrect
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isCorrect
                        ? EduverseColors.primary
                        : EduverseColors.outline,
                    size: 22,
                  ),
                ),
              ),
              Text(
                'Option $optLetter',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(width: 8),
              if (isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: EduverseColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Correct Answer Key',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Option Text Rich Editor
          RichDocumentEditor(
            key: ValueKey('${question.id}-opt-$optionIndex'),
            initialDeltaJson: opt.textDelta,
            initialHtml: opt.textHtml,
            initialText: opt.text,
            labelText: 'Option $optLetter Content',
            autoSaveDebounceDuration: const Duration(milliseconds: 300),
            onSave: (delta, html) {
              final newOptions = List<AnswerOption>.generate(4, (idx) {
                final existing = idx < options.length
                    ? options[idx]
                    : AnswerOption(id: 'opt_${idx + 1}', text: '');
                if (idx == optionIndex) {
                  return existing.copyWith(
                    text: RichTextService.extractPlainText(delta),
                    textDelta: delta,
                    textHtml: html,
                  );
                }
                return existing;
              });
              onUpdateQuestion(question.copyWith(options: newOptions));
            },
          ),
          const SizedBox(height: 10),

          // Distractor Rationale Field
          TextFormField(
            key: ValueKey('${question.id}-opt-rationale-$optionIndex'),
            initialValue: opt.rationale ?? '',
            decoration: InputDecoration(
              labelText: isCorrect
                  ? 'Official Rationale / Why this option is correct'
                  : 'Distractor Rationale / Common trap explanation',
              hintText: 'Enter explanation for why students choose or avoid this option...',
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            onChanged: (v) {
              final newOptions = List<AnswerOption>.generate(4, (idx) {
                final existing = idx < options.length
                    ? options[idx]
                    : AnswerOption(id: 'opt_${idx + 1}', text: '');
                if (idx == optionIndex) {
                  return existing.copyWith(rationale: v.trim().isEmpty ? null : v);
                }
                return existing;
              });
              onUpdateQuestion(question.copyWith(options: newOptions));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrueFalseEditor(BuildContext context) {
    final boolVal = question.correctBooleanAnswer ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correct Answer (True / False):',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: EduverseColors.deepNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => onUpdateQuestion(question.copyWith(correctBooleanAnswer: true)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: boolVal
                        ? EduverseColors.emeraldVivid.withValues(alpha: 0.1)
                        : EduverseColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: boolVal ? EduverseColors.emeraldVivid : EduverseColors.outlineVariant,
                      width: boolVal ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        boolVal ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: boolVal ? EduverseColors.emeraldVivid : EduverseColors.outline,
                      ),
                      const SizedBox(width: 8),
                      const Text('TRUE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => onUpdateQuestion(question.copyWith(correctBooleanAnswer: false)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !boolVal
                        ? EduverseColors.error.withValues(alpha: 0.1)
                        : EduverseColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !boolVal ? EduverseColors.error : EduverseColors.outlineVariant,
                      width: !boolVal ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        !boolVal ? Icons.cancel : Icons.radio_button_unchecked,
                        color: !boolVal ? EduverseColors.error : EduverseColors.outline,
                      ),
                      const SizedBox(width: 8),
                      const Text('FALSE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplanationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedagogical Explanation & Solution',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: EduverseColors.deepNavy,
          ),
        ),
        const SizedBox(height: 10),
        RichDocumentEditor(
          key: ValueKey('${question.id}-explanation'),
          initialDeltaJson: question.explanationDelta,
          initialHtml: question.explanationHtml,
          initialText: question.explanation,
          labelText: 'Comprehensive Solution & Concept Notes',
          autoSaveDebounceDuration: const Duration(milliseconds: 300),
          onSave: (delta, html) {
            onUpdateQuestion(
              question.copyWith(
                explanation: RichTextService.extractPlainText(delta),
                explanationDelta: delta,
                explanationHtml: html,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (onPreviousQuestion != null)
            OutlinedButton.icon(
              onPressed: onPreviousQuestion,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text('Previous: Q$questionIndex'),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onDuplicateQuestion,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Duplicate'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onNextOrAddQuestion,
            icon: Icon(isLastQuestion ? Icons.add : Icons.arrow_forward, size: 16),
            label: Text(isLastQuestion ? 'Add Question' : 'Next: Q${questionIndex + 2}'),
            style: FilledButton.styleFrom(
              backgroundColor: EduverseColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
