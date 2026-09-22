import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

enum FormulaCategory { algebra, calculus, greek, matrices, symbols }

class _FormulaSymbol {
  final String label;
  final String latex;
  final Key? key;

  const _FormulaSymbol({required this.label, required this.latex, this.key});
}

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
  FormulaCategory _selectedCategory = FormulaCategory.algebra;

  static const Map<FormulaCategory, List<_FormulaSymbol>> _categorizedSymbols = {
    FormulaCategory.algebra: [
      _FormulaSymbol(label: r'\frac{a}{b}', latex: r'\frac{a}{b}', key: Key('preset_fraction')),
      _FormulaSymbol(label: r'\sqrt{x}', latex: r'\sqrt{x}', key: Key('preset_sqrt')),
      _FormulaSymbol(label: r'\sqrt[n]{x}', latex: r'\sqrt[n]{x}'),
      _FormulaSymbol(label: r'x^{n}', latex: r'x^{n}'),
      _FormulaSymbol(label: r'x_{i}', latex: r'x_{i}'),
      _FormulaSymbol(label: r'\pm', latex: r'\pm'),
      _FormulaSymbol(label: r'\times', latex: r'\times'),
      _FormulaSymbol(label: r'\div', latex: r'\div'),
      _FormulaSymbol(label: r'\neq', latex: r'\neq'),
      _FormulaSymbol(label: r'\leq', latex: r'\leq'),
      _FormulaSymbol(label: r'\geq', latex: r'\geq'),
    ],
    FormulaCategory.calculus: [
      _FormulaSymbol(label: r'\int', latex: r'\int_{a}^{b} x \, dx', key: Key('preset_integral')),
      _FormulaSymbol(label: r'\iint', latex: r'\iint'),
      _FormulaSymbol(label: r'\frac{df}{dx}', latex: r'\frac{df}{dx}'),
      _FormulaSymbol(label: r'\frac{\partial f}{\partial x}', latex: r'\frac{\partial f}{\partial x}'),
      _FormulaSymbol(label: r'\lim_{x \to 0}', latex: r'\lim_{x \to 0}'),
      _FormulaSymbol(label: r'\sum', latex: r'\sum_{i=1}^{n} i', key: Key('preset_sum')),
      _FormulaSymbol(label: r'\prod_{i=1}^{n}', latex: r'\prod_{i=1}^{n}'),
      _FormulaSymbol(label: r'\nabla', latex: r'\nabla'),
      _FormulaSymbol(label: r'\Delta x', latex: r'\Delta x'),
    ],
    FormulaCategory.greek: [
      _FormulaSymbol(label: r'\pi', latex: r'\pi', key: Key('preset_pi')),
      _FormulaSymbol(label: r'\alpha', latex: r'\alpha'),
      _FormulaSymbol(label: r'\beta', latex: r'\beta'),
      _FormulaSymbol(label: r'\gamma', latex: r'\gamma'),
      _FormulaSymbol(label: r'\delta', latex: r'\delta'),
      _FormulaSymbol(label: r'\theta', latex: r'\theta'),
      _FormulaSymbol(label: r'\lambda', latex: r'\lambda'),
      _FormulaSymbol(label: r'\mu', latex: r'\mu'),
      _FormulaSymbol(label: r'\sigma', latex: r'\sigma'),
      _FormulaSymbol(label: r'\phi', latex: r'\phi'),
      _FormulaSymbol(label: r'\omega', latex: r'\omega'),
      _FormulaSymbol(label: r'\Delta', latex: r'\Delta'),
      _FormulaSymbol(label: r'\Omega', latex: r'\Omega'),
    ],
    FormulaCategory.matrices: [
      _FormulaSymbol(label: 'Matrix ( )', latex: r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}'),
      _FormulaSymbol(label: 'Matrix [ ]', latex: r'\begin{bmatrix} a & b \\ c & d \end{bmatrix}'),
      _FormulaSymbol(label: 'Determinant | |', latex: r'\begin{vmatrix} a & b \\ c & d \end{vmatrix}'),
    ],
    FormulaCategory.symbols: [
      _FormulaSymbol(label: r'\rightarrow', latex: r'\rightarrow'),
      _FormulaSymbol(label: r'\Rightarrow', latex: r'\Rightarrow'),
      _FormulaSymbol(label: r'\Leftrightarrow', latex: r'\Leftrightarrow'),
      _FormulaSymbol(label: r'\in', latex: r'\in'),
      _FormulaSymbol(label: r'\subset', latex: r'\subset'),
      _FormulaSymbol(label: r'\cup', latex: r'\cup'),
      _FormulaSymbol(label: r'\cap', latex: r'\cap'),
      _FormulaSymbol(label: r'\emptyset', latex: r'\emptyset'),
      _FormulaSymbol(label: r'\forall', latex: r'\forall'),
      _FormulaSymbol(label: r'\exists', latex: r'\exists'),
      _FormulaSymbol(label: r'\infty', latex: r'\infty'),
      _FormulaSymbol(label: r'^{\circ}', latex: r'^{\circ}'),
      _FormulaSymbol(label: r'\angle', latex: r'\angle'),
    ],
  };

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
      // Check for unbalanced braces or common syntax errors
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white : Colors.black87);

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

            // Category Selector Chips
            Text(
              'Categories:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FormulaCategory.values.map((category) {
                  final name = category.name[0].toUpperCase() + category.name.substring(1);
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      key: Key('category_${category.name}'),
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8.0),

            // Quick Presets Row (Always accessible)
            Text(
              'Quick Presets:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ActionChip(
                  key: const Key('preset_fraction'),
                  label: const Text(r'Fraction (\frac{a}{b})'),
                  onPressed: () => _insertSymbol(r'\frac{a}{b}'),
                ),
                ActionChip(
                  key: const Key('preset_sqrt'),
                  label: const Text(r'Square Root (\sqrt{x})'),
                  onPressed: () => _insertSymbol(r'\sqrt{x}'),
                ),
                ActionChip(
                  key: const Key('preset_integral'),
                  label: const Text(r'Integral (\int)'),
                  onPressed: () => _insertSymbol(r'\int_{a}^{b} x \, dx'),
                ),
                ActionChip(
                  key: const Key('preset_pi'),
                  label: const Text(r'Pi (\pi)'),
                  onPressed: () => _insertSymbol(r'\pi'),
                ),
                ActionChip(
                  key: const Key('preset_sum'),
                  label: const Text(r'Sum (\sum)'),
                  onPressed: () => _insertSymbol(r'\sum_{i=1}^{n} i'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Category Symbols Palette
            Text(
              '${_selectedCategory.name[0].toUpperCase() + _selectedCategory.name.substring(1)} Palette:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: (_categorizedSymbols[_selectedCategory] ?? []).map((symbol) {
                return ActionChip(
                  key: symbol.key,
                  label: Text(symbol.label),
                  onPressed: () => _insertSymbol(symbol.latex),
                );
              }).toList(),
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
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
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
                        color: _latexError != null ? Colors.red : textColor,
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
