import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/sim_service.dart';

class WaitHistogram extends StatelessWidget {
  final SimSummary summary;
  const WaitHistogram({super.key, required this.summary});

  String _fmt(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final edges = summary.waitBinEdges;
    final counts = summary.waitBinCounts;

    if (counts.isEmpty) {
      return const Center(child: Text('Нет данных для гистограммы.'));
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < counts.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: counts[i].toDouble(),
              width: 10,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Гистограмма ожиданий (распределение)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: (maxCount <= 0) ? 1 : (maxCount * 1.15),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= counts.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$i',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final i = group.x;
                        final a = edges[i];
                        final b = edges[i + 1];
                        return BarTooltipItem(
                          '${_fmt(a)}–${_fmt(b)}\nкол-во: ${counts[i]}',
                          const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  barGroups: groups,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ось X: номер интервала, подсказка показывает диапазон ожидания и количество заявок.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
