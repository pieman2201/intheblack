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
      $transactionsColumnCategoryIconUrl text not null,
      $transactionsColumnCategory text not null,
      $transactionsColumnOriginalDescription text)''');

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
      $categoriesColumnIcon int not null,
      $categoriesColumnBudgetId integer nullable)''');

      await db.execute('''
      create table $tableRules (
      $rulesColumnId integer primary key autoincrement,
      $rulesColumnCategoryId int not null,
      $rulesColumnPriority int not null)''');

      await db.execute('''
      create table $tableBudgets (
      $budgetsColumnId integer primary key autoincrement,
      $budgetsColumnName text not null,
      $budgetsColumnLimit real not null)''');

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

      // Create default categories and rules
      Category category;
      Rule rule;

      // Default 'uncategorized spending' catch-all
      category = Category(
          id: 0, name: 'Unknown', type: CategoryType.spending, icon: 58123);
      category.id = await db.insert(tableCategories, category.toMap());
      await db.insert(
        tableRules,
        Rule(id: 0, category: category, priority: 0).toMap(),
      );

      // Venmo categorize as unknown spending
      rule = Rule(id: -1, category: category, priority: 11);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
            id: -1,
            rule: rule,
            param: 'category',
            regex: RegExp('Venmo'),
          ).toUnidentifiedMap());

      // Transfers ignore
      category = Category(
          id: -1, name: 'Transfers', type: CategoryType.ignored, icon: 0xe182);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('ACCOUNT_TRANSFER'))
              .toUnidentifiedMap());

      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('INVESTMENT_AND_RETIREMENT'))
              .toUnidentifiedMap());

      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('CASH_ADVANCES'))
              .toUnidentifiedMap());

      // Make sure Venmo bank withdrawals count as transfers
      rule = Rule(id: -1, category: category, priority: 12);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(id: -1, rule: rule, param: 'name', regex: RegExp('Venmo'))
              .toUnidentifiedMap());

      // And same for transfers out of Venmo
      rule = Rule(id: -1, category: category, priority: 12);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
            id: -1,
            rule: rule,
            param: 'category',
            regex: RegExp('Venmo'),
          ).toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(id: -1, rule: rule, param: 'original_description', regex: RegExp('Standard transfer'))
              .toUnidentifiedMap());

      // Invisible category that will not show up on lists in the UI
      category = Category(
          id: -1, name: 'Invisible', type: CategoryType.invisible, icon: 0xe6be);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());

      // Make sure authorization requests (from Future) are counted as invisible
      rule = Rule(id: -1, category: category, priority: 12);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(id: -1, rule: rule, param: 'original_description', regex: RegExp(' - AUTHORIZATION REQUEST'))
              .toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(id: -1, rule: rule, param: 'pending', regex: RegExp('1'))
              .toUnidentifiedMap());

      // And ignore the weird integration request holds
      rule = Rule(id: -1, category: category, priority: 12);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(id: -1, rule: rule, param: 'original_description', regex: RegExp('Release hold ttx_'))
              .toUnidentifiedMap());

      // Salary income
      category = Category(
          id: -1, name: 'Salary', type: CategoryType.income, icon: 0xe6f4);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('INCOME_WAGES'))
              .toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'name',
                  regex: RegExp('^((?!EXPENSE).)*\$'))
              .toUnidentifiedMap());

      // Card payment ignored
      category = Category(
          id: -1,
          name: 'Card payment',
          type: CategoryType.ignored,
          icon: 0xe19f);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('CREDIT_CARD_PAYMENT'))
              .toUnidentifiedMap());

      // Rent living expense
      category = Category(
          id: -1, name: 'Rent', type: CategoryType.living, icon: 0xe089);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 10);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'primary_category',
                  regex: RegExp('TRANSFER_OUT'))
              .toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1, rule: rule, param: 'name', regex: RegExp('ALLY BANK'))
              .toUnidentifiedMap());

      // Electric Utilities living expense
      category = Category(
          id: -1, name: 'Electricity', type: CategoryType.living, icon: 0xf06ed);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('UTILITIES_GAS_AND_ELECTRICITY'))
              .toUnidentifiedMap());

      // Internet Utilities living expense
      category = Category(
          id: -1, name: 'Internet', type: CategoryType.living, icon: 0xe542);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('UTILITIES_INTERNET'))
              .toUnidentifiedMap());

      // Ride-hailing spending
      category = Category(
          id: -1,
          name: 'Ride-hailing',
          type: CategoryType.spending,
          icon: 0xe1d7);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('TAXIS_AND_RIDE_SHARES'))
              .toUnidentifiedMap());

      // Public transit living expense
      category = Category(
        id: -1,
        name: 'Public transit',
        type: CategoryType.living,
        icon: 0xe675,
      );
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('PUBLIC_TRANSIT'))
              .toUnidentifiedMap());

      // OMNY override
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'merchant_name',
              regex: RegExp('OMNY'))
              .toUnidentifiedMap());

      // Shopping spending
      category = Category(
          id: -1, name: 'Shopping', type: CategoryType.spending, icon: 0xf37d);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'primary_category',
                  regex: RegExp('MERCHANDISE'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('PHARMACIES'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'primary_category',
              regex: RegExp('HOME_IMPROVEMENT'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'primary_category',
              regex: RegExp('PERSONAL_CARE'))
              .toUnidentifiedMap());

      // Dining spending
      category = Category(
          id: -1,
          name: 'Dining',
          type: CategoryType.spending,
          icon: 0xf049);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'primary_category',
                  regex: RegExp('FOOD_AND_DRINK'))
              .toUnidentifiedMap());

      // Drinking spending
      category = Category(
          id: -1,
          name: 'Drinks',
          type: CategoryType.spending,
          icon: 0xe6f1);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('BEER_WINE'))
              .toUnidentifiedMap());

      // Cafe spending
      category = Category(
          id: -1,
          name: 'Cafes',
          type: CategoryType.spending,
          icon: 0xf175);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('COFFEE'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'name',
              regex: RegExp('(c|C)(offee|OFFEE)'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'name',
              regex: RegExp('(c|C)(afe|AFE)'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'merchant_name',
              regex: RegExp('(c|C)(afe|AFE)'))
              .toUnidentifiedMap());

      // Groceries living expense
      category = Category(
          id: -1, name: 'Groceries', type: CategoryType.living, icon: 0xf17d);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'detailed_category',
                  regex: RegExp('GROCERIES'))
              .toUnidentifiedMap());

      // Services spending
      category = Category(
          id: -1, name: 'Services', type: CategoryType.spending, icon: 0xe60c);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'primary_category',
              regex: RegExp('GENERAL_SERVICES'))
              .toUnidentifiedMap());

      // Fees ignored
      category = Category(
          id: -1, name: 'Fees', type: CategoryType.ignored, icon: 0xf04e);
      category.id =
          await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
                  id: -1,
                  rule: rule,
                  param: 'primary_category',
                  regex: RegExp('BANK_FEES'))
              .toUnidentifiedMap());

      // Taxes are also fees
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('TAX_PAYMENT'))
              .toUnidentifiedMap());

      // Entertainment spending
      category = Category(id: -1, name: "Entertainment", type: CategoryType.spending, icon: 58964);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 1);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'primary_category',
              regex: RegExp('ENTERTAINMENT'))
              .toUnidentifiedMap());

      // Crunch fitness living
      category = Category(id: -1, name: "Fitness", type: CategoryType.living, icon: 57997);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'primary_category',
              regex: RegExp('ENTERTAINMENT'))
              .toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1, rule: rule, param: 'name', regex: RegExp('CRUNCH'))
              .toUnidentifiedMap());

      // Deposits income
      category = Category(id: -1, name: "Deposits", type: CategoryType.income, icon: 0xf336);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'name',
              regex: RegExp('DEPOSIT'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('INTEREST_EARNED'))
              .toUnidentifiedMap());

      // Withdrawals spending
      category = Category(id: -1, name: "Withdrawals", type: CategoryType.spending, icon: 0xe3f8);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('WITHDRAWAL'))
              .toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'name',
              regex: RegExp('(W|w)ithdraw'))
              .toUnidentifiedMap());

      // Reimbursement income
      category = Category(id: -1, name: "Reimbursement", type: CategoryType.income, icon: 58637);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'name',
              regex: RegExp('BREX REIMB'))
              .toUnidentifiedMap());

      // Travel spending
      category = Category(id: -1, name: "Travel", type: CategoryType.spending, icon: 0xeeb4);
      category.id =
      await db.insert(tableCategories, category.toUnidentifiedMap());
      rule = Rule(id: -1, category: category, priority: 2);
      rule.id = await db.insert(tableRules, rule.toUnidentifiedMap());
      await db.insert(
          tableRulesegments,
          Rulesegment(
              id: -1,
              rule: rule,
              param: 'detailed_category',
              regex: RegExp('TRAVEL'))
              .toUnidentifiedMap());
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
  
  // Helper method to associate categories with a budget
  Future<void> associateCategoriesWithBudget(int budgetId, List<int> categoryIds) async {
    // Update categories to reference this budget
    for (var categoryId in categoryIds) {
      await db.update(
        tableCategories,
        {categoriesColumnBudgetId: budgetId},
        where: '$categoriesColumnId = ?', 
        whereArgs: [categoryId]
      );
    }
  }
  
  // Helper method to remove budget associations from categories
  Future<void> removeBudgetFromCategories(int budgetId) async {
    await db.update(
      tableCategories,
      {categoriesColumnBudgetId: null},
      where: '$categoriesColumnBudgetId = ?', 
      whereArgs: [budgetId]
    );
  }

  Future<Budget> updateBudget(Budget budget) async {
    await db.update(tableBudgets, budget.toMap(),
        where: '$budgetsColumnId = ?', whereArgs: [budget.id]);
    return budget;
  }

  Future<Budget> deleteBudget(Budget budget) async {
    // First remove budget associations from all categories
    await removeBudgetFromCategories(budget.id);
    
    // Then delete the budget
    await db.delete(tableBudgets,
        where: '$budgetsColumnId = ?', whereArgs: [budget.id]);
    return budget;
  }

  Future<Budget?> getBudgetById(int budgetId) async {
    List<Map<String, dynamic>> maps = await db.query(
      tableBudgets,
      where: '$budgetsColumnId = ?',
      whereArgs: [budgetId]
    );
    
    if (maps.isNotEmpty) {
      var budget = Budget.fromMap(maps.first);
      // Load associated categories
      budget.categories = (await getCategoriesByBudgetId(budgetId)).toList();
      return budget;
    }
    return null;
  }

  Future<Iterable<Budget>> getBudgets() async {
    List<Map<String, dynamic>> maps = await db.query(tableBudgets);
    
    // Create budgets without loading categories yet
    List<Budget> budgets = maps.map((e) => Budget.fromMap(e)).toList();

    List<Budget> budgetsWithCategories = [];
    // Load categories for each budget
    for (var budget in budgets) {
      budget.categories = (await getCategoriesByBudgetId(budget.id)).toList();
      budgetsWithCategories.add(budget);
    }
    
    return budgetsWithCategories;
  }
  
  // New method to get categories by budget ID
  Future<Iterable<Category>> getCategoriesByBudgetId(int budgetId) async {
    List<Map<String, dynamic>> maps = await db.query(
      tableCategories,
      where: '$categoriesColumnBudgetId = ?',
      whereArgs: [budgetId]
    );
    return maps.map((e) => Category.fromMap(e));
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
    where $rulesColumnId = $ruleId
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
