import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';

import '../backend/types.dart';

class CategoryPage extends StatefulWidget {
  final BackendController backendController;
  final Category? category;

  const CategoryPage(
      {super.key, required this.backendController, required this.category});

  @override
  State<StatefulWidget> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late TextEditingController _nameEditingController;
  late TextEditingController _iconEditingController;

  CategoryType _categoryType = CategoryType.spending;

  @override
  void initState() {
    super.initState();

    _nameEditingController = TextEditingController();
    _iconEditingController = TextEditingController();

    if (widget.category != null) {
      _nameEditingController.text = widget.category!.name;
      _iconEditingController.text = widget.category!.icon.toInt().toString();
      _categoryType = widget.category!.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      TextField(
        controller: _nameEditingController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Name',
        ),
      ),
      SegmentedButton<CategoryType>(
        segments: const [
          ButtonSegment(
              value: CategoryType.spending,
              //label: Text('Spending'),
              icon: Icon(Icons.show_chart)),
          ButtonSegment(
              value: CategoryType.living,
              //label: Text('Living'),
              icon: Icon(Icons.night_shelter_outlined)),
          ButtonSegment(
              value: CategoryType.income,
              //label: Text('Income'),
              icon: Icon(Icons.payments_outlined)),
          ButtonSegment(
              value: CategoryType.ignored,
              //label: Text('Ignored'),
              icon: Icon(Icons.visibility_off_outlined))
        ],
        selected: {_categoryType},
        onSelectionChanged: (Set<CategoryType> newSelection) {
          setState(() {
            _categoryType = newSelection.first;
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure category"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext context, int index) => items[index],
        separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 16,
        ),
        itemCount: items.length,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Category category = widget.category ??
              Category(
                id: -1,
                name: '',
                type: CategoryType.spending,
                icon: 0,
              );
          try {
            if (_nameEditingController.text.isEmpty) {
              throw Exception();
            }
            category.name = _nameEditingController.text.trim();
            category.type = _categoryType;
            category.icon = int.parse(_iconEditingController.text);
          } on Exception {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Please submit a valid category")));
            return;
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
