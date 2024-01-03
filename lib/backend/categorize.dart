import 'package:pfm/backend/types.dart';

class CategorizationClient {
  final Category fallbackCategory;
  final Iterable<RuleWithSegments> rulesWithSegments;

  late List<RuleWithSegments> sortedByPriority;

  CategorizationClient(this.fallbackCategory, this.rulesWithSegments) {
    sortedByPriority = rulesWithSegments.toList();
    sortedByPriority.sort((a, b) => a.rule.priority.compareTo(b.rule.priority));
  }

  Category getFallbackCategory() {
    return fallbackCategory;
  }

  Category categorizeTransaction(Transaction transaction) {
    Category category = getFallbackCategory();
    for (var ruleWithSegments in sortedByPriority) {
      if (ruleWithSegments.matchesTransaction(transaction)) {
        category = ruleWithSegments.rule.category;
      }
    }
    return category;
  }
}
