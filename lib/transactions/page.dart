import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pfm/backend/controller.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/util.dart';
import 'package:pfm/widgets/transaction.dart';

class TransactionsPage extends StatefulWidget {
  final BackendController backendController;

  const TransactionsPage({super.key, required this.backendController});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SurfacedTransaction> _transactions = [];
  bool _isLoading = true;

  // Current month bounds
  late DateTime _currentMonthStart;
  late DateTime _currentMonthEnd;

  @override
  void initState() {
    super.initState();
    _initializeMonthBounds();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    // Load transactions from the past year
    final DateTime now = DateTime.now();
    final DateTime oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    final transactions = await widget.backendController
        .getSurfacedTransactionsInDateRange(oneYearAgo, now);

    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  List<SurfacedTransaction> _getFilteredTransactions() {
    if (_searchQuery.isEmpty) {
      return _transactions;
    }

    final query = _searchQuery.toLowerCase();

    return _transactions.where((transaction) {
      // Convert the entire transaction to a JSON string for full-text search
      final transactionJson = _convertTransactionToSearchableJson(transaction);
      return transactionJson.contains(query);
    }).toList();
  }

  String _convertTransactionToSearchableJson(SurfacedTransaction transaction) {
    // Create a map with all relevant transaction data
    final Map<String, dynamic> searchableData = {
      // SurfacedTransaction properties
      'name': transaction.name,
      'percent_of_real_amount': transaction.percentOfRealAmount,
      'category_name': transaction.category.name,
      'category_type': transaction.category.type.toString(),
      'amount': transaction.getAmount(),

      // Include the entire real transaction
      'transaction_id': transaction.realTransaction.transactionId,
      'date': transaction.realTransaction.date.toString(),
      'merchant_name': transaction.realTransaction.merchantName,
      'original_description': transaction.realTransaction.originalDescription,
      'real_amount': transaction.realTransaction.amount,
      'pending': transaction.realTransaction.pending,
      'primary_category': transaction.realTransaction.primaryCategory,
      'detailed_category': transaction.realTransaction.detailedCategory,
      'authorized_date': transaction.realTransaction.authorizedDate?.toString(),
      'pending_transaction_id':
          transaction.realTransaction.pendingTransactionId,
    };

    // Convert to JSON string and make lowercase for case-insensitive search
    return jsonEncode(searchableData).toLowerCase();
  }

  void _initializeMonthBounds() {
    final currentMonth = widget.backendController.getNthPreviousMonth(0);
    final (start, end) = widget.backendController.getMonthBounds(currentMonth);
    _currentMonthStart = start;
    _currentMonthEnd = end;
  }

  // Calculate summary statistics for the filtered transactions
  Map<String, dynamic> _calculateStatistics(
    List<SurfacedTransaction> transactions,
  ) {
    // Initialize counters
    num totalSum = 0;
    num currentMonthSum = 0;
    int totalCount = 0;
    int currentMonthCount = 0;

    for (final transaction in transactions) {
      // Get transaction amount
      final amount = transaction.getAmount();

      // Add to total sum and count
      totalSum += amount;
      totalCount++;

      // Check if transaction is in current month
      final date = transaction.realTransaction.date;
      if (date.isAfter(_currentMonthStart.subtract(const Duration(days: 1))) &&
          date.isBefore(_currentMonthEnd.add(const Duration(days: 1)))) {
        currentMonthSum += amount;
        currentMonthCount++;
      }
    }

    // Calculate averages (avoid division by zero)
    final totalAvg = totalCount > 0 ? totalSum / totalCount : 0;
    final monthAvg = currentMonthCount > 0
        ? currentMonthSum / currentMonthCount
        : 0;

    return {
      'totalSum': totalSum,
      'totalAvg': totalAvg,
      'monthSum': currentMonthSum,
      'monthAvg': monthAvg,
      'totalCount': totalCount,
      'monthCount': currentMonthCount,
    };
  }

  // Get the appropriate formatter based on the category type
  String Function(num) _getFormatter(List<SurfacedTransaction> transactions) {
    if (transactions.isEmpty) {
      return categoryTypeMiscAmountFormatters[CategoryType.spending]!;
    }

    // Use the category type of the first transaction to determine formatter
    return categoryTypeMiscAmountFormatters[transactions.first.category.type]!;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();
    final statistics = _calculateStatistics(filteredTransactions);
    final formatter = _getFormatter(filteredTransactions);

    return SafeArea(
      bottom: false,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Summary statistics card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                spacing: 4.0,
                children: [
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'MMM y',
                                    ).format(_currentMonthStart),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                Text('${statistics['monthCount']} items'),
                              ],
                            ),
                            Row(
                              textBaseline: TextBaseline.alphabetic,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Sum",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                Text(formatter(statistics['monthSum'])),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Average",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                Text(formatter(statistics['monthAvg'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    filteredTransactions.isNotEmpty
                                        ? 'From ${DateFormat('MMM yy').format(filteredTransactions.last.realTransaction.date)}'
                                        : 'All',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                Text('${statistics['totalCount']} items'),
                              ],
                            ),
                            Row(
                              textBaseline: TextBaseline.alphabetic,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Sum",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                Text(formatter(statistics['totalSum'])),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Average",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                Text(formatter(statistics['totalAvg'])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No transactions found'
                            : 'No matching transactions',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          return TransactionListItem(
                            key: UniqueKey(),
                            backendController: widget.backendController,
                            transaction: filteredTransactions[index],
                            onTransactionChangedCallback: () {
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
