import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class EquationBuilder extends StatefulWidget {
  final String initialEquation;
  final ValueChanged<String> onEquationSaved;

  const EquationBuilder({
    super.key,
    this.initialEquation = '',
    required this.onEquationSaved,
  });

  @override
  State<EquationBuilder> createState() => _EquationBuilderState();
}

class _EquationBuilderState extends State<EquationBuilder> {
  late final TextEditingController _latexController;
  String _previewText = '';
  String? _latexError;

  @override
  void initState() {
    super.initState();
    _latexController = TextEditingController(text: widget.initialEquation);
    _previewText = widget.initialEquation;
    _latexController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _latexController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final text = _latexController.text;
    String? error;

    if (text.isNotEmpty) {
      // Simple bracket/braces balancing check
      final braces = <String>[];
      for (int i = 0; i < text.length; i++) {
        final char = text[i];
        if (char == '{') {
          braces.add('{');
        } else if (char == '}') {
          if (braces.isEmpty) {
            error = 'LaTeX Error: Unbalanced curly braces';
            break;
          }
          braces.removeLast();
        }
      }
      if (error == null && braces.isNotEmpty) {
        error = 'LaTeX Error: Unbalanced curly braces';
      }
    }

    setState(() {
      _previewText = text;
      _latexError = error;
    });
  }

  void _insertSymbol(String symbol) {
    final text = _latexController.text;
    final selection = _latexController.selection;
    
    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;
    
    final newText = text.substring(0, start) + symbol + text.substring(end);
    _latexController.text = newText;
    
    // Set selection cursor position after the inserted symbol
    _latexController.selection = TextSelection.collapsed(offset: start + symbol.length);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'LaTeX Equation Builder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _latexController,
              key: const Key('latex_input'),
              decoration: InputDecoration(
                labelText: 'LaTeX Equation',
                hintText: r'e.g. \frac{a}{b} or x^2 + y^2 = r^2',
                errorText: _latexError,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Presets:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ActionChip(
                  key: const Key('preset_fraction'),
                  label: const Text('Fraction (\\frac{a}{b})'),
                  onPressed: () => _insertSymbol(r'\frac{a}{b}'),
                ),
                ActionChip(
                  key: const Key('preset_sqrt'),
                  label: const Text('Square Root (\\sqrt{x})'),
                  onPressed: () => _insertSymbol(r'\sqrt{x}'),
                ),
                ActionChip(
                  key: const Key('preset_integral'),
                  label: const Text('Integral (\\int)'),
                  onPressed: () => _insertSymbol(r'\int_{a}^{b} x \, dx'),
                ),
                ActionChip(
                  key: const Key('preset_pi'),
                  label: const Text('Pi (\\pi)'),
                  onPressed: () => _insertSymbol(r'\pi'),
                ),
                ActionChip(
                  key: const Key('preset_sum'),
                  label: const Text('Sum (\\sum)'),
                  onPressed: () => _insertSymbol(r'\sum_{i=1}^{n} i'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              'Preview:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey.shade50,
              ),
              alignment: Alignment.center,
              child: _previewText.isEmpty
                  ? const Text(
                      'Type equation or select presets above to preview',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Math.tex(
                      _previewText,
                      key: const Key('latex_math_preview'),
                      textStyle: TextStyle(
                        fontSize: 18.0,
                        color: _latexError != null ? Colors.red : Colors.black,
                      ),
                      onErrorFallback: (err) => Text(
                        'LaTeX Error: ${err.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  key: const Key('save_equation_button'),
                  onPressed: _latexError != null
                      ? null
                      : () {
                          widget.onEquationSaved(_latexController.text);
                        },
                  child: const Text('Insert Equation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
