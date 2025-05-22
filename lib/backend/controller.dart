import 'package:pfm/backend/api.dart';
import 'package:pfm/backend/db.dart';
import 'package:pfm/backend/types.dart';
import 'package:pfm/util.dart';

import 'categorize.dart';

class BackendController {
  DbClient dbClient;
  late ApiClient apiClient;
  late CategorizationClient categorizationClient;

  BackendController() : dbClient = DbClient();

  Future open() async {
    await dbClient.open();
    await loadCategorizationClient();
    await openApiClient();
  }

  Future openApiClient() async {
    Map<SettingsType, String> settings = await getSettings();
    apiClient = ApiClient(settings[SettingsType.apiClientId].toString(),
        settings[SettingsType.apiSecret].toString());
  }

  Future loadCategorizationClient() async {
    categorizationClient = CategorizationClient(
      (await getCategories()).firstWhere((element) => element.id == 0),
      await getRulesWithSegments(),
    );
  }

  DateTime getNthPreviousMonth(int n) {
    DateTime currentTime = DateTime.now();
    int currentMonth = currentTime.month;
    int currentYear = currentTime.year;

    int monthToShowMonth = currentMonth - n;
    int monthToShowYear = currentYear;
    while (monthToShowMonth <= 0) {
      monthToShowMonth += 12;
      monthToShowYear--;
    }
    return DateTime(monthToShowYear, monthToShowMonth);
  }

  (DateTime, DateTime) getMonthBounds(DateTime month) {
    DateTime beginningOfCurrentMonth =
        DateTime(month.year, month.month);
    int nextMonth = month.month + 1;
    int nextYear = month.year;
    if (nextMonth >= 13) {
      nextMonth -= 12;
      nextYear++;
    }
    DateTime beginningOfNextMonth = DateTime(nextYear, nextMonth);
    DateTime endOfCurrentMonth = beginningOfNextMonth.subtract(const Duration(days: 1));
    return (beginningOfCurrentMonth, endOfCurrentMonth);
  }

  Future insertTransactionAndSurface(Transaction transaction) async {
    await dbClient.insertTransaction(transaction);
    if (transaction.pendingTransactionId != null && !transaction.pending) {
      // Find and transfer associated pending SurfacedTransactions
      Transaction? pendingTransaction = await dbClient
          .getTransactionByTransactionId(transaction.pendingTransactionId!);
      if (pendingTransaction != null && pendingTransaction.pending) {
        // Found pending transaction
        Iterable<SurfacedTransaction> pendingSurfacedTransactions =
            await dbClient
                .getSurfacedTransactionsForTransaction(pendingTransaction);
        for (SurfacedTransaction pendingSurfacedTransaction
            in pendingSurfacedTransactions) {
          pendingSurfacedTransaction.realTransaction = transaction;
          await dbClient.updateSurfacedTransaction(pendingSurfacedTransaction);
        }

        return; // Don't add new SurfacedTransaction for this
      }
    }
    await dbClient.insertSurfacedTransaction(SurfacedTransaction(
        id: -1,
        realTransaction: transaction,
        category: categorizationClient.categorizeTransaction(transaction),
        percentOfRealAmount: 100,
        name: transaction.merchantName ?? transaction.name));
  }

  Future syncTransactionsAndStore() async {
    var (tDiffs, lNextCursorMap) =
        await apiClient.syncTransactions(await dbClient.retrieveCursorValues());
    for (String accessToken in lNextCursorMap.keys) {
      await dbClient.updateCursorValue(
          accessToken, lNextCursorMap[accessToken]!);
    }

    for (TransactionsDiff tDiff in tDiffs) {
      for (Transaction addedTransaction in tDiff.added) {
        await insertTransactionAndSurface(addedTransaction);
      }
      for (Transaction modifiedTransaction in tDiff.modified) {
        Transaction? originalTransaction = await dbClient
            .getTransactionByTransactionId(modifiedTransaction.transactionId);
        if (originalTransaction == null) {
          await insertTransactionAndSurface(modifiedTransaction);
        } else {
          modifiedTransaction.id = originalTransaction.id;
          await dbClient.updateTransaction(modifiedTransaction);
        }
      }
      for (String removedTransactionId in tDiff.removed) {
        Transaction? originalTransaction =
            await dbClient.getTransactionByTransactionId(removedTransactionId);
        printDebug(originalTransaction);
        if (originalTransaction != null) {
          // Remove surfaced transaction associated with the transaction
          Iterable<SurfacedTransaction> surfacedTransactions = await dbClient
              .getSurfacedTransactionsForTransaction(originalTransaction);
          for (SurfacedTransaction surfacedTransaction
              in surfacedTransactions) {
            await dbClient.deleteSurfacedTransaction(surfacedTransaction);
          }
          // Now it is safe to remove the original transaction
          await dbClient.deleteTransaction(originalTransaction);
        }
      }
    }
  }

  Future<List<SurfacedTransaction>> getSurfacedTransactionsInDateRange(
      DateTime startDate, DateTime endDate) async {
    Iterable<SurfacedTransaction> matchingSurfacedTransactions =
        await dbClient.getSurfacedTransactionsInDateRange(startDate, endDate);
    List<SurfacedTransaction> surfacedTransactionList =
        matchingSurfacedTransactions.toList();
    surfacedTransactionList.sort(
        (b, a) => a.realTransaction.date.compareTo(b.realTransaction.date));
    surfacedTransactionList.removeWhere((e) => e.category.type == CategoryType.invisible);
    return surfacedTransactionList;
  }

  Future<List<SurfacedTransaction>>
      getSurfacedTransactionsInCategoryInDateRange(
          Category category, DateTime startDate, DateTime endDate) async {
    Iterable<SurfacedTransaction> matchingSurfacedTransactions =
        await dbClient.getSurfacedTransactionsInCategoryInDateRange(
            category, startDate, endDate);
    List<SurfacedTransaction> surfacedTransactionList =
        matchingSurfacedTransactions.toList();
    surfacedTransactionList.sort(
        (b, a) => a.realTransaction.date.compareTo(b.realTransaction.date));
    return surfacedTransactionList;
  }

  Future<SurfacedTransaction> updateSurfacedTransaction(
      SurfacedTransaction surfacedTransaction) async {
    return await dbClient.updateSurfacedTransaction(surfacedTransaction);
  }

  Future<Map<String, String>> getAccessTokenCursors() async {
    return await dbClient.retrieveCursorValues();
  }

  Future<Map<String, String>> addNewAccessToken(String accessToken) async {
    await dbClient.updateCursorValue(accessToken, null.toString());
    return getAccessTokenCursors();
  }

  Future clearAccessTokens() async {
    await dbClient.clearCursorValues();
  }

  Future<Map<SettingsType, String>> getSettings() async {
    return await dbClient.retrieveSettings();
  }

  Future<Map<SettingsType, String>> changeSetting(
      SettingsType settingsType, String value) async {
    await dbClient.updateSetting(settingsType, value);
    return getSettings();
  }

  Future<Category> upsertCategory(Category category) async {
    Category? existingCategory = await dbClient.getCategoryById(category.id);
    if (existingCategory == null) {
      // Insert
      return await dbClient.insertCategory(category);
    } else {
      // Update
      return await dbClient.updateCategory(category);
    }
  }
  
  // Associate a category with a budget
  Future<Category> assignCategoryToBudget(Category category, Budget? budget) async {
    // Update category with budget reference
    category.budgetId = budget?.id;
    return await upsertCategory(category);
  }
  
  // Get categories assigned to a specific budget
  Future<List<Category>> getCategoriesForBudget(Budget budget) async {
    return (await dbClient.getCategoriesByBudgetId(budget.id)).toList();
  }

  Future<Iterable<Category>> getCategories() async {
    return await dbClient.getCategories();
  }

  Future deleteCategory(Category category) async {
    // Remove category from all surfaced transactions in the category to be deleted
    Iterable<SurfacedTransaction> allBudgetTransactions =
        await dbClient.getSurfacedTransactionsInCategoryInDateRange(
            category,
            DateTime.fromMillisecondsSinceEpoch(0),
            DateTime.now().add(const Duration(days: 1)));

    for (SurfacedTransaction budgetTransaction in allBudgetTransactions) {
      budgetTransaction.category = categorizationClient
          .categorizeTransaction(budgetTransaction.realTransaction);
      await dbClient.updateSurfacedTransaction(budgetTransaction);
    }

    // Remove category itself
    await dbClient.deleteCategory(category);
  }

  Future<Budget> upsertBudget(Budget budget, List<Category> categories) async {
    Budget? existingBudget = await dbClient.getBudgetById(budget.id);
    Budget savedBudget;
    
    if (existingBudget == null) {
      // Insert new budget
      savedBudget = await dbClient.insertBudget(budget);
    } else {
      // Update existing budget
      savedBudget = await dbClient.updateBudget(budget);
      
      // Remove old category associations
      await dbClient.removeBudgetFromCategories(budget.id);
    }
    
    // Associate selected categories with this budget
    List<int> categoryIds = categories.map((c) => c.id).toList();
    await dbClient.associateCategoriesWithBudget(savedBudget.id, categoryIds);
    
    // Update cached categories in budget
    savedBudget.categories = categories;
    
    return savedBudget;
  }

  // Get all budgets with their categories populated
  Future<Iterable<Budget>> getBudgets() async {
    printDebug("GETTING BUDGETS");
    Iterable<Budget> budgets = await dbClient.getBudgets();
    printDebug("BUDGETS: ");
    printDebug(budgets);
    return budgets;
  }

  Future deleteBudget(Budget budget) async {
    // This will automatically remove budget references from categories
    await dbClient.deleteBudget(budget);
  }

  Future<Iterable<RuleWithSegments>> getRulesWithSegments() async {
    Iterable<Rule> rules = await dbClient.getRules();
    List<RuleWithSegments> rulesWithSegments = [];
    for (var rule in rules) {
      rulesWithSegments.add(RuleWithSegments(
          rule: rule, segments: await dbClient.getRulesegmentsForRule(rule)));
    }
    return rulesWithSegments;
  }

  Future<RuleWithSegments> upsertRuleWithSegments(
      RuleWithSegments ruleWithSegments) async {
    Rule? existingRule = await dbClient.getRuleById(ruleWithSegments.rule.id);
    if (existingRule == null) {
      // Need to insert rule
      await dbClient.insertRule(ruleWithSegments.rule);
    } else {
      // Rule already exists
      await dbClient.updateRule(ruleWithSegments.rule);
    }

    var existingSegments =
        await dbClient.getRulesegmentsForRule(ruleWithSegments.rule);

    // Check each of the segments to see if it exists already
    for (Rulesegment segment in ruleWithSegments.segments) {
      var found = false;
      for (var existingSegment in existingSegments) {
        if (segment.id == existingSegment.id) {
          // Already exists
          await dbClient.updateRulesegment(segment);
          found = true;
          break;
        }
      }
      if (!found) {
        // Need to insert
        await dbClient.insertRulesegment(segment);
      }
    }

    await loadCategorizationClient();

    return ruleWithSegments;
  }

  Future deleteRuleWithSegments(RuleWithSegments ruleWithSegments) async {
    await dbClient.deleteRule(ruleWithSegments.rule);
    for (var segment in ruleWithSegments.segments) {
      await dbClient.deleteRulesegment(segment);
    }

    await loadCategorizationClient();
  }
}
