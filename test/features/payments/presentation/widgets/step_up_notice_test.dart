import 'package:flutter_test/flutter_test.dart';
import 'package:salli/features/payments/domain/entities/step_up_reason.dart';
import 'package:salli/features/payments/presentation/widgets/step_up_notice.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  testWidgets('explains every reason for the extra check', (tester) async {
    await pumpLocalized(tester, const StepUpNotice(reasons: {StepUpReason.largeAmount, StepUpReason.newPayee}));
    expect(find.text('Check before you pay'), findsOneWidget);
    expect(find.text('This is a large payment.'), findsOneWidget);
    expect(find.text("You haven't paid this person or account before."), findsOneWidget);
    expect(find.text('You signed in on this phone recently.'), findsNothing);
  });
}
