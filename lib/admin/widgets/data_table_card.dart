import 'package:flutter/material.dart';

class DataTableCard extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const DataTableCard({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(columns: columns, rows: rows),
      ),
    );
  }
}
