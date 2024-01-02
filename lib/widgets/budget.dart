import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';

import '../editors/budgeteditor.dart';

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

  @override
  void initState() {
    super.initState();

    _budget = widget.budget;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(IconData(_budget.icon, fontFamily: 'MaterialIcons')),
      ),
      title: Text(
        _budget.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_budget.type.toString().split('.').last.toUpperCase()),
      trailing: Text(_budget.limit.isNegative
          ? '+\$${_budget.limit.abs().toStringAsFixed(2)}'
          : '\$${_budget.limit.abs().toStringAsFixed(2)}'),
      onTap: () async {
        Budget? newBudget = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BudgetPage(
                      backendController: widget.backendController,
                      budget: _budget,
                    )));
        setState(() {
          if (newBudget != null) {
            _budget = newBudget;
          }
        });
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
