import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:intl/intl.dart';
import 'package:pfm/editors/transactioneditor.dart';

import '../util.dart';

class TransactionListItem extends StatefulWidget {
  final BackendController backendController;
  final SurfacedTransaction transaction;
  final Function onTransactionChangedCallback;

  const TransactionListItem(
      {super.key,
      required this.backendController,
      required this.transaction,
      required this.onTransactionChangedCallback});

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
          child: Icon(IconData(_transaction.category.icon,
              fontFamily: 'MaterialIcons')),
        ),
        title: Text(
          _transaction.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            Text(DateFormat('MMMMd').format(_transaction.realTransaction.date)),
        trailing: Text(categoryTypeMiscAmountFormatters[_transaction.category.type]!(_transaction.getAmount())),
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
              widget.onTransactionChangedCallback();
            }
          });
        });
  }
}
