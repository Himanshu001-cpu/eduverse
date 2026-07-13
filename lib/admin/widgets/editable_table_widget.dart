import 'package:flutter/material.dart';

class EditableTableWidget extends StatefulWidget {
  final int initialRows;
  final int initialCols;
  final List<List<String>>? initialData;
  final void Function(List<List<String>> cells, int rows, int cols) onTableChanged;

  const EditableTableWidget({
    super.key,
    required this.initialRows,
    required this.initialCols,
    this.initialData,
    required this.onTableChanged,
  });

  @override
  State<EditableTableWidget> createState() => _EditableTableWidgetState();
}

class _EditableTableWidgetState extends State<EditableTableWidget> {
  late int _rows;
  late int _cols;
  late List<List<String>> _cellData;
  late List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows;
    _cols = widget.initialCols;

    _cellData = List.generate(
      _rows,
      (r) => List.generate(
        _cols,
        (c) {
          if (widget.initialData != null &&
              r < widget.initialData!.length &&
              c < widget.initialData![r].length) {
            return widget.initialData![r][c];
          }
          return 'Cell ${(r * _cols) + c + 1}';
        },
      ),
    );

    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      _rows,
      (r) => List.generate(
        _cols,
        (c) {
          final controller = TextEditingController(text: _cellData[r][c]);
          controller.addListener(() {
            _cellData[r][c] = controller.text;
            widget.onTableChanged(_cellData, _rows, _cols);
          });
          return controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EditableTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != null) {
      bool changed = false;
      if (_rows != widget.initialRows || _cols != widget.initialCols) {
        changed = true;
      } else {
        for (int r = 0; r < _rows; r++) {
          for (int c = 0; c < _cols; c++) {
            if (r < widget.initialData!.length &&
                c < widget.initialData![r].length &&
                _cellData[r][c] != widget.initialData![r][c]) {
              changed = true;
              break;
            }
          }
        }
      }

      if (changed) {
        setState(() {
          _rows = widget.initialRows;
          _cols = widget.initialCols;
          _cellData = List.generate(
            _rows,
            (r) => List.generate(
              _cols,
              (c) {
                if (r < widget.initialData!.length &&
                    c < widget.initialData![r].length) {
                  return widget.initialData![r][c];
                }
                return '';
              },
            ),
          );
          for (final row in _controllers) {
            for (final controller in row) {
              controller.dispose();
            }
          }
          _initControllers();
        });
      }
    }
  }

  void _addRow() {
    if (_rows >= 20) return;
    setState(() {
      _rows++;
      final newRowData = List.generate(_cols, (c) => '');
      _cellData.add(newRowData);
      
      final newRowControllers = List.generate(_cols, (c) {
        final controller = TextEditingController(text: '');
        controller.addListener(() {
          _cellData[_rows - 1][c] = controller.text;
          widget.onTableChanged(_cellData, _rows, _cols);
        });
        return controller;
      });
      _controllers.add(newRowControllers);
    });
    widget.onTableChanged(_cellData, _rows, _cols);
  }

  void _removeRow() {
    if (_rows <= 1) return;
    setState(() {
      _rows--;
      final removedControllers = _controllers.removeLast();
      for (final controller in removedControllers) {
        controller.dispose();
      }
      _cellData.removeLast();
    });
    widget.onTableChanged(_cellData, _rows, _cols);
  }

  void _addColumn() {
    if (_cols >= 20) return;
    setState(() {
      _cols++;
      for (int r = 0; r < _rows; r++) {
        _cellData[r].add('');
        
        final controller = TextEditingController(text: '');
        final colIndex = _cols - 1;
        final rowIndex = r;
        controller.addListener(() {
          _cellData[rowIndex][colIndex] = controller.text;
          widget.onTableChanged(_cellData, _rows, _cols);
        });
        _controllers[r].add(controller);
      }
    });
    widget.onTableChanged(_cellData, _rows, _cols);
  }

  void _removeColumn() {
    if (_cols <= 1) return;
    setState(() {
      _cols--;
      for (int r = 0; r < _rows; r++) {
        final controller = _controllers[r].removeLast();
        controller.dispose();
        _cellData[r].removeLast();
      }
    });
    widget.onTableChanged(_cellData, _rows, _cols);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Title / Header
            const Row(
              children: [
                Icon(Icons.grid_on, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Visual Table Editor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            
            // Scrollable Grid Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 48,
                ),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: List.generate(_rows, (r) {
                    final isHeader = r == 0;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isHeader ? Colors.grey.shade100 : null,
                      ),
                      children: List.generate(_cols, (c) {
                        return Container(
                          padding: const EdgeInsets.all(4.0),
                          constraints: const BoxConstraints(minWidth: 80),
                          child: TextField(
                            key: Key('table_cell_${r}_$c'),
                            controller: _controllers[r][c],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Edit Controls Row
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const Key('btn_add_row'),
                  onPressed: _rows < 20 ? _addRow : null,
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Row', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('btn_remove_row'),
                  onPressed: _rows > 1 ? _removeRow : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 14),
                  label: const Text('Row', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('btn_add_col'),
                  onPressed: _cols < 20 ? _addColumn : null,
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Col', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('btn_remove_col'),
                  onPressed: _cols > 1 ? _removeColumn : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 14),
                  label: const Text('Col', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
