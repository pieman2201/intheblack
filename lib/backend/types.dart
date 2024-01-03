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

const String tableCategories = 'categories';
const String categoriesColumnId = 'categories_id';
const String categoriesColumnName = 'categories_name';
const String categoriesColumnType = 'categories_type';
const String categoriesColumnIcon = 'categories_icon';

enum CategoryType {
  spending,
  living,
  income,
  ignored,
}

class Category {
  int id;
  String name;
  CategoryType type;
  int icon;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      categoriesColumnId: id,
      categoriesColumnName: name,
      categoriesColumnType: type.toString(),
      categoriesColumnIcon: icon,
    };
    return map;
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(categoriesColumnId);
    return map;
  }

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
  });

  Category.fromMap(Map<String, dynamic> map)
      : id = map[categoriesColumnId],
        name = map[categoriesColumnName],
        type = CategoryType.values
            .firstWhere((e) => e.toString() == map[categoriesColumnType]),
        icon = map[categoriesColumnIcon];
}

const String tableRules = 'rules';
const String rulesColumnId = 'rules_id';
const String rulesColumnCategoryId = 'rules_category_id';
const String rulesColumnPriority = 'rules_priority';

class Rule {
  int id;
  Category category;
  int priority;

  Rule({
    required this.id,
    required this.category,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      rulesColumnId: id,
      rulesColumnCategoryId: category.id,
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

const String tableRulesegments = 'rulesegments';
const String rulesegmentsColumnId = 'rulesegments_id';
const String rulesegmentsColumnRuleId = 'rulesegments_rule_id';
const String rulesegmentsColumnParam = 'rulesegments_param';
const String rulesegmentsColumnRegex = 'rulesegments_regex';

class Rulesegment {
  int id;
  Rule rule;
  String param;
  RegExp regex;

  Rulesegment({
    required this.id,
    required this.rule,
    required this.param,
    required this.regex,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      rulesegmentsColumnId: id,
      rulesegmentsColumnRuleId: rule.id,
      rulesegmentsColumnParam: param,
      rulesegmentsColumnRegex: regex.pattern,
    };
    return map;
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(rulesegmentsColumnId);
    return map;
  }
}

class RuleWithSegments {
  Rule rule;
  Iterable<Rulesegment> segments;

  RuleWithSegments({required this.rule, required this.segments});
}

const String tableBudgets = 'budgets';
const String budgetsColumnId = 'budgets_id';
const String budgetsColumnCategoryId = 'budgets_category_id';
const String budgetsColumnLimit = 'budgets_limit';

class Budget {
  int id;
  Category category;
  num limit;

  Budget({required this.id, required this.category, required this.limit});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      budgetsColumnId: id,
      budgetsColumnCategoryId: category.id,
      budgetsColumnLimit: limit,
    };
  }

  Map<String, dynamic> toUnidentifiedMap() {
    var map = toMap();
    map.remove(budgetsColumnId);
    return map;
  }
}

const String tableSurfacedTransactions = 'surfaced_transactions';
const String surfacedTransactionsColumnId = 'surfaced_transactions_id';
const String surfacedTransactionsColumnRealTransactionId =
    'surfaced_transactions_real_transaction_id';
const String surfacedTransactionsColumnPercentOfRealAmount =
    'surfaced_transactions_percent_of_real_amount';
const String surfacedTransactionsColumnName = 'surfaced_transactions_name';
const String surfacedTransactionsColumnCategoryId =
    'surfaced_transactions_category_id';

class SurfacedTransaction {
  int id;
  Transaction realTransaction;
  Category category;
  num percentOfRealAmount;
  String name;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      surfacedTransactionsColumnId: id,
      surfacedTransactionsColumnRealTransactionId:
          realTransaction.transactionId,
      surfacedTransactionsColumnCategoryId: category.id,
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
    required this.category,
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
