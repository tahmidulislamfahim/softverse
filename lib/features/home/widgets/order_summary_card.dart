import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/primary_button.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/helpers/app_helper.dart';

import '../../../core/utils/responsive.dart';

class OrderSummaryCard extends StatelessWidget {
  final String orderId;
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;

  const OrderSummaryCard({
    super.key,
    required this.orderId,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);

    return Container(
      padding: isLand
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
          : EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: getTextStyle(
                    fontSize: isLand ? 15.0 : 16.4,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isLand ? 6 : 20.h),
                Text(
                  'Item : $itemCount',
                  style: getTextStyle(
                    fontSize: isLand ? 12.0 : 12.8,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppHelperFunctions.formatCurrency(total),
                style: getTextStyle(
                  fontSize: isLand ? 18.0 : 21.9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isLand ? 6 : 12.h),
              PrimaryButton(
                label: 'Checkout',
                onPressed: onCheckout,
                icon: Iconsax.add_circle,
                iconSize: isLand ? 16 : 18,
                width: isLand ? 116 : 133.w,
                height: isLand ? 34 : 37,
                fontSize: isLand ? 14.5 : 16.4,
                textColor: AppColors.authTextDark,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.checkoutGoldStart,
                    AppColors.checkoutGoldMid,
                    AppColors.checkoutGoldLight,
                    AppColors.checkoutGoldMid,
                    AppColors.checkoutGoldEnd,
                  ],
                ),
                borderRadius: 999,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
