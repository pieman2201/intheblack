import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';

class TransactionPage extends StatefulWidget {
  final BackendController backendController;
  final SurfacedTransaction transaction;

  const TransactionPage(
      {super.key, required this.backendController, required this.transaction});

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
      appBar: AppBar(
        title: const Text("Edit transaction"),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                Text(
                  transaction.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    Text(transaction.getAmount().isNegative
                        ? '+\$${transaction.getAmount().abs().toStringAsFixed(2)}'
                        : '\$${transaction.getAmount().toStringAsFixed(2)}'),
                    const Spacer(),
                    Text(transaction.realTransaction.date
                        .toString()
                        .split(' ')
                        .first)
                  ],
                ),
                Text(transaction.realTransaction.primaryCategory),
                Text(transaction.realTransaction.detailedCategory),
                const SizedBox(
                  height: 8,
                ),
                const Divider(),
                const SizedBox(
                  height: 8,
                ),
                Text(transaction.realTransaction.name),
                Text(transaction.realTransaction.merchantName.toString()),
              ],
            ),
          )),
          FutureBuilder(
              future: widget.backendController.getCategories(),
              builder: (BuildContext context,
                  AsyncSnapshot<Iterable<Category>> snapshot) {
                if (snapshot.hasData) {
                  return Column(children: [
                    ...(snapshot.data!
                        .map((e) => RadioListTile<int?>(
                              value: e.id,
                              groupValue: transaction.category.id,
                              title: Text(e.name),
                              subtitle: Text(e.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase()),
                              secondary: CircleAvatar(
                                child: Icon(IconData(transaction.category.icon, fontFamily: 'MaterialIcons')),
                              ),
                              onChanged: (int? value) {
                                setState(() {
                                  transaction.category = snapshot.data!
                                      .firstWhere((element) => e.id == value);
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
