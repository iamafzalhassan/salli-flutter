import 'package:flutter_test/flutter_test.dart';
import 'package:salli/features/wallet/presentation/widgets/transaction_tile.dart';

import '../../../../helpers/localized_app.dart';
import '../../../../helpers/wallet_fakes.dart';

void main() {
  testWidgets('shows who, what and a signed amount on one line each', (tester) async {
    await pumpLocalized(tester, TransactionTile(transaction: testTransaction));
    expect(find.text('Kavindi Silva'), findsOneWidget);
    expect(find.text('−Rs. 1,500.00'), findsOneWidget);
    expect(find.textContaining('Sent'), findsOneWidget);
  });
}
