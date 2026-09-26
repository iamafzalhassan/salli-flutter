import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/security/sms_consent.dart';

class SmsCodeListener extends StatefulWidget {
  const SmsCodeListener({super.key, required this.codeLength, required this.onCode, required this.child});

  final int codeLength;

  final ValueChanged<String> onCode;

  final Widget child;

  @override
  State<SmsCodeListener> createState() => _SmsCodeListenerState();
}

class _SmsCodeListenerState extends State<SmsCodeListener> {
  final SmsConsent _smsConsent = const SmsConsent();

  Future<void> _listen() async {
    final code = await _smsConsent.listenForCode(widget.codeLength);
    if (code != null && mounted) widget.onCode(code);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_listen());
  }

  @override
  void dispose() {
    unawaited(_smsConsent.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
