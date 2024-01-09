import 'package:flutter/material.dart';
import 'package:pfm/backend/types.dart';

class SegmentEditorItem extends StatefulWidget {
  final Rulesegment? segment;
  final Function(String param, RegExp regex) onEditedCallback;

  const SegmentEditorItem(
      {super.key, this.segment, required this.onEditedCallback});

  @override
  State<StatefulWidget> createState() => _SegmentEditorItemState();
}

class _SegmentEditorItemState extends State<SegmentEditorItem> {
  late TextEditingController _paramEditingController;
  late TextEditingController _regexEditingController;

  @override
  void initState() {
    super.initState();

    _paramEditingController = TextEditingController();
    _regexEditingController = TextEditingController();

    if (widget.segment != null) {
      _paramEditingController.text = widget.segment!.param;
      _regexEditingController.text = widget.segment!.regex.pattern;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            autocorrect: false,
            controller: _paramEditingController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Param',
            ),
            onChanged: (String value) {
              widget.onEditedCallback(value,
                  RegExp(_regexEditingController.text));
              setState(() {});
            },
          ),
        ),
        Expanded(
            child: TextField(
          autocorrect: false,
          controller: _regexEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Regex',
          ),
          onChanged: (String value) {
            widget.onEditedCallback(_paramEditingController.text,
                RegExp(value));
            setState(() {});
          },
        ))
      ],
    );
  }
}
