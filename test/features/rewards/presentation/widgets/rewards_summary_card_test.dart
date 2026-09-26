import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/theme/app_theme.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/rewards/domain/entities/referral.dart';
import 'package:salli/features/rewards/domain/entities/rewards_summary.dart';
import 'package:salli/features/rewards/presentation/widgets/rewards_summary_card.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  const summary = RewardsSummary(
    cashback: Money(152500),
    minRedeemPoints: 500,
    points: 740,
    pointStep: 100,
    pointValue: Money(10),
    referral: Referral(canClaim: false, code: 'SALLIABCD', joinedCount: 2, reward: Money.rupees(250)),
    scratchCards: [],
  );

  const cardWidth = 360.0;

  for (final (name, theme) in [('dark', AppTheme.dark), ('light', AppTheme.light)]) {
    testWidgets('matches the $name golden', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: cardWidth,
          child: RewardsSummaryCard(summary: summary),
        ),
        theme: theme,
      );
      await expectLater(find.byType(RewardsSummaryCard), matchesGoldenFile('goldens/rewards_summary_card_$name.png'));
    });
  }

  testWidgets('offers redemption only from the minimum points', (tester) async {
    await pumpLocalized(
      tester,
      const SizedBox(
        width: cardWidth,
        child: RewardsSummaryCard(summary: summary),
      ),
    );
    expect(find.text('740 points'), findsOneWidget);
    expect(find.text('Worth Rs. 74.00'), findsOneWidget);
  });
}
