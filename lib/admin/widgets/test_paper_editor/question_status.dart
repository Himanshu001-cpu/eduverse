import 'package:flutter/material.dart';
import 'package:eduverse/feed/models/feed_models.dart';
import 'package:eduverse/core/theme/eduverse_theme.dart';

enum QuestionValidationStatus {
  complete,
  incomplete,
}

/// Computes whether a question is fully specified with prompt and correct answer.
bool isQuestionComplete(QuizQuestion q) {
  final hasPrompt = q.questionText.trim().isNotEmpty;
  if (!hasPrompt) return false;

  if (q.answerType == AnswerType.multipleChoice) {
    final filledOptions = q.options.where((o) => o.text.trim().isNotEmpty).toList();
    if (filledOptions.length < 2) return false;
    return filledOptions.any((o) => o.isCorrect);
  } else if (q.answerType == AnswerType.trueFalse) {
    return q.correctBooleanAnswer != null;
  } else {
    return (q.correctShortAnswer?.trim().isNotEmpty ?? false);
  }
}

/// Helper badge returning colors and icon for palette chips and badges
class QuestionStatusHelper {
  QuestionStatusHelper._();

  static Color getStatusColor({
    required bool isComplete,
    required bool isFlagged,
  }) {
    if (isFlagged) {
      return const Color(0xFFD97706); // Amber / tertiary warning
    }
    if (isComplete) {
      return EduverseColors.emeraldVivid; // Green / Validated
    }
    return EduverseColors.error; // Incomplete
  }

  static IconData getStatusIcon({
    required bool isComplete,
    required bool isFlagged,
  }) {
    if (isFlagged) return Icons.flag_rounded;
    if (isComplete) return Icons.check_circle_rounded;
    return Icons.error_outline_rounded;
  }

  static String getStatusLabel({
    required bool isComplete,
    required bool isFlagged,
  }) {
    if (isFlagged) return 'Flagged for Review';
    if (isComplete) return 'Validated';
    return 'Incomplete';
  }
}
