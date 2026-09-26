import 'package:flutter/material.dart';

import '../../domain/entities/transaction_type.dart';

abstract final class TransactionIcons {
  static const Map<TransactionType, IconData> _icons = {
    TransactionType.bankTransfer: Icons.account_balance_rounded,
    TransactionType.bill: Icons.receipt_long_rounded,
    TransactionType.bonus: Icons.redeem_rounded,
    TransactionType.card: Icons.credit_card_rounded,
    TransactionType.cashback: Icons.savings_rounded,
    TransactionType.fee: Icons.percent_rounded,
    TransactionType.merchant: Icons.storefront_rounded,
    TransactionType.other: Icons.swap_horiz_rounded,
    TransactionType.reload: Icons.phone_android_rounded,
    TransactionType.topUp: Icons.add_card_rounded,
    TransactionType.transferIn: Icons.south_west_rounded,
    TransactionType.transferOut: Icons.north_east_rounded,
    TransactionType.withdrawal: Icons.account_balance_wallet_rounded,
  };

  static IconData of(TransactionType type) => _icons[type] ?? Icons.swap_horiz_rounded;
}
