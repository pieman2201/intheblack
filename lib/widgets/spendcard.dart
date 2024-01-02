import 'package:flutter/material.dart';

import '../backend/types.dart';

class SpendCard extends StatelessWidget {
  final Iterable<Budget> budgets;
  final Iterable<SurfacedTransaction> transactions;

  const SpendCard(
      {super.key, required this.budgets, required this.transactions});

  @override
  Widget build(BuildContext context) {
    Map<int, num> budgetSpends = <int, num>{};
    Map<int, num> budgetPercents = <int, num>{};
    for (Budget budget in budgets) {
      budgetSpends[budget.id] = 0;
    }
    for (SurfacedTransaction transaction in transactions) {
      if (transaction.budget == null) {
        // Skip uncategorized transactions
        continue;
      }
      budgetSpends[transaction.budget!.id] =
          budgetSpends[transaction.budget!.id]! + transaction.getAmount();
    }
    print(budgetSpends);
    for (Budget budget in budgets) {
      print(budget);
      num spend = budgetSpends[budget.id]! / budget.limit;
      if (spend.isInfinite || spend.isNaN) {
        budgetPercents[budget.id] = 0;
      } else {
        budgetPercents[budget.id] = spend;
      }
    }

    Map<BudgetType, num> budgetTypeLimits = <BudgetType, num>{};
    Map<BudgetType, num> budgetTypeSpends = <BudgetType, num>{};
    Map<BudgetType, num> budgetTypePercents = <BudgetType, num>{};
    for (BudgetType budgetType in BudgetType.values) {
      budgetTypeSpends[budgetType] = 0;
      budgetTypeLimits[budgetType] = 0;
    }
    for (int budgetId in budgetSpends.keys) {
      Budget budget = budgets.firstWhere((element) => element.id == budgetId);
      budgetTypeLimits[budget.type] =
          budgetTypeLimits[budget.type]! + budget.limit;
      budgetTypeSpends[budget.type] =
          budgetTypeSpends[budget.type]! + budgetSpends[budget.id]!;
    }
    for (BudgetType budgetType in BudgetType.values) {
      num percent =
          budgetTypeSpends[budgetType]! / budgetTypeLimits[budgetType]!;
      if (percent.isInfinite || percent.isNaN) {
        budgetTypePercents[budgetType] = 1.0;
      } else {
        budgetTypePercents[budgetType] = percent;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          children: [
            ListTile(
              leading: CircularProgressIndicator(
                value: budgetTypePercents[BudgetType.spending]!.toDouble(),
              ),
              title: Text("Spending"),
            ),
            ListTile(
              leading: CircularProgressIndicator(
                value: budgetTypePercents[BudgetType.living]!.toDouble(),
              ),
              title: Text("Living"),
            ),
          ],
        ),
      ),
    );
  }
}
