import 'package:pfm/backend/api.dart';
import 'package:pfm/backend/db.dart';
import 'package:pfm/backend/types.dart';

class BackendController {
  DbClient dbClient;
  late ApiClient apiClient;

  BackendController() : dbClient = DbClient();

  Future open() async {
    await dbClient.open();
    await openApiClient();
  }

  Future openApiClient() async {
    Map<SettingsType, String> settings = await getSettings();
    apiClient = ApiClient(settings[SettingsType.apiClientId].toString(),
        settings[SettingsType.apiSecret].toString());
  }

  Future insertTransactionAndSurface(Transaction transaction) async {
    await dbClient.insertTransaction(transaction);
    await dbClient.insertSurfacedTransaction(SurfacedTransaction(
        id: -1,
        realTransaction: transaction,
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
      for (Transaction removedTransaction in tDiff.removed) {
        Transaction? originalTransaction = await dbClient
            .getTransactionByTransactionId(removedTransaction.transactionId);
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
    return surfacedTransactionList;
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
}
