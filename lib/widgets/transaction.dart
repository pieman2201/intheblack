import 'package:flutter/material.dart';
import 'package:pfm/backend/types.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final SurfacedTransaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(transaction.budget != null
            ? IconData(transaction.budget!.icon, fontFamily: 'MaterialIcons')
            : Icons.question_mark),
      ),
      title: Text(
        transaction.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          Text(DateFormat('MMMMd').format(transaction.realTransaction.date)),
      trailing: Text(transaction.getAmount().isNegative
          ? '+\$${transaction.getAmount().abs().toStringAsFixed(2)}'
          : '\$${transaction.getAmount().abs().toStringAsFixed(2)}'),
    );
  }
}
