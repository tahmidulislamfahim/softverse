import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/utils/constants/colors.dart';
import '../controller/checkout_controller.dart';

class ModifierDiscountToggle extends StatelessWidget {
  final PriceAdjustmentMode mode;
  final VoidCallback onModifierTap;
  final VoidCallback onDiscountTap;

  const ModifierDiscountToggle({
    super.key,
    required this.mode,
    required this.onModifierTap,
    required this.onDiscountTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
              label: 'Modifier',
              icon: Iconsax.edit_2,
              selected: mode == PriceAdjustmentMode.modifier,
              onTap: onModifierTap,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildButton(
              label: 'Discount',
              icon: Iconsax.percentage_circle,
              selected: mode == PriceAdjustmentMode.discount,
              onTap: onDiscountTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          height: 48.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  )
                : null,
            color: selected ? null : Colors.white,
            border: selected ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: selected ? Colors.white : AppColors.authTextDark,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: getTextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.authTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
