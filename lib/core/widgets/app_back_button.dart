import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/locale_keys.dart';
import 'app_icon_button.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AppIconButton(icon: Icons.arrow_back_rounded, onPressed: onPressed ?? () => context.pop(), semanticLabel: context.tr(LocaleKeys.commonBack));
}
