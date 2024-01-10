import 'package:flutter/material.dart';
import 'package:pfm/widgets/spendcard/categorytypespend.dart';

import '../../backend/types.dart';

class SpendCard extends StatelessWidget {
  final Iterable<Budget> budgets;
  final Iterable<SurfacedTransaction> transactions;

  const SpendCard(
      {super.key, required this.budgets, required this.transactions});

  @override
  Widget build(BuildContext context) {
    Map<Category, num> categorySpends = <Category, num>{};
    for (Budget budget in budgets) {
      categorySpends[budget.category] = 0;
    }
    for (SurfacedTransaction transaction in transactions) {
      if (categorySpends[transaction.category] == null) {
        categorySpends[transaction.category] = 0;
      }
      categorySpends[transaction.category] =
          categorySpends[transaction.category]! + transaction.getAmount();
    }

    Map<CategoryType, List<Budget>> categoryTypeBudgets =
        <CategoryType, List<Budget>>{};
    for (CategoryType categoryType in CategoryType.values) {
      categoryTypeBudgets[categoryType] = [];
    }
    for (Budget budget in budgets) {
      categoryTypeBudgets[budget.category.type]!.add(budget);
    }
    for (CategoryType categoryType in CategoryType.values) {
      categoryTypeBudgets[categoryType]!.sort((a, b) =>
          categorySpends[b.category]!.compareTo(categorySpends[a.category]!));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryTypeSpend(
            type: CategoryType.spending,
            budgets: categoryTypeBudgets[CategoryType.spending]!,
            categoryAmountSpentMap: categorySpends,
            formatAmount: (num amount) {
              amount = amount.round();
              if (amount < 0) {
                return '+\$${amount.abs().toStringAsFixed(0)}';
              }
              return '\$${amount.toStringAsFixed(0)}';
            },
            formatRemainingAmount: (num amount) {
              if (amount < 0) {
                return '\$${amount.round().abs().toStringAsFixed(0)} over';
              }
              return '\$${amount.round().toStringAsFixed(0)} left';
            },
            formatMiscAmount: (num amount) {
              if (amount < 0) {
                return '\$${amount.abs().toStringAsFixed(2)} surplus';
              }
              return '\$${amount.toStringAsFixed(2)} extra';
            },
          ),
          //const Divider(),
          CategoryTypeSpend(
            type: CategoryType.living,
            budgets: categoryTypeBudgets[CategoryType.living]!,
            categoryAmountSpentMap: categorySpends,
            formatAmount: (num amount) {
              if (amount < 0) {
                return '+\$${amount.abs().toStringAsFixed(0)}';
              }
              return '\$${amount.toStringAsFixed(0)}';
            },
            formatRemainingAmount: (num amount) {
              if (amount < 0) {
                return '\$${amount.abs().toStringAsFixed(0)} over';
              }
              return '\$${amount.toStringAsFixed(0)} left';
            },
            formatMiscAmount: (num amount) {
              if (amount < 0) {
                return '\$${amount.abs().toStringAsFixed(2)} surplus';
              }
              return '\$${amount.toStringAsFixed(2)} extra';
            },
          ),
          //const Divider(),
          CategoryTypeSpend(
            type: CategoryType.income,
            budgets: categoryTypeBudgets[CategoryType.income]!,
            categoryAmountSpentMap: categorySpends,
            formatAmount: (num amount) {
              if (amount <= 0) {
                return '\$${amount.abs().toStringAsFixed(0)}';
              }
              return '-\$${amount.toStringAsFixed(0)}';
            },
            formatRemainingAmount: (num amount) {
              if (amount < 0) {
                return '\$${amount.abs().toStringAsFixed(0)} expected';
              }
              return '\$${amount.toStringAsFixed(0)} extra';
            },
            formatMiscAmount: (num amount) {
              if (amount <= 0) {
                return '\$${amount.abs().toStringAsFixed(2)} surplus';
              }
              return '\$${amount.toStringAsFixed(2)} deficit';
            },
          )
        ],
      ),
    );
  }
}
