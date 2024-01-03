import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:intl/intl.dart';
import 'package:pfm/editors/transactioneditor.dart';

class TransactionListItem extends StatefulWidget {
  final BackendController backendController;
  final SurfacedTransaction transaction;

  const TransactionListItem(
      {super.key, required this.backendController, required this.transaction});

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
  late SurfacedTransaction _transaction;

  @override
  void initState() {
    super.initState();

    _transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: CircleAvatar(
          child: Icon(_transaction.category != null
              ? IconData(_transaction.category!.icon, fontFamily: 'MaterialIcons')
              : Icons.question_mark),
        ),
        title: Text(
          _transaction.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            Text(DateFormat('MMMMd').format(_transaction.realTransaction.date)),
        trailing: Text(_transaction.getAmount().isNegative
            ? '+\$${_transaction.getAmount().abs().toStringAsFixed(2)}'
            : '\$${_transaction.getAmount().abs().toStringAsFixed(2)}'),
        onTap: () async {
          SurfacedTransaction? newTransaction = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TransactionPage(
                        backendController: widget.backendController,
                        transaction: _transaction,
                      )));
          setState(() {
            if (newTransaction != null) {
              _transaction = newTransaction;
            }
          });
        });
  }
}
