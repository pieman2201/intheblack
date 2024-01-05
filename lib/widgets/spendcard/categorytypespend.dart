import 'dart:math';

import 'package:flutter/material.dart';

import '../../backend/types.dart';

class CategoryTypeSpend extends StatefulWidget {
  final CategoryType type;
  final List<Budget> budgets;
  final Map<Category, num> categoryAmountSpentMap;
  final String Function(num amount) formatAmount;
  final String Function(num amount) formatRemainingAmount;
  final String Function(num amount) formatMiscAmount;

  const CategoryTypeSpend(
      {super.key,
      required this.type,
      required this.budgets,
      required this.categoryAmountSpentMap,
      required this.formatAmount,
      required this.formatRemainingAmount,
      required this.formatMiscAmount});

  @override
  State<StatefulWidget> createState() => _CategoryTypeSpendState();
}

class _CategoryTypeSpendState extends State<CategoryTypeSpend> {
  bool _expanded = false;
  List<Category> unBudgetedCategories = [];

  @override
  void initState() {
    super.initState();
  }

  double getBudgetSpentDecimal(Budget budget, num amountSpent) {
    print((budget.effectiveLimit, amountSpent));
    return min(1, amountSpent / budget.effectiveLimit)
        .toDouble();
  }

  String getCategoryTitle() {
    String typeString = widget.type.toString().toLowerCase().split('.').last;
    return typeString.substring(0, 1).toUpperCase() + typeString.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    Set<Category> allCategories = widget.categoryAmountSpentMap.keys
        .where((element) => element.type == widget.type)
        .toSet();
    for (Budget budget in widget.budgets) {
      allCategories.remove(budget.category);
    }
    unBudgetedCategories = allCategories.toList();
    unBudgetedCategories.sort((a, b) => widget.categoryAmountSpentMap[b]!
        .compareTo(widget.categoryAmountSpentMap[a]!));

    return Theme(
      data: Theme.of(context).copyWith(
          progressIndicatorTheme: ProgressIndicatorThemeData(
              color: Theme.of(context).colorScheme.primary,
              circularTrackColor: Theme.of(context).colorScheme.background)),
      child: Column(
        children: [
          ListTile(
              title: Text(getCategoryTitle(),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleLarge),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              trailing: unBudgetedCategories.isNotEmpty
                  ? Text(widget.formatMiscAmount(unBudgetedCategories
                      .map((e) => widget.categoryAmountSpentMap[e] ?? 0)
                      .reduce((value, element) => value + element)))
                  : const SizedBox.shrink()),
          ...(widget.budgets.map((budget) => ListTile(
                leading: CircularProgressIndicator(
                  value: getBudgetSpentDecimal(
                      budget, widget.categoryAmountSpentMap[budget.category]!),
                ),
                title: Text(budget.category.name),
                subtitle: Text(widget.formatRemainingAmount(
                    (budget.effectiveLimit -
                        widget.categoryAmountSpentMap[budget.category]!))),
                trailing: Text(widget.formatAmount(
                    widget.categoryAmountSpentMap[budget.category]!)),
              ))),
          unBudgetedCategories.isNotEmpty
              ? (!_expanded
                  ? const SizedBox.shrink()
                  : Column(
                      children: unBudgetedCategories
                          .map((e) => ListTile(
                                title: Text(e.name),
                                leading: Icon(IconData(e.icon,
                                    fontFamily: 'MaterialIcons')),
                                trailing: Text(widget.formatAmount(
                                    widget.categoryAmountSpentMap[e]!)),
                              ))
                          .toList(),
                    ))
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
