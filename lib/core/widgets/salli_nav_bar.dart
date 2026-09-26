import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';

class SalliNavItem {
  final String label;

  final IconData icon;

  const SalliNavItem({required this.label, required this.icon});
}

class SalliNavBar extends StatefulWidget {
  const SalliNavBar({super.key, required this.currentIndex, required this.scanLabel, required this.items, required this.onSelected, required this.onScan});

  final int currentIndex;

  final String scanLabel;

  final List<SalliNavItem> items;

  final ValueChanged<int> onSelected;

  final VoidCallback onScan;

  @override
  State<SalliNavBar> createState() => _SalliNavBarState();
}

class _SalliNavBarState extends State<SalliNavBar> with SingleTickerProviderStateMixin {
  late final Animation<double> _breath = Tween<double>(begin: 1, end: AppMotion.breathScale).animate(_breathCurve);

  late final AnimationController _controller = AnimationController(duration: AppMotion.breath, vsync: this);

  late final CurvedAnimation _breathCurve = CurvedAnimation(curve: AppMotion.breathing, parent: _controller);

  Widget _item(int index) {
    final colors = context.colors;
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;
    return Expanded(
      child: Semantics(
        label: item.label,
        selected: isSelected,
        child: AppPressable(
          onPressed: () => widget.onSelected(index),
          child: Center(
            child: AnimatedContainer(
              curve: AppMotion.standard,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: isSelected ? colors.surfaceRaised : Colors.transparent),
              duration: AppMotion.base,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Icon(item.icon, color: isSelected ? colors.accentInk : colors.textSecondary, size: AppSpacing.iconMd),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final half = widget.items.length ~/ 2;
    return Padding(
      padding: EdgeInsets.only(bottom: max(MediaQuery.paddingOf(context).bottom, AppSpacing.md), left: AppSpacing.screenPadding, right: AppSpacing.screenPadding),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.border, width: AppSpacing.hairline),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: colors.surface,
        ),
        height: AppSpacing.navHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            for (var index = 0; index < half; index++) _item(index),
            RepaintBoundary(
              child: Semantics(
                button: true,
                label: widget.scanLabel,
                child: ScaleTransition(
                  scale: _breath,
                  child: AppPressable(
                    curve: AppMotion.spring,
                    onPressed: widget.onScan,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), color: colors.accent),
                      height: AppSpacing.scanButton,
                      width: AppSpacing.scanButton,
                      child: Icon(Icons.qr_code_scanner_rounded, color: colors.onAccent, size: AppSpacing.iconMd),
                    ),
                  ),
                ),
              ),
            ),
            for (var index = half; index < widget.items.length; index++) _item(index),
          ],
        ),
      ),
    );
  }
}
