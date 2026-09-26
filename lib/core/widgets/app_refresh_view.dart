import 'package:flutter/cupertino.dart';

class AppRefreshView extends StatelessWidget {
  const AppRefreshView({super.key, required this.children, required this.padding, required this.onRefresh});

  final List<Widget> children;

  final EdgeInsetsGeometry padding;

  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
    slivers: [
      CupertinoSliverRefreshControl(onRefresh: onRefresh),
      SliverPadding(
        padding: padding,
        sliver: SliverList.list(children: children),
      ),
    ],
  );
}
