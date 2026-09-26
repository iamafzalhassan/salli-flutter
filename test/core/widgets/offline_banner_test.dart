import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/network/network_status.dart';
import 'package:salli/core/widgets/offline_banner.dart';

import '../../helpers/localized_app.dart';

void main() {
  testWidgets('slides in while offline and away once back', (tester) async {
    final status = NetworkStatus(() async => false);
    await pumpLocalized(tester, OfflineBanner(status: status, child: const SizedBox.expand()));
    double opacity() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 0);
    status.markOffline();
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    expect(find.textContaining("You're offline"), findsOneWidget);
    status.markOnline();
    await tester.pumpAndSettle();
    expect(opacity(), 0);
    status.dispose();
  });
}
