import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/services/business_profile_service.dart';
import '../../../core/common/widgets/dashed_divider.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/helpers/app_helper.dart';

import '../../../core/utils/responsive.dart';

class BillSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final String? discountLabel;
  final double loyaltyDiscount;
  final double tax;
  final double taxRate;
  final double totalAmount;
  final TextEditingController amountReceivedController;
  final double changeToReturn;
  final ValueChanged<String> onAmountReceivedChanged;

  const BillSummaryCard({
    super.key,
    required this.subtotal,
    this.discount = 0,
    this.discountLabel,
    this.loyaltyDiscount = 0,
    required this.tax,
    required this.taxRate,
    required this.totalAmount,
    required this.amountReceivedController,
    required this.changeToReturn,
    required this.onAmountReceivedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);
    final rowSpacing = isLand ? 5.0 : 8.h;
    final divSpacing = isLand ? 6.0 : 12.h;

    return Container(
      padding: isLand
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
          : EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.billCardStart,
            AppColors.billCardMid1,
            AppColors.billCardMid2,
            AppColors.billCardEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          _Row(
            label: 'Subtotal',
            value: AppHelperFunctions.formatCurrency(subtotal),
            compact: isLand,
          ),
          if (discount > 0) ...[
            SizedBox(height: rowSpacing),
            _Row(
              label: discountLabel ?? 'Discount',
              value: '-${AppHelperFunctions.formatCurrency(discount)}',
              compact: isLand,
            ),
          ],
          if (loyaltyDiscount > 0) ...[
            SizedBox(height: rowSpacing),
            _Row(
              label: 'Loyalty points',
              value: '-${AppHelperFunctions.formatCurrency(loyaltyDiscount)}',
              compact: isLand,
            ),
          ],
          SizedBox(height: rowSpacing),
          _Row(
            label: 'TAX (${(taxRate * 100).toStringAsFixed(1)}%)',
            value: AppHelperFunctions.formatCurrency(tax),
            compact: isLand,
          ),
          SizedBox(height: divSpacing),
          const DashedDivider(),
          SizedBox(height: divSpacing),
          _Row(
            label: 'Total Amount',
            value: AppHelperFunctions.formatCurrency(totalAmount),
            emphasize: true,
            compact: isLand,
          ),
          SizedBox(height: divSpacing),
          Row(
            children: [
              Text(
                'Amount Received',
                style: getTextStyle(
                  fontSize: isLand ? 13.5 : 14.6,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                width: isLand ? 90 : 95.w,
                height: isLand ? 32 : 37.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: onAmountReceivedChanged,
                  controller: amountReceivedController,
                  style: getTextStyle(
                    fontSize: isLand ? 13.5 : 14.6,
                    color: AppColors.authTextDark,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixText: BusinessProfileService.currencySymbol,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: divSpacing),
          const DashedDivider(),
          SizedBox(height: divSpacing),
          _Row(
            label: 'Change to Return',
            value: AppHelperFunctions.formatCurrency(changeToReturn),
            emphasize: true,
            compact: isLand,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final bool compact;

  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseSize = compact ? 13.5 : 14.6;
    final empSize = compact ? 15.0 : 16.4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getTextStyle(fontSize: baseSize, color: Colors.white),
        ),
        Text(
          value,
          style: getTextStyle(
            fontSize: emphasize ? empSize : baseSize,
            fontWeight: emphasize ? FontWeight.w500 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
