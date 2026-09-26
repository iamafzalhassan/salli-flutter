import 'package:flutter/foundation.dart';

class MockSms {
  final String body;

  final DateTime receivedAt;

  const MockSms({required this.body, required this.receivedAt});
}

class MockSmsInbox extends ValueNotifier<MockSms?> {
  MockSmsInbox() : super(null);

  void deliver(String body) => value = MockSms(body: body, receivedAt: DateTime.now());
}
