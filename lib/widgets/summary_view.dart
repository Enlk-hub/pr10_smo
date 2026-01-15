import 'package:flutter/material.dart';
import '../services/sim_service.dart';

class SummaryView extends StatelessWidget {
  final SimSummary? summary;
  const SummaryView({super.key, required this.summary});

  String _fmt(double v) => v.toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(
        child: Text('Загрузите Excel, чтобы построить отчёт.'),
      );
    }

    final s = summary!;
    final waitedPct = s.total == 0 ? 0 : (100.0 * s.waitedCount / s.total);
    final load = s.busyRatioApprox;

    // Индикатор загрузки (простая и понятная визуализация)
    // < 0.9 — стабильно, 0.9..1.0 — напряжённо, > 1.0 — риск очередей
    final loadLabel = load < 0.9
        ? 'Стабильно'
        : (load <= 1.0 ? 'Напряжённо' : 'Риск перегрузки');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Итоги моделирования (FIFO, 1 канал)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('Всего заявок: ${s.total}'),
                Text(
                  'С ожиданием: ${s.waitedCount} (${waitedPct.toStringAsFixed(1)}%)',
                ),
                Text('Среднее ожидание: ${_fmt(s.avgWait)}'),
                Text('Среднее время в системе: ${_fmt(s.avgSystemTime)}'),
                Text('Максимальное ожидание: ${_fmt(s.maxWait)}'),
                const SizedBox(height: 12),
                Text(
                  'Индикатор загрузки (по данным): ${_fmt(load)} → $loadLabel',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: (load).clamp(0.0, 1.2) / 1.2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сравнение: начало / середина / конец',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...s.segments.entries.map((e) {
                  final st = e.value;
                  final pct = st.count == 0
                      ? 0
                      : (100.0 * st.waitedCount / st.count);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${e.key}: заявок=${st.count}, ожидали=${st.waitedCount} (${pct.toStringAsFixed(1)}%), '
                      'ср.ожид=${_fmt(st.avgWait)}, ср.в_сист=${_fmt(st.avgSystemTime)}',
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Редкие, но длительные задержки (Top-10 ожиданий)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...s.topWaits.map(
                  (r) => Text(
                    '#${r.index}: ожидание=${_fmt(r.wait)} (arrival=${_fmt(r.arrival)}, service=${_fmt(r.service)})',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Выводы и рекомендации (шаблон)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  '• Если очередь растёт и не “схлопывается”, системе не хватает мощности → добавить ресурс/канал обслуживания.',
                ),
                Text(
                  '• Если “пики” редкие, но большие → подумать про перераспределение нагрузки (батчирование, приоритеты, ограничение входа).',
                ),
                Text(
                  '• Если конец файла хуже начала → нагрузка увеличивается со временем → нужен план масштабирования или сглаживание потока.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
