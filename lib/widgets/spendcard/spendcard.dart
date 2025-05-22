import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/util.dart';
import 'package:pfm/widgets/spendcard/categorytypespend.dart';

import '../../backend/types.dart';

class SpendCard extends StatefulWidget {
  final Iterable<Budget> budgets;
  final Iterable<SurfacedTransaction> transactions;
  final BackendController backendController;
  final int nthPreviousMonth;

  const SpendCard(
      {super.key,
      required this.budgets,
      required this.transactions,
      required this.backendController,
      required this.nthPreviousMonth});

  @override
  State<SpendCard> createState() => _SpendCardState();
}

class _SpendCardState extends State<SpendCard> {
  @override
  Widget build(BuildContext context) {
    Map<Category, num> categorySpends = <Category, num>{};
    for (SurfacedTransaction transaction in widget.transactions) {
      if (categorySpends[transaction.category] == null) {
        categorySpends[transaction.category] = 0;
      }
      categorySpends[transaction.category] =
          categorySpends[transaction.category]! + transaction.getAmount();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryTypeSpend(
            type: CategoryType.spending,
            budgets: widget.budgets.toList(),
            categoryAmountSpentMap: categorySpends,
            formatAmount: categoryTypeAmountFormatters[CategoryType.spending]!,
            formatRemainingAmount: categoryTypeRemainingAmountFormatters[CategoryType.spending]!,
            formatMiscAmount: categoryTypeMiscAmountFormatters[CategoryType.spending]!,
            backendController: widget.backendController,
            nthPreviousMonth: widget.nthPreviousMonth,
          ),
          //const Divider(),
          CategoryTypeSpend(
            type: CategoryType.living,
            budgets: widget.budgets.toList(),
            categoryAmountSpentMap: categorySpends,
            formatAmount: categoryTypeAmountFormatters[CategoryType.living]!,
            formatRemainingAmount: categoryTypeRemainingAmountFormatters[CategoryType.living]!,
            formatMiscAmount: categoryTypeMiscAmountFormatters[CategoryType.living]!,
            backendController: widget.backendController,
            nthPreviousMonth: widget.nthPreviousMonth,
          ),
          //const Divider(),
          CategoryTypeSpend(
            type: CategoryType.income,
            budgets: widget.budgets.toList(),
            categoryAmountSpentMap: categorySpends,
            formatAmount: categoryTypeAmountFormatters[CategoryType.income]!,
            formatRemainingAmount: categoryTypeRemainingAmountFormatters[CategoryType.income]!,
            formatMiscAmount: categoryTypeMiscAmountFormatters[CategoryType.income]!,
            backendController: widget.backendController,
            nthPreviousMonth: widget.nthPreviousMonth,
          )
        ],
      ),
    );
  }
}
