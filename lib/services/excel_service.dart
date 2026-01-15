import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/record.dart';

class ExcelParseResult {
  final List<String> headers;
  final List<List<dynamic>> rows; // raw rows excluding header
  ExcelParseResult({required this.headers, required this.rows});
}

class ExcelService {
  ExcelParseResult parse(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);

    // берём первый лист
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('Пустой Excel или не удалось прочитать лист.');
    }

    // первая строка — заголовки
    final headerRow = sheet.rows.first;
    final headers = headerRow
        .map((c) => (c?.value ?? '').toString().trim())
        .toList();

    final rows = <List<dynamic>>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final r = sheet.rows[i];
      // нормализуем длину под headers
      final row = List<dynamic>.generate(headers.length, (j) {
        if (j >= r.length) return null;
        return r[j]?.value;
      });
      rows.add(row);
    }

    return ExcelParseResult(headers: headers, rows: rows);
  }

  /// Пытаемся угадать колонку поступления/обслуживания по заголовкам.
  int? guessArrivalCol(List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      if (h == 'arrivaltime') return i;
    }
    final keys = [
      'arrival',
      'arrive',
      'in',
      'поступ',
      'вход',
      'приход',
      't_in',
    ];
    return _guessByKeys(headers, keys);
  }

  int? guessServiceCol(List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      if (h == 'servicetime') return i;
    }
    final keys = [
      'service',
      'duration',
      'обслуж',
      'время обслуж',
      'serv',
      't_serv',
    ];
    return _guessByKeys(headers, keys);
  }

  int? _guessByKeys(List<String> headers, List<String> keys) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      if (keys.any((k) => h.contains(k))) return i;
    }
    return null;
  }

  List<InputRecord> toInputRecords({
    required ExcelParseResult raw,
    required int arrivalCol,
    required int serviceCol,
  }) {
    final out = <InputRecord>[];

    for (int i = 0; i < raw.rows.length; i++) {
      final row = raw.rows[i];

      final a = _toDouble(row[arrivalCol]);
      final s = _toDouble(row[serviceCol]);

      // пропускаем пустые/битые строки
      if (a == null || s == null) continue;

      out.add(InputRecord(index: out.length + 1, arrival: a, service: s));
    }

    // сортировка по времени поступления (на случай если Excel не отсортирован)
    out.sort((x, y) => x.arrival.compareTo(y.arrival));
    return out;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    return double.tryParse(s);
  }
}
