import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/sim_service.dart';
import 'wait_histogram.dart';

class QueueChart extends StatelessWidget {
  final SimSummary? summary;
  const QueueChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Center(child: Text('Сначала загрузите Excel.'));
    }

    final s = summary!;
    final spots = <FlSpot>[];
    for (int i = 0; i < s.queueByIndex.length; i++) {
      spots.add(FlSpot((i + 1).toDouble(), s.queueByIndex[i].toDouble()));
    }

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
                  'Длина очереди перед началом обслуживания',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: LineChart(
                    LineChartData(
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false,
                          dotData: const FlDotData(show: false),
                          barWidth: 2,
                        ),
                      ],
                      minY: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        WaitHistogram(summary: s),
      ],
    );
  }
}
