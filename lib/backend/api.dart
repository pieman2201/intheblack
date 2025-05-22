import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pfm/backend/types.dart';

import '../util.dart';

class ApiClient {
  final String clientId;
  final String secret;

  ApiClient(this.clientId, this.secret);

  Future<(Iterable<TransactionsDiff>, Map<String, String>)> syncTransactions(
    Map<String, String> nextCursorMap,
  ) async {
    List<TransactionsDiff> diffs = [];
    Map<String, String> newCursorMap = Map<String, String>.from(nextCursorMap);
    for (final accessToken in newCursorMap.keys) {
      bool hasMore = true;
      while (hasMore) {
        Map<String, dynamic> payload = <String, dynamic>{
          'client_id': clientId,
          'secret': secret,
          'access_token': accessToken,
          'options': {'include_original_description': true},
        };
        if (newCursorMap.containsKey(accessToken) &&
            newCursorMap[accessToken] != null.toString()) {
          payload['cursor'] = newCursorMap[accessToken]!;
        }

        http.Response resp = await http.post(
          Uri.parse("https://production.plaid.com/transactions/sync"),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (resp.statusCode == 200) {
          var decodedResp = jsonDecode(resp.body) as Map<String, dynamic>;

          var tDiff = TransactionsDiff.fromJson(decodedResp);
          hasMore = decodedResp['has_more'];
          newCursorMap[accessToken] = tDiff.nextCursor;
          diffs.add(tDiff);
        } else {
          printDebug(accessToken);
          printDebug(resp.statusCode);
          printDebug(resp.body);
          throw Exception("Failed to sync transactions");
        }
      }
    }
    return (diffs, newCursorMap);
  }
}
