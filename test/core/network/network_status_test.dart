import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/network/network_status.dart';

void main() {
  test('goes offline once and back online on the next answer', () {
    final status = NetworkStatus(() async => false);
    var changes = 0;
    status
      ..addListener(() => changes++)
      ..markOffline()
      ..markOffline();
    expect(status.isOffline, isTrue);
    status
      ..markOnline()
      ..markOnline();
    expect(status.isOffline, isFalse);
    expect(changes, 2);
    status.dispose();
  });
}
