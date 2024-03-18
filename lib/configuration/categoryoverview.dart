import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/editors/categoryeditor.dart';

import '../widgets/transaction.dart';

class CategoryOverview extends StatefulWidget {
  final BackendController backendController;
  final Category category;
  final int initialNthPreviousMonth;
  final String Function(num amount) formatAmount;
  final String Function(num amount) formatRemainingAmount;
  final String Function(num amount) formatMiscAmount;

  const CategoryOverview(
      {super.key,
      required this.category,
      required this.backendController,
      required this.initialNthPreviousMonth,
      required this.formatAmount,
      required this.formatRemainingAmount,
      required this.formatMiscAmount});

  @override
  State<CategoryOverview> createState() => _CategoryOverviewState();
}

class _CategoryOverviewState extends State<CategoryOverview> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<SurfacedTransaction> _transactions = [];
  late int _nthPreviousMonth;

  Future loadCategoryData() async {
    _transactions = [];
    setState(() {});
    var (monthStart, monthEnd) = widget.backendController.getMonthBounds(
        widget.backendController.getNthPreviousMonth(_nthPreviousMonth));
    print(monthStart);
    print(monthEnd);
    _transactions = (await widget.backendController
            .getSurfacedTransactionsInCategoryInDateRange(
                widget.category, monthStart, monthEnd))
        .toList();
    for (SurfacedTransaction transaction in _transactions) {
      print(transaction.realTransaction.date);
    }
    _transactions.sort((b, a) {
      return a.realTransaction.date.compareTo(b.realTransaction.date);
    });
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Trigger first-time 'refresh'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });

    _nthPreviousMonth = widget.initialNthPreviousMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {
                      _nthPreviousMonth++;
                      _refreshIndicatorKey.currentState?.show();
                    },
                    icon: const Icon(Icons.chevron_left)),
                Text(DateFormat('MMMM y').format(widget.backendController
                    .getNthPreviousMonth(_nthPreviousMonth))),
                IconButton(
                    onPressed: _nthPreviousMonth > 0
                        ? () {
                            _nthPreviousMonth--;
                            _refreshIndicatorKey.currentState?.show();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right))
              ],
            ),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CategoryPage(
                                backendController: widget.backendController,
                                category: widget.category,
                              )));
                },
                icon: const Icon(Icons.edit))
          ],
        ),
        body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: loadCategoryData,
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _transactions.isNotEmpty
                                ? widget.formatMiscAmount(_transactions
                                    .map((e) => e.getAmount())
                                    .reduce(
                                        (value, element) => value + element))
                                : '',
                            style: Theme.of(context).textTheme.titleMedium,
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: _transactions.length,
                itemBuilder: (BuildContext context, int index) {
                  return TransactionListItem(
                    backendController: widget.backendController,
                    transaction:
                        _transactions[_transactions.length - index - 1],
                    onTransactionChangedCallback: () async {
                      await loadCategoryData();
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(
                    height: 0,
                  );
                },
              ),
            ])));
  }
}
