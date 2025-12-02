import 'package:flutter/material.dart';
import 'package:eduverse/study/study_data.dart';

class PracticeQuestionPage extends StatefulWidget {
  final TestModel? test;

  const PracticeQuestionPage({Key? key, this.test}) : super(key: key);

  @override
  State<PracticeQuestionPage> createState() => _PracticeQuestionPageState();
}

class _PracticeQuestionPageState extends State<PracticeQuestionPage> {
  late TestModel _test;
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isSubmitted = false;
  
  // Mock timer
  int _secondsRemaining = 1200; // 20 mins

  @override
  void initState() {
    super.initState();
    // Use passed test or fallback to first mock test
    _test = widget.test ?? StudyData.mockTests.first;
  }

  @override
  Widget build(BuildContext context) {
    final question = _test.questions[_currentQuestionIndex % _test.questions.length];
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/${_test.questionCount}'),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _test.questionCount,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedOptionIndex == index;
                      final isCorrect = question.answerIndex == index;
                      
                      Color borderColor = Colors.grey[300]!;
                      Color? backgroundColor;
                      IconData? icon;
                      
                      if (_isSubmitted) {
                        if (isCorrect) {
                          borderColor = Colors.green;
                          backgroundColor = Colors.green.withOpacity(0.1);
                          icon = Icons.check_circle;
                        } else if (isSelected) {
                          borderColor = Colors.red;
                          backgroundColor = Colors.red.withOpacity(0.1);
                          icon = Icons.cancel;
                        }
                      } else if (isSelected) {
                        borderColor = Theme.of(context).primaryColor;
                        backgroundColor = Theme.of(context).primaryColor.withOpacity(0.05);
                      }

                      return GestureDetector(
                        onTap: _isSubmitted ? null : () => setState(() => _selectedOptionIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor ?? Colors.white,
                            border: Border.all(color: borderColor, width: isSelected || (_isSubmitted && isCorrect) ? 2 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor),
                                  color: isSelected && !_isSubmitted ? Theme.of(context).primaryColor : null,
                                ),
                                child: isSelected && !_isSubmitted
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : (_isSubmitted && icon != null ? Icon(icon, size: 18, color: borderColor) : Center(child: Text(String.fromCharCode(65 + index), style: TextStyle(color: borderColor, fontWeight: FontWeight.bold)))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isSubmitted && isCorrect ? Colors.green[800] : Colors.black87,
                                    fontWeight: _isSubmitted && isCorrect ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    if (_isSubmitted) ...[
                      const SizedBox(height: 24),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(question.explanation, style: const TextStyle(height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Space for bottom button + keyboard
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedOptionIndex == null ? null : () {
                if (_isSubmitted) {
                  // Next Question
                  setState(() {
                    _currentQuestionIndex++;
                    _selectedOptionIndex = null;
                    _isSubmitted = false;
                  });
                } else {
                  // Submit
                  setState(() {
                    _isSubmitted = true;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isSubmitted ? 'Next Question' : 'Submit Answer',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
