import 'package:flutter/material.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/widgets/spendchart.dart';

import '../backend/types.dart';
import '../widgets/transaction.dart';

class SpendingPage extends StatefulWidget {
  final BackendController backendController;

  const SpendingPage({super.key, required this.backendController});

  @override
  State<SpendingPage> createState() => _SpendingPageState();
}

class _SpendingPageState extends State<SpendingPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<SurfacedTransaction> _transactions = [];
  num? _monthSum;
  DateTime? _beginningOfCurrentMonth;
  DateTime? _endOfCurrentMonth;

  Future _fetchAndShowTransactions() async {
    try {
      await widget.backendController.syncTransactionsAndStore();
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not sync transactions")));
      }
    }

    DateTime currentDateTime = DateTime.now();
    int currentYear = currentDateTime.year;
    int currentMonth = currentDateTime.month;
    _beginningOfCurrentMonth = DateTime(currentYear, currentMonth);
    int nextMonth = currentMonth + 1;
    int nextYear = currentYear;
    if (nextMonth >= 13) {
      nextMonth -= 12;
      nextYear++;
    }
    DateTime beginningOfNextMonth = DateTime(nextYear, nextMonth);
    _endOfCurrentMonth = beginningOfNextMonth.subtract(const Duration(days: 1));
    var retrievedTransactions = await widget.backendController
        .getSurfacedTransactionsInDateRange(
            _beginningOfCurrentMonth!, beginningOfNextMonth);

    setState(() {
      _transactions = retrievedTransactions;
      if (retrievedTransactions.isNotEmpty) {
        _monthSum = retrievedTransactions
            .map((e) => e.getAmount())
            .reduce((value, element) => value + element);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Trigger first-time 'refresh'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _fetchAndShowTransactions,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: _monthSum == null
                ? const SizedBox.shrink()
                : Text('\$${_monthSum!.toStringAsFixed(2)}'),
          ),
          SliverToBoxAdapter(
              child: _beginningOfCurrentMonth == null
                  ? const SizedBox.shrink()
                  : SpendChart(
                      startDate: _beginningOfCurrentMonth!,
                      endDate: _endOfCurrentMonth!,
                      transactions: _transactions)),
          SliverList.separated(
            itemCount: _transactions.length,
            itemBuilder: (BuildContext context, int index) {
              return TransactionListItem(
                  transaction: _transactions[_transactions.length - index - 1]);
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider();
            },
          ),
        ],
      ),
    );
  }
}
