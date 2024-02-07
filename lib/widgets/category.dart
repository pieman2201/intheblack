import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/configuration/categoryoverview.dart';
import 'package:pfm/editors/categoryeditor.dart';
import 'package:pfm/util.dart';

class CategoryListItem extends StatefulWidget {
  final BackendController backendController;
  final Category category;

  const CategoryListItem(
      {super.key, required this.backendController, required this.category});

  @override
  State<CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<CategoryListItem> {
  late Category _category;

  @override
  void initState() {
    super.initState();

    _category = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(IconData(_category.icon, fontFamily: 'MaterialIcons')),
      ),
      title: Text(
        _category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_category.type.toString().split('.').last.toUpperCase()),
      onTap: () async {
        Category? newCategory = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CategoryOverview(
                      backendController: widget.backendController,
                      category: _category,
                      initialNthPreviousMonth: 0,
                      formatAmount:
                          categoryTypeAmountFormatters[_category.type]!,
                      formatRemainingAmount:
                          categoryTypeRemainingAmountFormatters[
                              _category.type]!,
                      formatMiscAmount:
                          categoryTypeMiscAmountFormatters[_category.type]!,
                    )));
        setState(() {
          if (newCategory != null) {
            _category = newCategory;
          }
        });
      },
      onLongPress: () async {
        bool? delete = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete category?"),
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
          await widget.backendController.deleteCategory(_category);
          setState(() {});
        }
      },
    );
  }
}
