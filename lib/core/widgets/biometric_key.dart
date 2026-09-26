import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class BiometricKey extends StatelessWidget {
  const BiometricKey({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(LocaleKeys.biometricUse),
    child: Icon(Icons.fingerprint_rounded, color: context.colors.accentInk, size: AppSpacing.iconLg),
  );
}
