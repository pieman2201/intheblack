import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/configuration/categoryoverview.dart';
import 'package:pfm/util.dart';
import '../../backend/types.dart';

class CategoryTypeSpend extends StatefulWidget {
  final CategoryType type;
  final List<Budget> budgets;
  final Map<Category, num> categoryAmountSpentMap;
  final String Function(num amount) formatAmount;
  final String Function(num amount) formatRemainingAmount;
  final String Function(num amount) formatMiscAmount;
  final BackendController backendController;
  final int nthPreviousMonth;

  const CategoryTypeSpend({
    super.key,
    required this.type,
    required this.budgets,
    required this.categoryAmountSpentMap,
    required this.formatAmount,
    required this.formatRemainingAmount,
    required this.formatMiscAmount,
    required this.backendController,
    required this.nthPreviousMonth,
  });

  @override
  State<StatefulWidget> createState() => _CategoryTypeSpendState();
}

class _CategoryTypeSpendState extends State<CategoryTypeSpend> {
  bool _expandedUnbudgeted = false; // For expanding unbudgeted categories
  Map<int, bool> _expandedBudgets =
      {}; // For tracking which budgets are expanded
  List<Category> unBudgetedCategories = [];
  Set<Category> allBudgetedCategories = {};
  Map<int, List<Category>> budgetCategories =
      {}; // Maps budget IDs to their categories

  @override
  void initState() {
    super.initState();

    // Initialize budget categories from already populated budget objects
    _initializeBudgetCategories();
  }

  // Process categories for each budget from the already populated budget objects
  void _initializeBudgetCategories() {
    budgetCategories = {};
    _expandedBudgets = {};

    printDebug("INIT STATE");
    printDebug(widget.budgets);
    printDebug(widget.categoryAmountSpentMap);
    // Get all categories of this type from all budgets
    for (Budget budget in widget.budgets) {
      List<Category> categories = budget.categories
          .where((c) => c.type == widget.type)
          .toList();
      if (categories.isNotEmpty) {
        budgetCategories[budget.id] = categories;
        _expandedBudgets[budget.id] = false; // Initialize as collapsed
      }
    }

    // Get all categories of this type
    Set<Category> allCategories = widget.categoryAmountSpentMap.keys
        .where((element) => element.type == widget.type)
        .toSet();

    // Collect all categories that belong to budgets
    allBudgetedCategories = {};
    budgetCategories.forEach((budgetId, categories) {
      for (var category in categories) {
        if (category.type == widget.type) {
          allBudgetedCategories.add(category);
        }
      }
    });

    // Calculate unbudgeted categories
    Set<Category> unbCategories = Set.from(allCategories);
    unbCategories.removeAll(allBudgetedCategories);
    unBudgetedCategories = unbCategories.toList();

    _expandedUnbudgeted = allBudgetedCategories.isEmpty;
  }

  void openCategoryOverview(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryOverview(
          backendController: widget.backendController,
          category: category,
          initialNthPreviousMonth: widget.nthPreviousMonth,
          formatAmount: widget.formatAmount,
          formatRemainingAmount: widget.formatRemainingAmount,
          formatMiscAmount: widget.formatMiscAmount,
        ),
      ),
    );
  }

  double getBudgetSpentDecimal(Budget budget, num amountSpent) {
    num effectiveLimit = budget.getEffectiveLimit();
    return min(1, amountSpent / effectiveLimit).toDouble();
  }

  String getCategoryTitle() {
    String typeString = widget.type.toString().toLowerCase().split('.').last;
    return typeString.substring(0, 1).toUpperCase() + typeString.substring(1);
  }

  // Helper to calculate total spent for a specific category type
  num _calculateTypeTotal(
    CategoryType type,
    Map<int, List<Category>> budgetCategoriesMap,
  ) {
    num total = 0;

    // Go through all budgets and their categories
    budgetCategoriesMap.values.forEach((categoriesList) {
      // Filter for categories of the requested type
      for (var category in categoriesList.where((c) => c.type == type)) {
        total += widget.categoryAmountSpentMap[category] ?? 0;
      }
    });

    return total;
  }

  // Helper function to create category widgets
  List<Widget> _createCategoryWidgets(List<Category> categories) {
    categories.sort(
          (a, b) => (widget.categoryAmountSpentMap[b] ?? 0).compareTo(
        widget.categoryAmountSpentMap[a] ?? 0,
      ),
    );

    if (widget.type == CategoryType.income) {
      categories = categories.reversed.toList();
    }

    return categories.map((category) {
      final amount = widget.categoryAmountSpentMap[category] ?? 0;

      return Card.outlined(
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            openCategoryOverview(category);
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: 6,
              top: 3,
              bottom: 3,
              right: 6,
            ),
            child: Row(
              children: [
                Icon(
                  IconData(category.icon, fontFamily: 'MaterialIcons'),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: const SizedBox(), // Empty space, no category name
                ),
                Text(widget.formatAmount(amount)),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // Function to reshape a list of widgets into a column-based grid
  List<Widget> _reshapeCategoryCardList(
    List<Widget> categoryWidgets, {
    int columns = 2, // Default to 2 columns
    double spacing = 2, // Default spacing between columns and items
  }) {
    if (categoryWidgets.isEmpty) {
      return [];
    }

    // Create a list for each column
    List<List<Widget>> columnLists = List.generate(columns, (_) => []);

    // Distribute cards among columns
    for (int i = 0; i < categoryWidgets.length; i++) {
      columnLists[i % columns].add(categoryWidgets[i]);
    }

    // Create the row with all columns
    List<Widget> rowChildren = [];
    for (int i = 0; i < columns; i++) {
      rowChildren.add(
        Expanded(
          child: Column(
            spacing: spacing,
            mainAxisSize: MainAxisSize.min,
            children: columnLists[i],
          ),
        ),
      );
    }

    // Return the container with all columns
    return [
      Row(
        spacing: spacing, // Use provided spacing for horizontal spacing
        crossAxisAlignment:
            CrossAxisAlignment.start, // Keep columns top-aligned
        children: rowChildren,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    printDebug(allBudgetedCategories);

    return Theme(
      data: Theme.of(context).copyWith(
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Theme.of(context).colorScheme.primaryContainer,
          circularTrackColor: Theme.of(context).colorScheme.surface,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                Text(
                  getCategoryTitle(),
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  widget.formatAmount(
                    // Calculate budgeted categories total
                    _calculateTypeTotal(widget.type, budgetCategories) +
                        // Add unbudgeted categories total
                        (unBudgetedCategories.isNotEmpty
                            ? unBudgetedCategories
                                  .map(
                                    (e) =>
                                        widget.categoryAmountSpentMap[e] ?? 0,
                                  )
                                  .fold(0.0, (sum, amount) => sum + amount)
                            : 0),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              spacing: 4.0,
              children: [
                // Budget cards with expand/collapse functionality
                if (allBudgetedCategories.isNotEmpty)
                  ..._reshapeCategoryCardList(
                    widget.budgets.map((budget) {
                      // Skip if not loaded yet or no categories of this type
                      if (!budgetCategories.containsKey(budget.id) ||
                          budgetCategories[budget.id]!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      // Get categories of this type in the budget
                      List<Category> categories = budgetCategories[budget.id]!;

                      // Calculate total amount spent for this budget's categories
                      num totalSpent = 0;
                      for (var category in categories) {
                        totalSpent +=
                            widget.categoryAmountSpentMap[category] ?? 0;
                      }

                      num effectiveLimit = budget.getEffectiveLimit();

                      bool isExpanded = _expandedBudgets[budget.id] ?? false;

                      return Card(
                        clipBehavior: Clip.hardEdge,
                        margin: EdgeInsets.zero,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  // Toggle expanded state for this budget
                                  _expandedBudgets[budget.id] = !isExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          widget.formatAmount(totalSpent),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer,
                                              ),
                                        ),
                                        SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: CircularProgressIndicator(
                                            strokeAlign:
                                                BorderSide.strokeAlignInside,
                                            strokeCap: StrokeCap.round,
                                            value: min(
                                              1.0,
                                              totalSpent / effectiveLimit,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            budget.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          Text(
                                            widget.formatRemainingAmount(
                                              effectiveLimit - totalSpent,
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Show categories in a card-based layout when expanded, like unbudgeted categories
                            if (isExpanded && categories.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                  bottom: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _reshapeCategoryCardList(
                                    _createCategoryWidgets(categories),
                                    columns:
                                        2, // Specify 2 columns for budget categories
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    columns: 2,
                    spacing: 4,
                  ),

                // The "Everything else" section for unbudgeted categories
                if (unBudgetedCategories.isNotEmpty)
                  Card(
                    clipBehavior: Clip.hardEdge,
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row - consistent whether expanded or not
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedUnbudgeted = !_expandedUnbudgeted;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Not budgeted",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Spacer(),
                                Text(
                                  widget.formatAmount(
                                    unBudgetedCategories.isEmpty
                                        ? 0
                                        : unBudgetedCategories
                                              .map(
                                                (e) =>
                                                    widget
                                                        .categoryAmountSpentMap[e] ??
                                                    0,
                                              )
                                              .reduce(
                                                (value, element) =>
                                                    value + element,
                                              ),
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _expandedUnbudgeted
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Use the reshapeCategoryCardList function but modify for 4 columns
                        if (_expandedUnbudgeted)
                          Padding(
                            padding: EdgeInsets.only(
                              left: 4,
                              right: 4,
                              bottom: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _reshapeCategoryCardList(
                                _createCategoryWidgets(unBudgetedCategories),
                                columns: 4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
