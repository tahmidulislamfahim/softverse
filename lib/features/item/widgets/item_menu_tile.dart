import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/responsive.dart';

class ItemMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ItemMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);
    final tileHeight = isLand ? 46.0 : 54.0;
    final iconSize = isLand ? 20.0 : 22.0;
    final fontSize = isLand ? 14.5 : 15.5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: tileHeight,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: AppColors.onboardingBackground),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: getTextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onboardingBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
