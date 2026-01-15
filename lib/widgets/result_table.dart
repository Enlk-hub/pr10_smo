import 'package:flutter/material.dart';
import '../services/sim_service.dart';

class ResultTable extends StatelessWidget {
  final SimSummary? summary;
  const ResultTable({super.key, required this.summary});

  String _fmt(num v) => v.toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: Text('Сначала загрузите Excel.'));
    }

    final rows = summary!.records.take(50).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('arrival')),
          DataColumn(label: Text('service')),
          DataColumn(label: Text('start')),
          DataColumn(label: Text('finish')),
          DataColumn(label: Text('wait')),
        ],
        rows: rows.map((r) {
          return DataRow(
            cells: [
              DataCell(Text(r.index.toString())),
              DataCell(Text(_fmt(r.arrival))),
              DataCell(Text(_fmt(r.service))),
              DataCell(Text(_fmt(r.start))),
              DataCell(Text(_fmt(r.finish))),
              DataCell(Text(_fmt(r.wait))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
