import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../backend/types.dart';

class SpendChart extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<SurfacedTransaction> transactions;

  final Map<DateTime, num> runningSpendSum = <DateTime, num>{};
  final List<FlSpot> spendLineSpots = [];
  late final List<FlSpot> projectedLineSpots;

  SpendChart(
      {super.key,
      required this.startDate,
      required this.endDate,
      required this.transactions}) {
    transactions.sort(
        (a, b) => a.realTransaction.date.compareTo(b.realTransaction.date));
    runningSpendSum[startDate] = 0;
    num runningSpendTotal = 0;
    for (SurfacedTransaction transaction in transactions) {
      runningSpendTotal += transaction.getAmount();
      runningSpendSum[transaction.realTransaction.date] = runningSpendTotal;
    }
    var dateKeys = runningSpendSum.keys.toList();
    dateKeys.sort((a, b) => a.compareTo(b));
    for (DateTime dateKey in dateKeys) {
      spendLineSpots.add(
          FlSpot(dateKey.day.toDouble(), runningSpendSum[dateKey]!.toDouble()));
    }
    spendLineSpots.add(
        FlSpot(DateTime.now().day.toDouble(), runningSpendTotal.toDouble()));
    num dailySpendRate = runningSpendTotal / (dateKeys.last.day.toDouble() - 1);
    projectedLineSpots = [
      FlSpot(DateTime.now().day.toDouble(), runningSpendTotal.toDouble()),
      FlSpot(
          endDate.day.toDouble(),
          runningSpendTotal.toDouble() +
              (dailySpendRate * (endDate.day - DateTime.now().day))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: 2,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: LineChart(
              LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                        spots: spendLineSpots,
                        isCurved: true,
                        isStrokeCapRound: true,
                        barWidth: 4,
                        color: Theme.of(context).colorScheme.primary,
                        belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.0)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )),
                        dotData: const FlDotData(show: false)),
                    LineChartBarData(
                      spots: projectedLineSpots,
                      isStrokeCapRound: true,
                      barWidth: 4,
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: false),
                      dashArray: [2, 6],
                    )
                  ],
                  lineTouchData: const LineTouchData(enabled: false)),
            )));
  }
}
