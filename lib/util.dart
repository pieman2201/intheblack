import 'package:flutter/foundation.dart';

import 'backend/types.dart';

Map<CategoryType, String Function(num amount)> categoryTypeAmountFormatters = {
  CategoryType.spending: (num amount) {
    amount = amount.round();
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(0)}';
  },
  CategoryType.living: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(0)}';
  },
  CategoryType.income: (num amount) {
    if (amount <= 0) {
      return '\$${amount.abs().toStringAsFixed(0)}';
    }
    return '-\$${amount.toStringAsFixed(0)}';
  },
  CategoryType.ignored: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(0)}';
  },
  CategoryType.invisible: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(0)}';
  },
};

Map<CategoryType, String Function(num amount)>
categoryTypeRemainingAmountFormatters = {
  CategoryType.spending: (num amount) {
    if (amount < 0) {
      return '\$${amount.abs().toStringAsFixed(0)} over';
    }
    return '\$${amount.toStringAsFixed(0)} left';
  },
  CategoryType.living: (num amount) {
    if (amount < 0) {
      return '\$${amount.abs().toStringAsFixed(0)} over';
    }
    return '\$${amount.toStringAsFixed(0)} left';
  },
  CategoryType.income: (num amount) {
    if (amount < 0) {
      return '\$${amount.abs().toStringAsFixed(0)} expected';
    }
    return '\$${amount.toStringAsFixed(0)} extra';
  },
  CategoryType.ignored: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(0)}';
  },
  CategoryType.invisible: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(0)}';
    }
    return '\$${amount.toStringAsFixed(0)}';
  },
};

Map<CategoryType, String Function(num amount)>
categoryTypeMiscAmountFormatters = {
  CategoryType.spending: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(2)}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  },
  CategoryType.living: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(2)}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  },
  CategoryType.income: (num amount) {
    if (amount <= 0) {
      return '\$${amount.abs().toStringAsFixed(2)}';
    }
    return '-\$${amount.toStringAsFixed(2)}';
  },
  CategoryType.ignored: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(2)}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  },
  CategoryType.invisible: (num amount) {
    if (amount < 0) {
      return '+\$${amount.abs().toStringAsFixed(2)}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  },
};

void printDebug(Object? o) {
  if (kDebugMode) {
    print(o);
  }
}
