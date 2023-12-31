import 'package:flutter/material.dart';
import 'package:pfm/backend/types.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final SurfacedTransaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    Image categoryImage = Image.network(
      transaction.realTransaction.categoryIconUrl,
      color: Theme.of(context).colorScheme.background,
      colorBlendMode: BlendMode.softLight,
    );

    return ListTile(
      leading: CircleAvatar(
        child: categoryImage,
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
