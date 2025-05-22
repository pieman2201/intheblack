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
  late TextEditingController _nameEditingController;
  List<Category> selectedCategories = [];
  List<Category> allCategories = [];

  @override
  void initState() {
    super.initState();

    _limitEditingController = TextEditingController();
    _nameEditingController = TextEditingController();

    if (widget.budget != null) {
      _limitEditingController.text = widget.budget!.limit.toString();
      _nameEditingController.text = widget.budget!.name;
      // Load associated categories in didChangeDependencies
    }
    
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    allCategories = (await widget.backendController.getCategories()).toList();
    
    if (widget.budget != null) {
      // Load categories associated with this budget
      selectedCategories = await widget.backendController.getCategoriesForBudget(widget.budget!);
    }
    
    if (mounted) setState(() {});
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
              controller: _nameEditingController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Budget Name',
              ),
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Select Categories for this Budget', 
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          allCategories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  ...(allCategories
                      .map((e) => CheckboxListTile(
                            value: selectedCategories.any((c) => c.id == e.id),
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
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  // Add to selected categories
                                  if (!selectedCategories.any((c) => c.id == e.id)) {
                                    selectedCategories.add(e);
                                  }
                                } else {
                                  // Remove from selected categories
                                  selectedCategories.removeWhere((c) => c.id == e.id);
                                }
                              });
                            },
                          ))
                      .toList()),
                ])
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_nameEditingController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a budget name')),
            );
            return;
          }
          
          if (selectedCategories.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select at least one category')),
            );
            return;
          }
          
          num limitValue;
          try {
            limitValue = num.parse(_limitEditingController.text.trim());
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a valid limit value')),
            );
            return;
          }
          
          // Create or update budget
          Budget budget = widget.budget ??
              Budget(
                  id: -1,
                  name: _nameEditingController.text.trim(),
                  limit: limitValue);
                  
          if (widget.budget != null) {
            budget.name = _nameEditingController.text.trim();
            budget.limit = limitValue;
          }
          
          // Save budget with selected categories
          Budget updatedBudget = await widget.backendController.upsertBudget(
            budget, selectedCategories);
            
          if (context.mounted) {
            Navigator.pop(context, updatedBudget);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
