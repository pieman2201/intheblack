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
    return min(1, amountSpent / budget.effectiveLimit).toDouble();
  }

  String getCategoryTitle() {
    String typeString = widget.type.toString().toLowerCase().split('.').last;
    return typeString.substring(0, 1).toUpperCase() + typeString.substring(1);
  }

  Widget reshapeBudgetCardList(List<Widget> budgetCards) {
    List<Widget> rowChildren = [];
    List<Widget> rows = [];
    for (Widget budgetCard in budgetCards) {
      rowChildren.add(Expanded(child: budgetCard));
      if (rowChildren.length == 2) {
        rows.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren.toList(),
            )));
        rowChildren = [];
      } else {
        //rowChildren.add(SizedBox(width: 8,));
      }
    }
    if (rowChildren.isNotEmpty) {
      // must be length 1
      rowChildren.add(const Expanded(
        child: SizedBox.shrink(),
      ));
      rows.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren.toList(),
          )));
    }
    return Column(
      //mainAxisAlignment: MainAxisAlignment.start,
      children: rows,
    );
  }

  List<Widget> reshapeUncategorizedCardList(List<Widget> uncategorizedWidgets,
      {Function? closeFunction}) {
    List<Widget> budgetGroups = [];
    List<Widget> currentGroup = [];
    for (Widget uncategorizedWidget in uncategorizedWidgets) {
      Widget uncategorizedCard;
      if (currentGroup.isEmpty) {
        // top left
        uncategorizedCard = Card(
          margin: const EdgeInsets.only(right: 1, bottom: 1),
          child: uncategorizedWidget,
        );
      } else if (currentGroup.length == 1) {
        // top right
        uncategorizedCard = Card(
          margin: const EdgeInsets.only(left: 1, bottom: 1),
          child: uncategorizedWidget,
        );
      } else if (currentGroup.length == 2) {
        // bottom left
        uncategorizedCard = Card(
          margin: const EdgeInsets.only(right: 1, top: 1),
          child: uncategorizedWidget,
        );
      } else {
        // bottom right
        uncategorizedCard = Card(
          margin: const EdgeInsets.only(left: 1, top: 1),
          child: uncategorizedWidget,
        );
      }
      currentGroup.add(uncategorizedCard);
      if (currentGroup.length == 4) {
        budgetGroups.add(reshapeBudgetCardList(currentGroup.toList()));
        currentGroup = [];
      }
    }
    if (currentGroup.isNotEmpty) {
      currentGroup.add(Card(
        margin: switch (currentGroup.length) {
          1 => EdgeInsets.only(left: 1, bottom: 1),
          2 => EdgeInsets.only(right: 1, top: 1),
          3 => EdgeInsets.only(left: 1, top: 1),
          _ => EdgeInsets.zero
        },
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            if (closeFunction != null) {
              closeFunction();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left),
                Text("Hide"),
              ],
            ),
          ),
        ),
      ));
      while (currentGroup.length < 3) {
        currentGroup.add(Card(
          elevation: 0,
          margin: currentGroup.length == 1
              ? const EdgeInsets.only(left: 1, bottom: 1)
              : const EdgeInsets.only(right: 1, top: 1),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.add,
                color: Theme.of(context).colorScheme.background),
          ),
        ));
      }
      budgetGroups.add(Container(
          margin: EdgeInsets.symmetric(vertical: 3),
          child: reshapeBudgetCardList(currentGroup)));
    } else {
      // add close button as a separate card
    }
    return budgetGroups;
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
          Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 8),
              child: Row(children: [
                Text(
                  getCategoryTitle(),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                    widget.formatAmount((widget.budgets.isNotEmpty
                            ? widget.budgets
                                .map((e) =>
                                    widget.categoryAmountSpentMap[e.category] ??
                                    0)
                                .reduce((v, e) => v + e)
                            : 0) +
                        (unBudgetedCategories.isNotEmpty
                            ? unBudgetedCategories
                                .map((e) =>
                                    widget.categoryAmountSpentMap[e] ?? 0)
                                .reduce((value, element) => value + element)
                            : 0)),
                    style: Theme.of(context).textTheme.titleMedium)
              ])),
          reshapeBudgetCardList(widget.budgets
                  .map((budget) => Card(
                      child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                    widget.formatAmount(
                                        widget.categoryAmountSpentMap[
                                            budget.category]!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)),
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeAlign: BorderSide.strokeAlignInside,
                                    strokeCap: StrokeCap.round,
                                    value: getBudgetSpentDecimal(
                                        budget,
                                        widget.categoryAmountSpentMap[
                                            budget.category]!),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(budget.category.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  Text(
                                      widget.formatRemainingAmount(
                                          (budget.effectiveLimit -
                                              widget.categoryAmountSpentMap[
                                                  budget.category]!)),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ]),
                          ]))))
                  .toList()
                  .cast<Widget>() +
              (unBudgetedCategories.isNotEmpty && _expanded
                  ? reshapeUncategorizedCardList(
                      unBudgetedCategories
                          .map((e) => Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Icon(
                                    IconData(e.icon,
                                        fontFamily: 'MaterialIcons'),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(widget.formatAmount(
                                      widget.categoryAmountSpentMap[e]!))
                                ],
                              )))
                          .toList(), closeFunction: () {
                      setState(() {
                        _expanded = false;
                      });
                    })
                  : (unBudgetedCategories.isNotEmpty
                      ? [
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, right: 0, top: 8, bottom: 8),
                                  child: Row(children: [
                                    SizedBox(
                                        height: 48,
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("Everything else",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall),
                                              Text(
                                                  widget.formatAmount(
                                                      unBudgetedCategories
                                                          .map((e) =>
                                                              widget.categoryAmountSpentMap[
                                                                  e] ??
                                                              0)
                                                          .reduce((value,
                                                                  element) =>
                                                              value + element)),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary))
                                            ])),
                                    const Spacer(),
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _expanded = true;
                                          });
                                        },
                                        icon: const Icon(Icons.chevron_right))
                                  ])))
                        ]
                      : []))),
        ],
      ),
    );
  }
}
