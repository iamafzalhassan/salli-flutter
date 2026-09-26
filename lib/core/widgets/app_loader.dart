import 'package:flutter/cupertino.dart';

import '../theme/app_spacing.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.color});

  static const double _radius = AppSpacing.progressIndicator / 2;

  final Color? color;

  @override
  Widget build(BuildContext context) => CupertinoActivityIndicator(color: color, radius: _radius);
}
