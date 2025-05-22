import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/editors/budgeteditor.dart';

class BudgetListItem extends StatefulWidget {
  final BackendController backendController;
  final Budget budget;

  const BudgetListItem(
      {super.key, required this.backendController, required this.budget});

  @override
  State<BudgetListItem> createState() => _BudgetListItemState();
}

class _BudgetListItemState extends State<BudgetListItem> {
  late Budget _budget;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    _categories = await widget.backendController.getCategoriesForBudget(_budget);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _categories.isEmpty 
        ? const CircleAvatar(child: Icon(Icons.account_balance_wallet)) 
        : CircleAvatar(
            child: Icon(IconData(_categories.first.icon, fontFamily: 'MaterialIcons')),
          ),
      title: Text(
        _budget.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _categories.isEmpty
          ? 'No categories'
          : '${_categories.length} ${_categories.length == 1 ? 'category' : 'categories'}'),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _budget.limit.isNegative
                ? '+\$${_budget.limit.abs().toStringAsFixed(2)}'
                : '\$${_budget.limit.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_categories.isNotEmpty && _categories.length <= 3)
            Text(
              _categories.map((c) => c.name).join(', '),
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      ),
      onTap: () async {
        Budget? newBudget = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BudgetPage(
                      backendController: widget.backendController,
                      budget: _budget,
                    )));
        if (newBudget != null) {
          setState(() {
            _budget = newBudget;
          });
          // Reload categories for the updated budget
          _loadCategories();
        }
      },
      onLongPress: () async {
        bool? delete = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete budget?"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Delete'))
                ],
              );
            });
        if (delete ?? false) {
          await widget.backendController.deleteBudget(_budget);
          setState(() {});
        }
      },
    );
  }
}
