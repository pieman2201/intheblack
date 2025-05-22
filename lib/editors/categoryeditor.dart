import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/editors/budgeteditor.dart';
import 'package:pfm/editors/rule/ruleeditor.dart';
import 'package:pfm/widgets/budget.dart';
import 'package:pfm/widgets/rule.dart';

import '../backend/types.dart';

class CategoryPage extends StatefulWidget {
  final BackendController backendController;
  final Category? category;

  const CategoryPage({
    super.key,
    required this.backendController,
    required this.category,
  });

  @override
  State<StatefulWidget> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late TextEditingController _nameEditingController;
  late TextEditingController _iconEditingController;

  CategoryType _categoryType = CategoryType.spending;

  Budget? _budget;
  Iterable<RuleWithSegments> _rules = [];

  void _loadCategoryData() async {
    if (widget.category == null) {
      return;
    }

    // Get associated budget by checking the budgetId on the category
    if (widget.category!.budgetId != null) {
      _budget = await widget.backendController.dbClient.getBudgetById(
        widget.category!.budgetId!,
      );
    }

    // Get rules for this category
    var rules = await widget.backendController.getRulesWithSegments();
    _rules = rules.where((element) => element.rule.category == widget.category);

    if (context.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _nameEditingController = TextEditingController();
    _iconEditingController = TextEditingController();

    if (widget.category != null) {
      _nameEditingController.text = widget.category!.name;
      _iconEditingController.text = widget.category!.icon.toInt().toString();
      _categoryType = widget.category!.type;

      _loadCategoryData();
    }
  }

  // New method to select an existing budget
  Future<void> _assignToExistingBudget() async {
    // Get all available budgets
    final budgets = await widget.backendController.getBudgets();

    if (!context.mounted) return;

    // Show dialog to select a budget
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Budget'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              Budget budget = budgets.elementAt(index);
              return ListTile(
                title: Text(budget.name),
                subtitle: Text('\$${budget.limit.toStringAsFixed(2)}'),
                onTap: () async {
                  // Associate category with this budget
                  if (widget.category != null) {
                    Category updatedCategory = widget.category!;
                    updatedCategory.budgetId = budget.id;
                    await widget.backendController.upsertCategory(
                      updatedCategory,
                    );

                    _budget = budget;
                    Navigator.of(context).pop();
                    _loadCategoryData();
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TextField(
              controller: _nameEditingController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CategoryType>(
              segments: const [
                ButtonSegment(
                  value: CategoryType.spending,
                  icon: Icon(Icons.show_chart),
                ),
                ButtonSegment(
                  value: CategoryType.living,
                  icon: Icon(Icons.night_shelter_outlined),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  icon: Icon(Icons.payments_outlined),
                ),
                ButtonSegment(
                  value: CategoryType.ignored,
                  icon: Icon(Icons.more_outlined),
                ),
                ButtonSegment(
                  value: CategoryType.invisible,
                  icon: Icon(Icons.visibility_off_outlined),
                ),
              ],
              selected: {_categoryType},
              onSelectionChanged: (Set<CategoryType> newSelection) {
                setState(() {
                  _categoryType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    autocorrect: false,
                    controller: _iconEditingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Icon code',
                    ),
                    onEditingComplete: () {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  child: _iconEditingController.text.isEmpty
                      ? const Icon(Icons.check_box_outline_blank)
                      : Icon(
                          IconData(
                            int.parse(_iconEditingController.text),
                            fontFamily: 'MaterialIcons',
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (_budget != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Budget", style: Theme.of(context).textTheme.titleMedium),
        ),
      );
      items.add(
        BudgetListItem(
          backendController: widget.backendController,
          budget: _budget!,
        ),
      );
    } else if (widget.category != null) {
      // Add budget management options
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Add to existing budget
              ElevatedButton(
                onPressed: _assignToExistingBudget,
                child: const Text("Use Existing Budget"),
              ),
              // Create new budget
              ElevatedButton(
                onPressed: () async {
                  // Create a new budget with this category's name
                  Budget newBudget = Budget(
                    id: -1,
                    name: '${widget.category!.name} Budget',
                    limit: 0,
                  );

                  // Navigate to budget editor
                  final Budget? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetPage(
                        backendController: widget.backendController,
                        budget: newBudget,
                      ),
                    ),
                  );

                  // If a budget was created, associate it with this category
                  if (result != null) {
                    // Update the category to point to this budget
                    Category updatedCategory = widget.category!;
                    updatedCategory.budgetId = result.id;
                    await widget.backendController.upsertCategory(
                      updatedCategory,
                    );

                    // Reload to show the new budget
                    _loadCategoryData();
                  }
                },
                child: const Text("Create New Budget"),
              ),
            ],
          ),
        ),
      );
    }

    if (_rules.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Rules", style: Theme.of(context).textTheme.titleMedium),
        ),
      );
      for (var rule in _rules) {
        items.add(
          RuleListItem(
            backendController: widget.backendController,
            ruleWithSegments: rule,
          ),
        );
      }
    } else if (widget.category != null) {
      items.add(
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RulePage(
                  backendController: widget.backendController,
                  ruleWithSegments: RuleWithSegments(
                    rule: Rule(id: -1, category: widget.category!, priority: 0),
                    segments: [],
                  ),
                ),
              ),
            );
          },
          child: const Text("Add rule"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Configure category")),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemBuilder: (BuildContext context, int index) => items[index],
        itemCount: items.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Category category =
              widget.category ??
              Category(id: -1, name: '', type: CategoryType.spending, icon: 0);
          try {
            if (_nameEditingController.text.isEmpty) {
              throw Exception();
            }
            category.name = _nameEditingController.text.trim();
            category.type = _categoryType;
            category.icon = int.parse(_iconEditingController.text);
          } on Exception {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please submit a valid category")),
            );
            return;
          }
          // If editing an existing category and it has a budget already, preserve the association
          if (widget.category != null && widget.category!.budgetId != null) {
            category.budgetId = widget.category!.budgetId;
          }

          await widget.backendController.upsertCategory(category);
          if (context.mounted) {
            Navigator.pop(context, category);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
