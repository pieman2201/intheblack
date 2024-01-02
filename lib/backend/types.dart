const String tableTransactions = 'transactions';
const String transactionsColumnId = 'transactions_id';
const String transactionsColumnAmount = 'transactions_amount';
const String transactionsColumnDate = 'transactions_date';
const String transactionsColumnName = 'transactions_name';
const String transactionsColumnMerchantName = 'transactions_merchant_name';
const String transactionsColumnPending = 'transactions_pending';
const String transactionsColumnPendingTransactionId =
    'transactions_pending_transaction_id';
const String transactionsColumnTransactionId = 'transactions_transaction_id';
const String transactionsColumnLogoUrl = 'transactions_logo_url';
const String transactionsColumnAuthorizedDate = 'transactions_authorized_date';
const String transactionsColumnPrimaryCategory =
    'transactions_primary_category';
const String transactionsColumnDetailedCategory =
    'transactions_detailed_category';
const String transactionsColumnCategoryIconUrl =
    'transactions_category_icon_url';

class Transaction {
  int id;
  num amount;
  DateTime date;
  String name;
  String? merchantName;
  bool pending;
  String? pendingTransactionId;
  String transactionId;
  String? logoUrl;
  DateTime? authorizedDate;
  String primaryCategory;
  String detailedCategory;
  String categoryIconUrl;

  static num dateToNum(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  static DateTime numToDate(num n) {
    int year = n ~/ 10000;
    int month = (n - (year * 10000)) ~/ 100;
    int day = (n % 100) as int;
    return DateTime(year, month, day);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      transactionsColumnId: id,
      transactionsColumnAmount: amount,
      transactionsColumnDate: dateToNum(date),
      transactionsColumnName: name,
      transactionsColumnMerchantName: merchantName,
      transactionsColumnPending: pending ? 1 : 0,
      transactionsColumnPendingTransactionId: pendingTransactionId,
      transactionsColumnTransactionId: transactionId,
      transactionsColumnLogoUrl: logoUrl,
      transactionsColumnAuthorizedDate:
          authorizedDate == null ? null : dateToNum(authorizedDate!),
      transactionsColumnPrimaryCategory: primaryCategory,
      transactionsColumnDetailedCategory: detailedCategory,
      transactionsColumnCategoryIconUrl: categoryIconUrl,
    };
    return map;
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(transactionsColumnId);
    return map;
  }

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.name,
    required this.merchantName,
    required this.pending,
    required this.pendingTransactionId,
    required this.transactionId,
    required this.logoUrl,
    required this.authorizedDate,
    required this.primaryCategory,
    required this.detailedCategory,
    required this.categoryIconUrl,
  });

  Transaction.fromMap(Map<String, dynamic> map)
      : id = map[transactionsColumnId]!,
        amount = map[transactionsColumnAmount]!,
        date = numToDate(map[transactionsColumnDate]!),
        name = map[transactionsColumnName]!,
        merchantName = map[transactionsColumnMerchantName],
        pending = map[transactionsColumnPending]! == 1,
        pendingTransactionId = map[transactionsColumnPendingTransactionId],
        transactionId = map[transactionsColumnTransactionId]!,
        logoUrl = map[transactionsColumnLogoUrl],
        authorizedDate = map[transactionsColumnAuthorizedDate] == null
            ? null
            : numToDate(map[transactionsColumnAuthorizedDate]!),
        primaryCategory = map[transactionsColumnPrimaryCategory]!,
        detailedCategory = map[transactionsColumnDetailedCategory]!,
        categoryIconUrl = map[transactionsColumnCategoryIconUrl]!;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'amount': num amount,
        'date': String date,
        'name': String name,
        'merchant_name': String? merchantName,
        'pending': bool pending,
        'pending_transaction_id': String? pendingTransactionId,
        'transaction_id': String transactionId,
        'logo_url': String? logoUrl,
        'authorized_date': String? authorizedDate,
        'personal_finance_category': {
          'primary': String primaryCategory,
          'detailed': String detailedCategory,
        },
        'personal_finance_category_icon_url': String categoryIconUrl,
      } =>
        () {
          Transaction t = Transaction(
            id: -1,
            amount: amount,
            date: DateTime.parse(date),
            name: name,
            pending: pending,
            pendingTransactionId: pendingTransactionId,
            transactionId: transactionId,
            authorizedDate:
                authorizedDate != null ? DateTime.parse(authorizedDate) : null,
            primaryCategory: primaryCategory,
            detailedCategory: detailedCategory,
            categoryIconUrl: categoryIconUrl,
            logoUrl: logoUrl,
            merchantName: merchantName,
          );
          if (logoUrl == null || merchantName == null) {
            // Attempt to source from counterparty if missing in main body
            for (dynamic counterparty in json['counterparties']) {
              var counterpartyMap = counterparty as Map<String, dynamic>;
              print(counterpartyMap);
              if (counterpartyMap['logo_url'] != null &&
                  counterpartyMap['name'] != null &&
                  counterpartyMap['type'] == 'merchant') {
                t.logoUrl = counterpartyMap['logo_url']!;
                t.merchantName = counterpartyMap['name']!;
              }
            }
          }
          return t;
        }(),
      _ => () {
          throw const FormatException("Failed to load Transaction");
        }(),
    };
  }
}

const String tableBudgets = 'budgets';
const String budgetsColumnId = 'budgets_id';
const String budgetsColumnName = 'budgets_name';
const String budgetsColumnType = 'budgets_type';
const String budgetsColumnLimit = 'budgets_limit';
const String budgetsColumnIcon = 'budgets_icon';

enum BudgetType {
  spending,
  living,
  income,
}

class Budget {
  int id;
  String name;
  BudgetType type;
  num limit;
  int icon;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      budgetsColumnId: id,
      budgetsColumnName: name,
      budgetsColumnType: type.toString(),
      budgetsColumnLimit: limit,
      budgetsColumnIcon: icon,
    };
    return map;
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(budgetsColumnId);
    return map;
  }

  Budget({
    required this.id,
    required this.name,
    required this.type,
    required this.limit,
    required this.icon,
  });

  Budget.fromMap(Map<String, dynamic> map)
      : id = map[budgetsColumnId],
        name = map[budgetsColumnName],
        type = BudgetType.values
            .firstWhere((e) => e.toString() == map[budgetsColumnType]),
        limit = map[budgetsColumnLimit],
        icon = map[budgetsColumnIcon];
}

const String tableSurfacedTransactions = 'surfaced_transactions';
const String surfacedTransactionsColumnId = 'surfaced_transactions_id';
const String surfacedTransactionsColumnRealTransactionId =
    'surfaced_transactions_real_transaction_id';
const String surfacedTransactionsColumnPercentOfRealAmount =
    'surfaced_transactions_percent_of_real_amount';
const String surfacedTransactionsColumnName = 'surfaced_transactions_name';
const String surfacedTransactionsColumnBudgetId =
    'surfaced_transactions_budget_id';

class SurfacedTransaction {
  int id;
  Transaction realTransaction;
  Budget? budget;
  num percentOfRealAmount;
  String name;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      surfacedTransactionsColumnId: id,
      surfacedTransactionsColumnRealTransactionId:
          realTransaction.transactionId,
      surfacedTransactionsColumnBudgetId: budget?.id,
      surfacedTransactionsColumnPercentOfRealAmount: percentOfRealAmount,
      surfacedTransactionsColumnName: name,
    };
    return map;
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(surfacedTransactionsColumnId);
    return map;
  }

  SurfacedTransaction({
    required this.id,
    required this.realTransaction,
    required this.budget,
    required this.percentOfRealAmount,
    required this.name,
  });

  num getAmount() {
    return percentOfRealAmount * realTransaction.amount / 100;
  }
}

const String tableCursors = 'cursors';
const String cursorsColumnId = 'cursors_id';
const String cursorsColumnToken = 'cursors_token';
const String cursorsColumnValue = 'cursors_value';

class TransactionsDiff {
  Iterable<Transaction> added;
  Iterable<Transaction> modified;
  Iterable<Transaction> removed;
  String nextCursor;

  TransactionsDiff({
    required this.added,
    required this.modified,
    required this.removed,
    required this.nextCursor,
  });

  factory TransactionsDiff.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'added': List<dynamic> added,
        'modified': List<dynamic> modified,
        'removed': List<dynamic> removed,
        'next_cursor': String nextCursor,
      } =>
        () {
          return TransactionsDiff(
            added: added
                .map((e) => Transaction.fromJson(e as Map<String, dynamic>)),
            modified: modified
                .map((e) => Transaction.fromJson(e as Map<String, dynamic>)),
            removed: removed
                .map((e) => Transaction.fromJson(e as Map<String, dynamic>)),
            nextCursor: nextCursor,
          );
        }(),
      _ => throw const FormatException("Failed to load TransactionsDiff"),
    };
  }
}

const String tableSettings = 'settings';
const String settingsColumnId = 'settings_id';
const String settingsColumnType = 'settings_type';
const String settingsColumnData = 'settings_data';

enum SettingsType {
  apiClientId,
  apiSecret,
}

const String tableRules = 'rules';
const String rulesColumnId = 'rules_id';
const String rulesColumnBudgetId = 'rules_budget_id';
const String rulesColumnMatcher = 'rules_matcher';
const String rulesColumnPriority = 'rules_priority';

class Rule {
  int id;
  Budget? budget;
  String matcher;
  int priority;

  Rule({
    required this.id,
    required this.budget,
    required this.matcher,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      rulesColumnId: id,
      rulesColumnBudgetId: budget?.id,
      rulesColumnMatcher: matcher,
      rulesColumnPriority: priority,
    };
    return map;
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(rulesColumnId);
    return map;
  }
}
