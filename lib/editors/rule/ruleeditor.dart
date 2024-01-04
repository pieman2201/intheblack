import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';

import '../../backend/types.dart';
import './segmenteditor.dart';

class RulePage extends StatefulWidget {
  final BackendController backendController;
  final RuleWithSegments? ruleWithSegments;

  const RulePage(
      {super.key,
      required this.backendController,
      required this.ruleWithSegments});

  @override
  State<RulePage> createState() => _RulePageState();
}

class _RulePageState extends State<RulePage> {
  late List<Rulesegment> _segments;
  late Rule _rule;

  @override
  void initState() {
    super.initState();

    if (widget.ruleWithSegments != null) {
      _rule = widget.ruleWithSegments!.rule;
      _segments = widget.ruleWithSegments!.segments.toList();
    } else {
      _rule = Rule(
          id: -1,
          category: widget.backendController.categorizationClient
              .getFallbackCategory(),
          priority: 0);
      _segments = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure rule"),
      ),
      body: FutureBuilder(
          future: widget.backendController.getCategories(),
          builder: (BuildContext context,
              AsyncSnapshot<Iterable<Category>> snapshot) {
            if (snapshot.hasData) {
              List<Category> categories = snapshot.data!.toList();
              return ListView(
                children: [
                  Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            setState(() {
                              _rule.priority = max(0, _rule.priority - 1);
                            });
                          },
                          icon: const Icon(Icons.remove)),
                      Expanded(child: Text('${_rule.priority}')),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              _rule.priority++;
                            });
                          },
                          icon: const Icon(Icons.add))
                    ],
                  ),
                  ...(categories.map((e) => RadioListTile<int>(
                        value: e.id,
                        groupValue: _rule.category.id,
                        title: Text(e.name),
                        subtitle: Text(
                            e.type.toString().split('.').last.toUpperCase()),
                        secondary: Icon(
                                IconData(e.icon, fontFamily: 'MaterialIcons')),
                        onChanged: (int? value) {
                          if (value != null) {
                            Category category = categories
                                .firstWhere((element) => element.id == value);
                            _rule.category = category;
                            setState(() {});
                          }
                        },
                        dense: true,
                      ))),
                  ...(() {
                    List<Widget> wList = [];
                    for (var i = 0; i < _segments.length; i++) {
                      wList.add(SegmentEditorItem(
                        segment: _segments[i],
                        onEditedCallback: (String param, RegExp regex) {
                          _segments[i].param = param;
                          _segments[i].regex = regex;
                        },
                      ));
                    }
                    return wList;
                  }()),
                  TextButton(
                      onPressed: () {
                        _segments.add(Rulesegment(
                            id: -1, rule: _rule, param: '', regex: RegExp('')));
                        setState(() {});
                      },
                      child: const Text("Add segment"))
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          RuleWithSegments ruleWithSegments =
              RuleWithSegments(rule: _rule, segments: _segments);
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
