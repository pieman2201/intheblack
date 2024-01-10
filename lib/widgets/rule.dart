import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/editors/rule/ruleeditor.dart';

class RuleListItem extends StatefulWidget {
  final BackendController backendController;
  final RuleWithSegments ruleWithSegments;

  const RuleListItem(
      {super.key, required this.backendController, required this.ruleWithSegments});

  @override
  State<RuleListItem> createState() => _RuleListItemState();
}

class _RuleListItemState extends State<RuleListItem> {
  late RuleWithSegments _rule;

  @override
  void initState() {
    super.initState();

    _rule = widget.ruleWithSegments;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child:
        Icon(IconData(_rule.rule.category.icon, fontFamily: 'MaterialIcons')),
      ),
      title: Text(
        _rule.rule.category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
      Text('${_rule.segments.length} segment(s)'),
      trailing: Text(_rule.rule.priority.toString()),
      onTap: () async {
        RuleWithSegments? newRule = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RulePage(
                  backendController: widget.backendController,
                  ruleWithSegments: _rule,
                )));
        setState(() {
          if (newRule != null) {
            _rule = newRule;
          }
        });
      },
      onLongPress: () async {
        bool? delete = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete rule?"),
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
          await widget.backendController.deleteRuleWithSegments(_rule);
          setState(() {});
        }
      },
    );
  }
}
