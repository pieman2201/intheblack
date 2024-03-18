import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/widgets/category.dart';

import '../editors/categoryeditor.dart';

class ConfigurationPage extends StatefulWidget {
  final BackendController backendController;

  const ConfigurationPage({super.key, required this.backendController});

  @override
  State<StatefulWidget> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Category> _categories = [];


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
        _categories = (await widget.backendController.getCategories()).toList();
        setState(() {});
      },
      child: CustomScrollView(slivers: [
        SliverAppBar.medium(
          actions: [
            IconButton(onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CategoryPage(
                        backendController: widget.backendController, category: null,
                      )));
              _refreshIndicatorKey.currentState?.show();
            }, icon: const Icon(Icons.add))
          ],
            flexibleSpace: const FlexibleSpaceBar(
          titlePadding: EdgeInsets.only(left: 16, bottom: 16),
          title: Text("Categories"),
        )),
        SliverList.separated(
          itemCount: _categories.length,
          itemBuilder: (BuildContext context, int index) {
            return CategoryListItem(
                backendController: widget.backendController,
                category: _categories[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              height: 0,
            );
          },
        )
      ]),
    );
  }
}
