import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';

import '../backend/types.dart';

class BudgetPage extends StatefulWidget {
  final BackendController backendController;
  final Budget? budget;

  const BudgetPage(
      {super.key, required this.backendController, required this.budget});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late TextEditingController _limitEditingController;
  late Category category;

  @override
  void initState() {
    super.initState();

    _limitEditingController = TextEditingController();

    if (widget.budget != null) {
      _limitEditingController.text = widget.budget!.limit.toString();
      category = widget.budget!.category;
    } else {
      category = widget.backendController.categorizationClient.getFallbackCategory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure budget"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _limitEditingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Limit',
              ),
            ),
          ),
          FutureBuilder(
              future: widget.backendController.getCategories(),
              builder: (BuildContext context,
                  AsyncSnapshot<Iterable<Category>> snapshot) {
                if (snapshot.hasData) {
                  return Column(children: [
                    ...(snapshot.data!
                        .map((e) => RadioListTile<int?>(
                              value: e.id,
                              groupValue: category.id,
                              title: Text(e.name),
                              subtitle: Text(e.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase()),
                              secondary: CircleAvatar(
                                child: Icon(IconData(e.icon,
                                    fontFamily: 'MaterialIcons')),
                              ),
                              onChanged: (int? value) {
                                setState(() {
                                  category = snapshot.data!
                                      .firstWhere((element) => element.id == value);
                                });
                              },
                            ))
                        .toList()),
                  ]);
                } else {
                  return const SizedBox.shrink();
                }
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Budget budget = widget.budget ??
              Budget(
                  id: -1,
                  category: category,
                  limit: num.parse(_limitEditingController.text.trim()));
          budget.category = category;
          budget.limit = num.parse(_limitEditingController.text.trim());
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
