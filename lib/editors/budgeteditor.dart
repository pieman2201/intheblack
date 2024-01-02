import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';

import '../backend/types.dart';

class BudgetPage extends StatefulWidget {
  final BackendController backendController;
  final Budget? budget;

  const BudgetPage(
      {super.key, required this.backendController, required this.budget});

  @override
  State<StatefulWidget> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late TextEditingController _nameEditingController;
  late TextEditingController _limitEditingController;
  late TextEditingController _iconEditingController;

  BudgetType _budgetType = BudgetType.spending;

  @override
  void initState() {
    super.initState();

    _nameEditingController = TextEditingController();
    _limitEditingController = TextEditingController();
    _iconEditingController = TextEditingController();

    if (widget.budget != null) {
      _nameEditingController.text = widget.budget!.name;
      _limitEditingController.text = widget.budget!.limit.toString();
      _iconEditingController.text = widget.budget!.icon.toInt().toString();
      _budgetType = widget.budget!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure budget"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext context, int index) => [
          TextField(
            controller: _nameEditingController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Name',
            ),
          ),
          TextField(
            keyboardType: TextInputType.number,
            controller: _limitEditingController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Limit',
            ),
          ),
          SegmentedButton<BudgetType>(
            segments: const [
              ButtonSegment(
                  value: BudgetType.spending,
                  label: Text('Spending'),
                  icon: Icon(Icons.show_chart)),
              ButtonSegment(
                  value: BudgetType.living,
                  label: Text('Living'),
                  icon: Icon(Icons.night_shelter_outlined)),
              ButtonSegment(
                  value: BudgetType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.payments_outlined)),
            ],
            selected: {_budgetType},
            onSelectionChanged: (Set<BudgetType> newSelection) {
              setState(() {
                _budgetType = newSelection.first;
              });
            },
          ),
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
              const SizedBox(
                width: 8,
              ),
              CircleAvatar(
                  child: _iconEditingController.text.isEmpty
                      ? const Icon(Icons.check_box_outline_blank)
                      : Icon(IconData(int.parse(_iconEditingController.text),
                          fontFamily: 'MaterialIcons')))
            ],
          ),
        ][index],
        separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 8,
        ),
        itemCount: 4,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Budget budget = widget.budget ??
              Budget(
                id: -1,
                name: '',
                type: BudgetType.spending,
                icon: 0,
                limit: 0,
              );
          try {
            if (_nameEditingController.text.isEmpty) {
              throw Exception();
            }
            budget.name = _nameEditingController.text.trim();
            budget.type = _budgetType;
            budget.limit = num.parse(_limitEditingController.text);
            budget.icon = int.parse(_iconEditingController.text);
          } on Exception {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please submit a valid budget")));
            return;
          }
          await widget.backendController.upsertBudget(budget);
          if (context.mounted) {
            Navigator.pop(context, budget);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
