import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_list_tile.dart';

class OptionSheet<T> extends StatelessWidget {
  const OptionSheet({super.key, required this.title, required this.options});

  static const double _maxHeightScale = 0.6;

  final String title;

  final List<({Widget? leading, String? subtitle, String title, T value})> options;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.md),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * _maxHeightScale),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [for (final option in options) AppListTile(leading: option.leading, onPressed: () => Navigator.of(context).pop(option.value), subtitle: option.subtitle, title: option.title)],
        ),
      ),
    ],
  );
}
