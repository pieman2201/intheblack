import 'package:pfm/backend/types.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';

class DbClient {
  late Database db;

  DbClient();

  Future open() async {
    var dbPath = await getDatabasesPath();
    db = await openDatabase(join(dbPath, 'db.db'), version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
      create table $tableTransactions (
      $transactionsColumnId integer primary key autoincrement,
      $transactionsColumnAmount real not null,
      $transactionsColumnDate int not null,
      $transactionsColumnName text not null,
      $transactionsColumnMerchantName text,
      $transactionsColumnPending integer not null,
      $transactionsColumnPendingTransactionId text,
      $transactionsColumnTransactionId text not null,
      $transactionsColumnLogoUrl text,
      $transactionsColumnAuthorizedDate int,
      $transactionsColumnPrimaryCategory text not null,
      $transactionsColumnDetailedCategory text not null,
      $transactionsColumnCategoryIconUrl text not null)''');

      await db.execute('''
      create table $tableSurfacedTransactions (
      $surfacedTransactionsColumnId integer primary key autoincrement,
      $surfacedTransactionsColumnRealTransactionId text not null,
      $surfacedTransactionsColumnPercentOfRealAmount real not null,
      $surfacedTransactionsColumnCategoryId int not null,
      $surfacedTransactionsColumnName text not null)''');

      await db.execute('''
      create table $tableCategories (
      $categoriesColumnId integer primary key autoincrement,
      $categoriesColumnName text not null,
      $categoriesColumnType text not null,
      $categoriesColumnIcon int not null)''');

      await db.execute('''
      create table $tableRules (
      $rulesColumnId integer primary key autoincrement,
      $rulesColumnCategoryId int not null,
      $rulesColumnPriority int not null)''');

      await db.execute('''
      create table $tableRulesegments (
      $rulesegmentsColumnId integer primary key autoincrement,
      $rulesegmentsColumnRuleId int not null,
      $rulesegmentsColumnParam text not null,
      $rulesegmentsColumnRegex text not null)''');

      await db.execute('''
      create table $tableCursors (
      $cursorsColumnId integer primary key autoincrement,
      $cursorsColumnToken text not null,
      $cursorsColumnValue text not null)''');

      await db.execute('''
      create table $tableSettings (
      $settingsColumnId integer primary key autoincrement,
      $settingsColumnType text not null,
      $settingsColumnData text not null)''');
    });
  }

  Future<Transaction> insertTransaction(Transaction transaction) async {
    transaction.id =
        await db.insert(tableTransactions, transaction.toUnidentifiedMap());
    return transaction;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    await db.update(tableTransactions, transaction.toMap(),
        where: '$transactionsColumnTransactionId = ?',
        whereArgs: [transaction.transactionId]);
    return transaction;
  }

  Future<Transaction> deleteTransaction(Transaction transaction) async {
    await db.delete(tableTransactions,
        where: '$transactionsColumnTransactionId = ?',
        whereArgs: [transaction.transactionId]);
    return transaction;
  }

  Future<SurfacedTransaction> insertSurfacedTransaction(
      SurfacedTransaction surfacedTransaction) async {
    surfacedTransaction.id = await db.insert(
        tableSurfacedTransactions, surfacedTransaction.toUnidentifiedMap());
    return surfacedTransaction;
  }

  Future<SurfacedTransaction> updateSurfacedTransaction(
      SurfacedTransaction surfacedTransaction) async {
    await db.update(tableSurfacedTransactions, surfacedTransaction.toMap(),
        where: '$surfacedTransactionsColumnId = ?',
        whereArgs: [surfacedTransaction.id]);
    return surfacedTransaction;
  }

  Future<SurfacedTransaction> deleteSurfacedTransaction(
      SurfacedTransaction surfacedTransaction) async {
    await db.delete(tableSurfacedTransactions,
        where: '$surfacedTransactionsColumnId = ?',
        whereArgs: [surfacedTransaction.id]);
    return surfacedTransaction;
  }

  Future<Transaction?> getTransactionByTransactionId(
      String transactionId) async {
    List<Map<String, dynamic>> maps = await db.query(tableTransactions,
        where: '$transactionsColumnTransactionId = ?',
        whereArgs: [transactionId]);
    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<Category> insertCategory(Category category) async {
    category.id =
        await db.insert(tableCategories, category.toUnidentifiedMap());
    return category;
  }

  Future<Category> updateCategory(Category category) async {
    await db.update(tableCategories, category.toMap(),
        where: '$categoriesColumnId = ?', whereArgs: [category.id]);
    return category;
  }

  Future<Category> deleteCategory(Category category) async {
    await db.delete(tableCategories,
        where: '$categoriesColumnId = ?', whereArgs: [category.id]);
    return category;
  }

  Future<Category?> getCategoryById(int categoryId) async {
    List<Map<String, dynamic>> maps = await db.query(tableCategories,
        where: '$categoriesColumnId = ?', whereArgs: [categoryId]);
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<Iterable<Category>> getCategories() async {
    List<Map<String, dynamic>> maps = await db.query(tableCategories);
    return maps.map((e) => Category.fromMap(e));
  }

  Future<Budget> insertBudget(Budget budget) async {
    budget.id = await db.insert(tableBudgets, budget.toUnidentifiedMap());
    return budget;
  }

  Future<Budget> updateBudget(Budget budget) async {
    await db.update(tableBudgets, budget.toMap(),
        where: '$rulesColumnId = ?', whereArgs: [budget.id]);
    return budget;
  }

  Future<Budget> deleteBudget(Budget budget) async {
    await db.delete(tableBudgets,
        where: '$rulesColumnId = ?', whereArgs: [budget.id]);
    return budget;
  }

  Future<Budget?> getBudgetById(int budgetId) async {
    List<Map<String, dynamic>> maps = await db.rawQuery('''
    select * from $tableBudgets
    left join $tableCategories
    on $tableBudgets.$budgetsColumnCategoryId=$tableCategories.$categoriesColumnId
    where $budgetsColumnId = $budgetId}
    ''');
    if (maps.isNotEmpty) {
      return Budget(
          id: maps.first[budgetsColumnId],
          category: Category.fromMap(maps.first),
          limit: maps.first[budgetsColumnLimit]);
    }
    return null;
  }

  Future<Iterable<Budget>> getBudgets() async {
    List<Map<String, dynamic>> maps = await db.rawQuery('''
    select * from $tableBudgets
    left join $tableCategories
    on $tableBudgets.$budgetsColumnCategoryId=$tableCategories.$categoriesColumnId
    ''');
    return maps.map((e) => Budget(
        id: e[budgetsColumnId],
        category: Category.fromMap(e),
        limit: e[budgetsColumnLimit]));
  }

  Future<Rule> insertRule(Rule rule) async {
    rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
    return rule;
  }

  Future<Rule> updateRule(Rule rule) async {
    await db.update(tableRules, rule.toMap(),
        where: '$rulesColumnId = ?', whereArgs: [rule.id]);
    return rule;
  }

  Future<Rule> deleteRule(Rule rule) async {
    await db
        .delete(tableRules, where: '$rulesColumnId = ?', whereArgs: [rule.id]);
    return rule;
  }

  Future<Rule?> getRuleById(int ruleId) async {
    List<Map<String, dynamic>> maps = await db.rawQuery('''
    select * from $tableRules
    left join $tableCategories
    on $tableRules.$rulesColumnCategoryId=$tableCategories.$categoriesColumnId
    where $rulesColumnId = $ruleId}
    ''');
    if (maps.isNotEmpty) {
      return Rule(
          id: maps.first[rulesColumnId],
          category: Category.fromMap(maps.first),
          priority: maps.first[rulesColumnPriority]);
    }
    return null;
  }

  Future<Iterable<Rule>> getRules() async {
    List<Map<String, dynamic>> maps = await db.rawQuery('''
    select * from $tableRules
    left join $tableCategories
    on $tableRules.$rulesColumnCategoryId=$tableCategories.$categoriesColumnId
    ''');
    return maps.map((e) => Rule(
        id: e[rulesColumnId],
        category: Category.fromMap(e),
        priority: e[rulesColumnPriority]));
  }

  Future<Rulesegment> insertRulesegment(Rulesegment rulesegment) async {
    rulesegment.id =
        await db.insert(tableRulesegments, rulesegment.toUnidentifiedMap());
    return rulesegment;
  }

  Future<Rulesegment> updateRulesegment(Rulesegment rulesegment) async {
    await db.update(tableRulesegments, rulesegment.toMap(),
        where: '$rulesegmentsColumnId = ?', whereArgs: [rulesegment.id]);
    return rulesegment;
  }

  Future<Rulesegment> deleteRulesegment(Rulesegment rulesegment) async {
    await db.delete(tableRulesegments,
        where: '$rulesegmentsColumnId = ?', whereArgs: [rulesegment.id]);
    return rulesegment;
  }

  Future<Iterable<Rulesegment>> getRulesegmentsForRule(Rule rule) async {
    var maps = await db.query(tableRulesegments,
        where: '$rulesegmentsColumnRuleId = ?', whereArgs: [rule.id]);
    return maps.map((Map<String, dynamic> e) => Rulesegment(
        id: e[rulesegmentsColumnId],
        rule: rule,
        param: e[rulesegmentsColumnParam],
        regex: RegExp(e[rulesegmentsColumnRegex])));
  }

  Future<Iterable<SurfacedTransaction>> getSurfacedTransactionsForTransaction(
      Transaction transaction) async {
    var maps = await db.query(tableSurfacedTransactions,
        where: '$surfacedTransactionsColumnRealTransactionId = ?',
        whereArgs: [transaction.transactionId]);
    List<SurfacedTransaction> surfacedTransactions = [];
    for (Map<String, dynamic> e in maps) {
      surfacedTransactions.add(SurfacedTransaction(
          id: e[surfacedTransactionsColumnId],
          realTransaction: transaction,
          category:
              (await getCategoryById(e[surfacedTransactionsColumnCategoryId]))!,
          percentOfRealAmount: e[surfacedTransactionsColumnPercentOfRealAmount],
          name: e[surfacedTransactionsColumnName]));
    }
    return surfacedTransactions;
  }

  Future<Iterable<SurfacedTransaction>> getSurfacedTransactionsInDateRange(
      DateTime startDate, DateTime endDate) async {
    num startInt = Transaction.dateToNum(startDate);
    num endInt = Transaction.dateToNum(endDate);

    List<Map<String, dynamic>> maps = await db.rawQuery('''
    select * from $tableSurfacedTransactions
    left join $tableCategories
    on $tableSurfacedTransactions.$surfacedTransactionsColumnCategoryId=$tableCategories.$categoriesColumnId
    inner join $tableTransactions
    on $tableSurfacedTransactions.$surfacedTransactionsColumnRealTransactionId=$tableTransactions.$transactionsColumnTransactionId
    where $transactionsColumnDate >= $startInt and $transactionsColumnDate <= $endInt
    ''');

    Iterable<SurfacedTransaction> surfacedTransactions = maps.map(
        (Map<String, dynamic> map) => SurfacedTransaction(
            id: map[surfacedTransactionsColumnId],
            realTransaction: Transaction.fromMap(map),
            category: Category.fromMap(map),
            percentOfRealAmount:
                map[surfacedTransactionsColumnPercentOfRealAmount],
            name: map[surfacedTransactionsColumnName]));
    return surfacedTransactions;
  }

  Future<Iterable<SurfacedTransaction>>
      getSurfacedTransactionsInCategoryInDateRange(
          Category category, DateTime startDate, DateTime endDate) async {
    num startInt = Transaction.dateToNum(startDate);
    num endInt = Transaction.dateToNum(endDate);

    List<Map<String, dynamic>> matchingSurfacedTransactionMaps =
        await db.rawQuery('''
    select * from $tableSurfacedTransactions
    left join $tableCategories
    on $tableSurfacedTransactions.$surfacedTransactionsColumnCategoryId=$tableCategories.$categoriesColumnId
    inner join $tableTransactions
    on $tableSurfacedTransactions.$surfacedTransactionsColumnRealTransactionId=$tableTransactions.$transactionsColumnTransactionId
    where $surfacedTransactionsColumnCategoryId = ${category.id} and $transactionsColumnDate >= $startInt and $transactionsColumnDate <= $endInt
    ''');
    return matchingSurfacedTransactionMaps.map((map) => SurfacedTransaction(
        id: map[surfacedTransactionsColumnId],
        realTransaction: Transaction.fromMap(map),
        category: Category.fromMap(map),
        percentOfRealAmount: map[surfacedTransactionsColumnPercentOfRealAmount],
        name: map[surfacedTransactionsColumnName]));
  }

  Future<String> updateCursorValue(
      String accessToken, String cursorValue) async {
    List<Map<String, dynamic>> matchingMaps = await db.query(tableCursors,
        where: '$cursorsColumnToken = ?', whereArgs: [accessToken]);
    Map<String, dynamic> currentCursorMap;
    if (matchingMaps.isEmpty) {
      currentCursorMap = <String, dynamic>{};
      currentCursorMap[cursorsColumnToken] = accessToken;
      currentCursorMap[cursorsColumnValue] = cursorValue;
      await db.insert(tableCursors, currentCursorMap);
    } else {
      Map<String, dynamic> currentCursorMap =
          Map<String, dynamic>.from(matchingMaps.first);
      currentCursorMap[cursorsColumnValue] = cursorValue;
      await db.update(tableCursors, currentCursorMap,
          where: '$cursorsColumnId = ?',
          whereArgs: [currentCursorMap[cursorsColumnId]]);
    }

    return cursorValue;
  }

  Future<Map<String, String>> retrieveCursorValues() async {
    List<Map<String, dynamic>> currentCursorMaps = await db.query(tableCursors);
    Map<String, String> storedCursors = <String, String>{};
    for (Map<String, dynamic> currentCursorMap in currentCursorMaps) {
      storedCursors[currentCursorMap[cursorsColumnToken]] =
          currentCursorMap[cursorsColumnValue];
    }
    return storedCursors;
  }

  Future clearCursorValues() async {
    await db.rawDelete('delete from $tableCursors');
  }

  Future<Map<SettingsType, String>> retrieveSettings() async {
    List<Map<String, dynamic>> settingsMaps = await db.query(tableSettings);
    Map<SettingsType, String> settingsTypesToValuesMap =
        <SettingsType, String>{};
    for (Map<String, dynamic> settingsMap in settingsMaps) {
      settingsTypesToValuesMap[SettingsType.values.firstWhere(
              (e) => e.toString() == settingsMap[settingsColumnType])] =
          settingsMap[settingsColumnData];
    }
    return settingsTypesToValuesMap;
  }

  Future<String> updateSetting(SettingsType settingsType, String value) async {
    List<Map<String, dynamic>> matchingMaps = await db.query(tableSettings,
        where: '$settingsColumnType = ?', whereArgs: [settingsType.toString()]);
    if (matchingMaps.isEmpty) {
      var settingsMap = <String, dynamic>{};
      settingsMap[settingsColumnType] = settingsType.toString();
      settingsMap[settingsColumnData] = value;
      await db.insert(tableSettings, settingsMap);
    } else {
      Map<String, dynamic> currentSettingsMap =
          Map<String, dynamic>.from(matchingMaps.first);
      currentSettingsMap[settingsColumnData] = value;
      await db.update(tableCursors, currentSettingsMap,
          where: '$cursorsColumnId = ?',
          whereArgs: [currentSettingsMap[settingsColumnId]]);
    }
    return value;
  }
}
