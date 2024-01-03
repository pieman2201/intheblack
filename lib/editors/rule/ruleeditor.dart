import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';

import '../../backend/types.dart';
import './segmenteditor.dart';

class RulePage extends StatefulWidget {
  final BackendController backendController;
  final RuleWithSegments ruleWithSegments;

  const RulePage(
      {super.key,
      required this.backendController,
      required this.ruleWithSegments});

  @override
  State<RulePage> createState() => _RulePageState();
}

class _RulePageState extends State<RulePage> {
  late List<Rulesegment> _segments;

  @override
  void initState() {
    super.initState();

    _segments = widget.ruleWithSegments.segments.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure rule"),
      ),
      body: Column(
        children: [
          FutureBuilder(
              future: widget.backendController.getCategories(),
              builder: (BuildContext context,
                  AsyncSnapshot<Iterable<Category>> snapshot) {
                if (snapshot.hasData) {
                  List<Category> categories = snapshot.data!.toList();
                  return ListView.builder(
                      itemBuilder: (BuildContext context, int index) {
                    return RadioListTile<int>(
                      value: categories[index].id,
                      groupValue: widget.ruleWithSegments.rule.category.id,
                      onChanged: (int? value) {
                        if (value != null) {
                          Category category = categories
                              .firstWhere((element) => element.id == value);
                          widget.ruleWithSegments.rule.category = category;
                          setState(() {});
                        }
                      },
                    );
                  });
                }
                return const SizedBox.shrink();
              }),
          ListView.builder(itemBuilder: (BuildContext context, int indexVar) {
            int index = indexVar;
            if (index >= _segments.length) {
              return TextButton(
                  onPressed: () {
                    _segments.add(Rulesegment(
                        id: -1,
                        rule: widget.ruleWithSegments.rule,
                        param: '',
                        regex: RegExp('')));
                    setState(() {});
                  },
                  child: const Text("Add segment"));
            }
            return SegmentEditorItem(
              segment: _segments[index],
              onEditedCallback: (String param, RegExp regex) {
                _segments[index].param = param;
                _segments[index].regex = regex;
              },
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          RuleWithSegments ruleWithSegments = RuleWithSegments(
              rule: widget.ruleWithSegments.rule, segments: _segments);
          await widget.backendController
              .upsertRuleWithSegments(ruleWithSegments);
          if (context.mounted) {
            Navigator.pop(context, ruleWithSegments);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
