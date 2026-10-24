import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/responsive.dart';

class ShiftActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const ShiftActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);
    final Color contentColor = filled
        ? Colors.white
        : AppColors.chipInactiveText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLand ? 46.0 : 54.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: filled ? null : AppColors.chipBackground,
          border: filled ? null : Border.all(color: AppColors.cardBorder),
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.shiftButtonGradientStart,
                    AppColors.shiftButtonGradientEnd,
                  ],
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isLand ? 20.0 : 24.0, color: contentColor),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: getTextStyle(
                  fontSize: isLand ? 14.5 : 15.5,
                  fontWeight: FontWeight.w500,
                  color: contentColor,
                ).copyWith(letterSpacing: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
