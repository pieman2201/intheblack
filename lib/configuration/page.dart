import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/editors/budgeteditor.dart';
import 'package:pfm/editors/categoryeditor.dart';
import 'package:pfm/editors/rule/ruleeditor.dart';
import 'package:pfm/widgets/budget.dart';
import 'package:pfm/widgets/category.dart';

import '../widgets/rule.dart';

class ConfigurationPage extends StatefulWidget {
  final BackendController backendController;

  const ConfigurationPage({super.key, required this.backendController});

  @override
  State<StatefulWidget> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Iterable<Category> _categories = [];
  Iterable<Budget> _budgets = [];
  Iterable<RuleWithSegments> _rules = [];

  @override
  void initState() {
    super.initState();

    // Trigger first-time 'refresh'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: () async {
        _budgets = await widget.backendController.getBudgets();
        _categories = await widget.backendController.getCategories();
        _rules = await widget.backendController.getRulesWithSegments();
        setState(() {});
      },
      child: Theme(
        data: Theme.of(context).copyWith(
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ))),
        child: ListView(
          children: [
            Card(
                child: Padding(
                    padding: EdgeInsets.only(bottom: _budgets.isEmpty ? 0 : 12),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            "Categories",
                          ),
                          //style: Theme.of(context).textTheme.titleLarge),,
                          trailing: TextButton(
                            onPressed: () async {
                              Category? newCategory = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CategoryPage(
                                            backendController:
                                                widget.backendController,
                                            category: null,
                                          )));
                              if (newCategory != null) {
                                setState(() {});
                              }
                              _refreshIndicatorKey.currentState?.show();
                            },
                            child: const Text('Add'),
                          ),
                        ),
                        ...(_categories.map((e) => CategoryListItem(
                            backendController: widget.backendController,
                            category: e)))
                      ],
                    ))),
            Card(
                child: Padding(
                    padding: EdgeInsets.only(bottom: _budgets.isEmpty ? 0 : 12),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            "Budgets",
                          ),
                          //style: Theme.of(context).textTheme.titleLarge),,
                          trailing: TextButton(
                            onPressed: () async {
                              Budget? newBudget = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BudgetPage(
                                            backendController:
                                                widget.backendController,
                                            budget: null,
                                          )));
                              if (newBudget != null) {
                                setState(() {});
                              }
                              _refreshIndicatorKey.currentState?.show();
                            },
                            child: const Text('Add'),
                          ),
                        ),
                        ...(_budgets.map((e) => BudgetListItem(
                            backendController: widget.backendController,
                            budget: e)))
                      ],
                    ))),
            Card(
                child: Padding(
                    padding: EdgeInsets.only(bottom: _budgets.isEmpty ? 0 : 12),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            "Rules",
                          ),
                          //style: Theme.of(context).textTheme.titleLarge),,
                          trailing: TextButton(
                            onPressed: () async {
                              RuleWithSegments? newRule = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RulePage(
                                            backendController:
                                                widget.backendController,
                                            ruleWithSegments: null,
                                          )));
                              if (newRule != null) {
                                setState(() {});
                              }
                              _refreshIndicatorKey.currentState?.show();
                            },
                            child: const Text('Add'),
                          ),
                        ),
                        ...(_rules.map((e) => RuleListItem(
                            backendController: widget.backendController,
                            ruleWithSegments: e)))
                      ],
                    ))),
          ],
        ),
      ),
    );
  }
}
