import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class FillScrollView extends StatelessWidget {
  const FillScrollView({super.key, required this.children, this.crossAxisAlignment = CrossAxisAlignment.stretch, this.padding = const EdgeInsets.all(AppSpacing.screenPadding)});

  final List<Widget> children;

  final CrossAxisAlignment crossAxisAlignment;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: padding,
          child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
        ),
      ),
    ],
  );
}
