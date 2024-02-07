import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../backend/types.dart';

class SpendChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<SurfacedTransaction> transactions;

  SpendChart(
      {super.key,
      required this.startDate,
      required this.endDate,
      required this.transactions});

  @override
  State<SpendChart> createState() => _SpendChartState();
}

class _SpendChartState extends State<SpendChart> {
  @override
  Widget build(BuildContext context) {
    Map<int, num> daySpendSum = <int, num>{};
    List<FlSpot> spendLineSpots = [];
    List<FlSpot> projectedLineSpots = [];

    widget.transactions.sort(
        (a, b) => a.realTransaction.date.compareTo(b.realTransaction.date));
    for (SurfacedTransaction transaction in widget.transactions) {
      if (transaction.category.type == CategoryType.spending) {
        if (!daySpendSum.containsKey(transaction.realTransaction.date.day)) {
          daySpendSum[transaction.realTransaction.date.day] = 0;
        }
        daySpendSum[transaction.realTransaction.date.day] =
            daySpendSum[transaction.realTransaction.date.day]! +
                transaction.getAmount();
      }
    }
    print(daySpendSum);
    spendLineSpots.add(const FlSpot(0, 0));

    int daysToCount = DateTime.fromMillisecondsSinceEpoch(min(
            widget.endDate.millisecondsSinceEpoch,
            DateTime.now().millisecondsSinceEpoch))
        .difference(widget.startDate)
        .inDays;

    num iteratorSum = 0;
    for (var i = 1; i <= daysToCount + 1; i++) {
      if (daySpendSum.containsKey(i)) {
        iteratorSum += daySpendSum[i]!;
      }
      spendLineSpots.add(FlSpot(i.toDouble(), iteratorSum.toDouble()));
    }
    DateTime maxDate = DateTime.now();
    if (maxDate.isBefore(widget.endDate)) {
      num dailySpendRate = iteratorSum / maxDate.day.toDouble();
      projectedLineSpots.addAll([
        FlSpot(maxDate.day.toDouble(), iteratorSum.toDouble()),
        FlSpot(
            widget.endDate.day.toDouble(),
            iteratorSum.toDouble() +
                (dailySpendRate * (widget.endDate.day - maxDate.day))),
      ]);
      print(projectedLineSpots);
    }
    print(spendLineSpots);

    return AspectRatio(
        aspectRatio: 3,
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
                        //isCurved: true,
                        isStrokeJoinRound: true,
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
