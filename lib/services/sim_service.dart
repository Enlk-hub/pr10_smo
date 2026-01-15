import '../models/record.dart';

class SimSummary {
  final int total;
  final int waitedCount;
  final double avgWait;
  final double avgSystemTime;
  final double maxWait;
  final double busyRatioApprox; // "загруженность" в понятном виде
  final List<SimRecord> records;

  // для графика очереди: точки (index -> queueLenBeforeServiceStart)
  final List<int> queueByIndex;

  // сравнение начало/середина/конец
  final Map<String, SegmentStats> segments;

  // топ редких долгих ожиданий
  final List<SimRecord> topWaits;

    // гистограмма ожиданий
  final List<double> waitBinEdges; // длина bins+1
  final List<int> waitBinCounts; // длина bins


  SimSummary({
    required this.total,
    required this.waitedCount,
    required this.avgWait,
    required this.avgSystemTime,
    required this.maxWait,
    required this.busyRatioApprox,
    required this.records,
    required this.queueByIndex,
    required this.segments,
    required this.topWaits,
    required this.waitBinEdges,
    required this.waitBinCounts,
  });
}

class SegmentStats {
  final int count;
  final double avgWait;
  final double avgSystemTime;
  final int waitedCount;
  SegmentStats({
    required this.count,
    required this.avgWait,
    required this.avgSystemTime,
    required this.waitedCount,
  });
}

class SimService {
  SimSummary simulate(List<InputRecord> input) {
    if (input.isEmpty) {
      throw Exception('Нет данных для моделирования.');
    }

    final records = <SimRecord>[];

    double prevFinish = 0;
    double totalWait = 0;
    double totalSys = 0;
    double maxWait = 0;
    int waited = 0;

    // для "понятной" оценки: сравним
    // средний интервал между поступлениями vs среднее время обслуживания
    final interArrivals = <double>[];
    for (int i = 1; i < input.length; i++) {
      interArrivals.add(input[i].arrival - input[i - 1].arrival);
    }
    final avgInterArrival = interArrivals.isEmpty ? 0 : _avg(interArrivals);
    final avgService = _avg(input.map((e) => e.service).toList());

    // busyRatioApprox:
    // если среднее обслуживание больше среднего интервала, система "напряжена".
    final busyRatioApprox = (avgInterArrival <= 0)
        ? 1.0
        : (avgService / avgInterArrival);

    // очередь по индексу: сколько было ожидающих прямо перед началом обслуживания заявки i
    final queueByIndex = <int>[];

    // будем хранить "виртуальные" моменты начала обслуживания, чтобы оценить очередь:
    // очередь перед стартом i = сколько заявок уже пришло, но ещё не началось обслуживание
    final starts = <double>[];

    for (int i = 0; i < input.length; i++) {
      final a = input[i].arrival;
      final s = input[i].service;

      final start = (a > prevFinish) ? a : prevFinish;
      final finish = start + s;
      final waitTime = start - a;
      final sysTime = finish - a;

      starts.add(start);

      if (waitTime > 0) waited++;
      if (waitTime > maxWait) maxWait = waitTime;

      totalWait += waitTime;
      totalSys += sysTime;

      records.add(
        SimRecord(
          index: i + 1,
          arrival: a,
          service: s,
          start: start,
          finish: finish,
          wait: waitTime,
          systemTime: sysTime,
        ),
      );

      prevFinish = finish;
    }

    // посчитаем очередь перед каждым стартом:
    // очередь = count(arrival <= start_i) - count(start_j < start_i) - 1 (сама заявка i тоже входит в пришедшие)
    for (int i = 0; i < records.length; i++) {
      final si = records[i].start;
      final arrived = records.where((r) => r.arrival <= si).length;
      final startedBefore = records.where((r) => r.start < si).length;
      final q = arrived - startedBefore - 1;
      queueByIndex.add(q < 0 ? 0 : q);
    }

    final avgWait = totalWait / records.length;
    final avgSys = totalSys / records.length;

    final sortedByWait = [...records]..sort((a, b) => b.wait.compareTo(a.wait));
    final topWaits = sortedByWait.take(10).toList();

    // сегменты: начало/середина/конец (как требует практика)
    final segments = _calcSegments(records);

    final hist = _buildWaitHistogram(records, bins: 12);


    return SimSummary(
      total: records.length,
      waitedCount: waited,
      avgWait: avgWait,
      avgSystemTime: avgSys,
      maxWait: maxWait,
      busyRatioApprox: busyRatioApprox,
      records: records,
      queueByIndex: queueByIndex,
      segments: segments,
      topWaits: topWaits,
      waitBinEdges: hist.edges,
      waitBinCounts: hist.counts,

    );
  }

  Map<String, SegmentStats> _calcSegments(List<SimRecord> records) {
    final n = records.length;
    final a = records.sublist(0, (n / 3).floor());
    final b = records.sublist((n / 3).floor(), (2 * n / 3).floor());
    final c = records.sublist((2 * n / 3).floor());

    SegmentStats stats(List<SimRecord> seg) {
      final double avgW = seg.isEmpty
          ? 0.0
          : (seg.map((e) => e.wait).reduce((x, y) => x + y) / seg.length)
                .toDouble();

      final double avgS = seg.isEmpty
          ? 0.0
          : (seg.map((e) => e.systemTime).reduce((x, y) => x + y) / seg.length)
                .toDouble();

      final int wc = seg.where((e) => e.waited).length;

      return SegmentStats(
        count: seg.length,
        avgWait: avgW,
        avgSystemTime: avgS,
        waitedCount: wc,
      );
    }

    return {'Начало': stats(a), 'Середина': stats(b), 'Конец': stats(c)};
  }

  double _avg(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

    _Histogram _buildWaitHistogram(List<SimRecord> records, {int bins = 12}) {
    final waits = records.map((e) => e.wait).toList();
    final double maxW = waits.isEmpty
        ? 0.0
        : waits.reduce((a, b) => a > b ? a : b).toDouble();

    if (bins < 1) bins = 1;
    final step = (maxW <= 0) ? 1.0 : (maxW / bins);

    final edges = List<double>.generate(bins + 1, (i) => i * step);
    final counts = List<int>.filled(bins, 0);

    for (final w in waits) {
      int idx = step <= 0 ? 0 : (w / step).floor();
      if (idx < 0) idx = 0;
      if (idx >= bins) idx = bins - 1; // max попадает в последний бин
      counts[idx]++;
    }

    return _Histogram(edges: edges, counts: counts);
  }
}

class _Histogram {
  final List<double> edges;
  final List<int> counts;
  _Histogram({required this.edges, required this.counts});
}

