import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/excel_service.dart';
import '../services/sim_service.dart';
import '../widgets/queue_chart.dart';
import '../widgets/result_table.dart';
import '../widgets/summary_view.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _exportCsv() async {
    final s = _summary;
    if (s == null) return;

    final buffer = StringBuffer();
    buffer.writeln(
      'Index,ArrivalTime,ServiceTime,StartTime,FinishTime,WaitTime,SystemTime',
    );

    for (final r in s.records) {
      buffer.writeln(
        [
          r.index,
          r.arrival,
          r.service,
          r.start,
          r.finish,
          r.wait,
          r.systemTime,
        ].join(','),
      );
    }

    // 1) Сохраняем в Documents приложения
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/smo_result.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString(), flush: true);

    // 2) Показываем системное меню "Поделиться"
    await Share.shareXFiles([
      XFile(filePath),
    ], text: 'Результаты моделирования СМО (CSV)');

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV подготовлен: smo_result.csv')));
  }

  final _excel = ExcelService();
  final _sim = SimService();

  ExcelParseResult? _raw;
  int? _arrivalCol;
  int? _serviceCol;

  SimSummary? _summary;
  String? _fileName;
  String? _error;

  Future<void> _pickExcel() async {
    setState(() {
      _error = null;
      _summary = null;
      _raw = null;
      _fileName = null;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      setState(() => _error = 'Не удалось прочитать файл (bytes == null).');
      return;
    }

    try {
      final raw = _excel.parse(bytes);
      final guessA = _excel.guessArrivalCol(raw.headers);
      final guessS = _excel.guessServiceCol(raw.headers);

      setState(() {
        _raw = raw;
        _fileName = f.name;
        _arrivalCol = guessA;
        _serviceCol = guessS;
      });

      // если не угадали — попросим выбрать
      if (_arrivalCol == null || _serviceCol == null) {
        await _showMappingDialog();
      }

      if (_arrivalCol == null || _serviceCol == null) {
        setState(
          () => _error = 'Нужно выбрать колонки поступления и обслуживания.',
        );
        return;
      }

      _runModel();
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }
  }

  void _runModel() {
    final raw = _raw!;
    final arrivalCol = _arrivalCol!;
    final serviceCol = _serviceCol!;

    final input = _excel.toInputRecords(
      raw: raw,
      arrivalCol: arrivalCol,
      serviceCol: serviceCol,
    );
    final summary = _sim.simulate(input);

    setState(() {
      _summary = summary;
      _error = null;
    });
  }

  Future<void> _showMappingDialog() async {
    final raw = _raw!;
    int? a = _arrivalCol;
    int? s = _serviceCol;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Сопоставление колонок'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: a,
                decoration: const InputDecoration(
                  labelText: 'Поступление (arrival)',
                ),
                items: _items(raw.headers),
                onChanged: (v) => a = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: s,
                decoration: const InputDecoration(
                  labelText: 'Обслуживание (service/duration)',
                ),
                items: _items(raw.headers),
                onChanged: (v) => s = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _arrivalCol = a;
                  _serviceCol = s;
                });
                Navigator.pop(context);
              },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<int>> _items(List<String> headers) {
    return List.generate(headers.length, (i) {
      final title = headers[i].isEmpty ? 'Колонка $i' : headers[i];
      return DropdownMenuItem(value: i, child: Text(title));
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ПР-10: Анализ СМО из Excel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Сводка'),
              Tab(text: 'Очередь'),
              Tab(text: 'Таблица'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _pickExcel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Загрузить Excel (.xlsx)'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: (_summary == null) ? null : _exportCsv,
                    icon: const Icon(Icons.download),
                    label: const Text('Экспорт'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName ?? 'Файл не выбран',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  SummaryView(summary: summary),
                  QueueChart(summary: summary),
                  ResultTable(summary: summary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
