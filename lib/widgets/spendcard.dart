import 'dart:math';

import 'package:flutter/material.dart';

import '../backend/types.dart';

class SpendCard extends StatelessWidget {
  final Iterable<Budget> budgets;
  final Iterable<SurfacedTransaction> transactions;

  const SpendCard(
      {super.key, required this.budgets, required this.transactions});

  @override
  Widget build(BuildContext context) {
    Map<int, num> budgetPercents = <int, num>{};
    Map<int, int> budgetIdToCategoryId = <int, int>{};

    Map<int, num> categorySpends = <int, num>{};
    for (SurfacedTransaction transaction in transactions) {
      if (categorySpends[transaction.category.id] == null) {
        categorySpends[transaction.category.id] = 0;
      }
      categorySpends[transaction.category.id] =
          categorySpends[transaction.category.id]! + transaction.getAmount();
    }

    Map<CategoryType, List<int>> categoryTypeBudgets =
        <CategoryType, List<int>>{};
    for (CategoryType categoryType in CategoryType.values) {
      categoryTypeBudgets[categoryType] = [];
    }
    for (Budget budget in budgets) {
      categoryTypeBudgets[budget.category.type]!.add(budget.id);

      if (categorySpends.containsKey(budget.category.id)) {
        budgetPercents[budget.id] =
            max(1.0, categorySpends[budget.category.id]! / budget.limit);
      } else {
        budgetPercents[budget.id] = 0;
      }

      budgetIdToCategoryId[budget.id] = budget.category.id;
    }

    for (CategoryType categoryType in CategoryType.values) {
      categoryTypeBudgets[categoryType]!.sort((a, b) =>
          categorySpends[budgetIdToCategoryId[b]]!
              .compareTo(budgetIdToCategoryId[a]!));
    }

    return Theme(
        data: Theme.of(context).copyWith(
            progressIndicatorTheme: ProgressIndicatorThemeData(
                color: Theme.of(context).colorScheme.primary,
                circularTrackColor: Theme.of(context).colorScheme.background)),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
                  child: Text("Spending",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Column(
                    children:
                        categoryTypeBudgets[CategoryType.spending]!.map((e) {
                      Budget budget =
                          budgets.firstWhere((element) => element.id == e);
                      return ListTile(
                        leading: CircularProgressIndicator(
                          value: budgetPercents[e]!.toDouble(),
                        ),
                        title: Text(budget.category.name),
                        subtitle: Text(
                            '\$${(budget.limit - categorySpends[budget.category.id]!).toStringAsFixed(2)} left'),
                        trailing: Text(
                            '\$${categorySpends[budget.category.id]!.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
                  child: Text("Living",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Column(
                    children:
                        categoryTypeBudgets[CategoryType.living]!.map((e) {
                      Budget budget =
                          budgets.firstWhere((element) => element.id == e);
                      return ListTile(
                        leading: CircularProgressIndicator(
                          value: budgetPercents[e]!.toDouble(),
                        ),
                        title: Text(budget.category.name),
                        subtitle: Text(
                            '\$${(budget.limit - categorySpends[budget.category.id]!).toStringAsFixed(2)} left'),
                        trailing: Text(
                            '\$${categorySpends[budget.category.id]!.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
                  child: Text("Income",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Column(
                    children:
                        categoryTypeBudgets[CategoryType.income]!.map((e) {
                      Budget budget =
                          budgets.firstWhere((element) => element.id == e);
                      return ListTile(
                        leading: CircularProgressIndicator(
                          value: budgetPercents[e]!.toDouble(),
                        ),
                        title: Text(budget.category.name),
                        subtitle: Text(
                            '\$${(budget.limit - categorySpends[budget.category.id]!).toStringAsFixed(2)} left'),
                        trailing: Text(
                            '\$${categorySpends[budget.category.id]!.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
