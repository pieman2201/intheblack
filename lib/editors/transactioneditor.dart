import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/util.dart';

class TransactionPage extends StatefulWidget {
  final BackendController backendController;
  final SurfacedTransaction transaction;

  const TransactionPage({
    super.key,
    required this.backendController,
    required this.transaction,
  });

  @override
  State<StatefulWidget> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late SurfacedTransaction transaction;

  @override
  void initState() {
    super.initState();

    transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit transaction")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: Text(
                      transaction.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        categoryTypeMiscAmountFormatters[transaction
                            .category
                            .type]!(transaction.getAmount()),
                      ),
                      Text(
                        transaction.realTransaction.date
                            .toString()
                            .split(' ')
                            .first,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder(
            future: () async {
              var categories = await widget.backendController.getCategories();
              var sortedCategories = categories.toList();
              sortedCategories.sort((a, b) => a.name.compareTo(b.name));
              return sortedCategories;
            }(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<Iterable<Category>> snapshot,
                ) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        ...(snapshot.data!
                            .map(
                              (e) => RadioListTile<int?>(
                                visualDensity: VisualDensity.compact,
                                value: e.id,
                                groupValue: transaction.category.id,
                                title: Text(e.name),
                                subtitle: Text(
                                  e.type
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                ),
                                secondary: CircleAvatar(
                                  child: Icon(
                                    IconData(
                                      e.icon,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                  ),
                                ),
                                onChanged: (int? value) {
                                  setState(() {
                                    transaction.category = snapshot.data!
                                        .firstWhere(
                                          (element) => element.id == value,
                                        );
                                  });
                                },
                              ),
                            )
                            .toList()),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Text(
                    JsonEncoder.withIndent(
                      '  ',
                    ).convert(transaction.realTransaction.toMap()),
                    style: TextStyle(fontFamily: "monospace", fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await widget.backendController.updateSurfacedTransaction(transaction);
          if (context.mounted) {
            Navigator.pop(context, transaction);
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
