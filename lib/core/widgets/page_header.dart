import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_back_button.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, this.title, this.onBack});

  final String? title;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return SizedBox(
      height: AppSpacing.touchTarget,
      child: Row(
        children: [
          AppBackButton(onPressed: onBack),
          if (title != null) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
            ),
          ],
        ],
      ),
    );
  }
}
