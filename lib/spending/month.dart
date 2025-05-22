import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/util.dart';
import 'package:pfm/widgets/spendcard/spendcard.dart';
import 'package:pfm/widgets/spendchart.dart';

import '../backend/types.dart';
import '../widgets/transaction.dart';

class MonthSpendingPage extends StatefulWidget {
  final BackendController backendController;
  final int nthPreviousMonthToShow;

  const MonthSpendingPage(
      {super.key,
      required this.backendController,
      required this.nthPreviousMonthToShow});

  @override
  State<MonthSpendingPage> createState() => _MonthSpendingPageState();
}

class _MonthSpendingPageState extends State<MonthSpendingPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<SurfacedTransaction> _transactions = [];
  Iterable<Budget> _budgets = [];
  DateTime? _beginningOfCurrentMonth;
  DateTime? _endOfCurrentMonth;

  Future _fetchAndShowTransactions() async {
    try {
      await widget.backendController.syncTransactionsAndStore();
    } on Exception catch (e, s) {
      printDebug(e);
      printDebug(s);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not sync transactions")));
      }
    }

    await _retrieveStoredData();
  }

  Future _retrieveStoredData() async {
    _transactions = [];
    _beginningOfCurrentMonth = null;
    _budgets = [];
    if (!mounted) return;
    setState(() {});

    var (monthStart, monthEnd) = widget.backendController.getMonthBounds(widget
        .backendController
        .getNthPreviousMonth(widget.nthPreviousMonthToShow));
    _beginningOfCurrentMonth = monthStart;
    _endOfCurrentMonth = monthEnd;
    _budgets = await widget.backendController.getBudgets();
    _transactions = await widget.backendController
        .getSurfacedTransactionsInDateRange(
            _beginningOfCurrentMonth!, _endOfCurrentMonth!);


    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    // Trigger first-time 'refresh'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });

    printDebug("init month state");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _fetchAndShowTransactions,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(DateFormat('MMMM y').format(widget.backendController
                    .getNthPreviousMonth(widget.nthPreviousMonthToShow)))),
          ),
          SliverToBoxAdapter(
              child: _beginningOfCurrentMonth == null
                  ? const SizedBox.shrink()
                  : SpendChart(
                      startDate: _beginningOfCurrentMonth!,
                      endDate: _endOfCurrentMonth!,
                      transactions: _transactions)),
          SliverToBoxAdapter(
              child: _transactions.isEmpty
                  ? const SizedBox.shrink()
                  : SpendCard(
                      budgets: _budgets,
                      transactions: _transactions,
                      backendController: widget.backendController,
                      nthPreviousMonth: widget.nthPreviousMonthToShow,
                    )),
          SliverList.separated(
            itemCount: _transactions.length,
            itemBuilder: (BuildContext context, int index) {
              return TransactionListItem(
                backendController: widget.backendController,
                transaction: _transactions[_transactions.length - index - 1],
                onTransactionChangedCallback: () async {
                  await _retrieveStoredData();
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(
                height: 0,
              );
            },
          ),
        ],
      ),
    );
  }
}
