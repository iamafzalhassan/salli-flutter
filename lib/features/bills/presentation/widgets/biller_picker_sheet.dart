import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../payments/domain/entities/bill_category.dart';
import '../../domain/entities/biller.dart';

class BillerPickerSheet extends StatelessWidget {
  const BillerPickerSheet({super.key, required this.billers, required this.category});

  static const double _maxHeightScale = 0.6;

  final List<Biller> billers;

  final BillCategory category;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.tr('${LocaleKeys.billCategoryPrefix}.${category.name}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.md),
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * _maxHeightScale),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            for (final biller in billers)
              AppListTile(
                leading: IconAvatar(icon: CategoryIcons.of(biller.category.name), isAccent: false),
                onPressed: () => Navigator.of(context).pop(biller),
                title: biller.name,
              ),
          ],
        ),
      ),
    ],
  );
}
