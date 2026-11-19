import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/product_image.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/helpers/app_helper.dart';
import '../../checkout/models/cart_item.dart';

class InvoiceItemCard extends StatelessWidget {
  final CartItem item;
  final bool selectable;
  final bool selected;
  final VoidCallback? onTap;
  final int? refundQuantity;
  final int? maxRefundQuantity;
  final int alreadyRefundedQuantity;
  final ValueChanged<int>? onRefundQuantityChanged;

  const InvoiceItemCard({
    super.key,
    required this.item,
    this.selectable = false,
    this.selected = false,
    this.onTap,
    this.refundQuantity,
    this.maxRefundQuantity,
    this.alreadyRefundedQuantity = 0,
    this.onRefundQuantityChanged,
  });

  Future<void> _promptCustomRefundQty(
    BuildContext context,
    int currentQty,
    int maxQty,
  ) async {
    if (onRefundQuantityChanged == null || maxQty <= 0) return;
    final textController = TextEditingController(text: '$currentQty');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refund quantity (max $maxQty)'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '1 - $maxQty',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(int.tryParse(val.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              ctx,
            ).pop(int.tryParse(textController.text.trim())),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) {
      onRefundQuantityChanged!(result.clamp(0, maxQty));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeQty = selectable && selected && refundQuantity != null
        ? refundQuantity!
        : item.quantity;
    final maxQty = maxRefundQuantity ?? item.quantity;
    final unitPrice = item.bundle?.subtotal ?? item.price;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selectable && selected
                ? AppColors.authLink
                : AppColors.cardBorder,
            width: selectable && selected ? 1.5 : 1,
          ),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white, AppColors.rowGradientEnd],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectable) ...[
              Padding(
                padding: EdgeInsets.only(top: 2.h, right: 12.w),
                child: _CheckboxIndicator(selected: selected),
              ),
            ],
            ProductImage(imageUrl: item.imageUrl, size: 46),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: getTextStyle(
                            fontSize: 14.6,
                            fontWeight: FontWeight.w500,
                            color: AppColors.authTextDark,
                          ),
                        ),
                      ),
                      Text(
                        AppHelperFunctions.formatCurrency(
                          unitPrice * activeQty,
                        ),
                        style: getTextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onboardingBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${item.quantity} x ${AppHelperFunctions.formatCurrency(item.price)}',
                    style: getTextStyle(
                      fontSize: 12.5,
                      color: AppColors.chipInactiveText,
                    ),
                  ),
                  if (alreadyRefundedQuantity > 0) ...[
                    SizedBox(height: 3.h),
                    Text(
                      'Already refunded: $alreadyRefundedQuantity • Remaining: $maxQty',
                      style: getTextStyle(
                        fontSize: 11.5,
                        color: AppColors.dangerRed,
                      ),
                    ),
                  ],
                  if (selectable &&
                      selected &&
                      onRefundQuantityChanged != null &&
                      maxQty > 0) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Refund Qty (of $maxQty):',
                          style: getTextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.authTextDark,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StepBtn(
                              icon: Icons.remove,
                              onTap: () => onRefundQuantityChanged!(
                                (activeQty - 1).clamp(0, maxQty),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _promptCustomRefundQty(
                                context,
                                activeQty,
                                maxQty,
                              ),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: Text(
                                  '$activeQty',
                                  style: getTextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.authTextDark,
                                  ),
                                ),
                              ),
                            ),
                            _StepBtn(
                              icon: Icons.add,
                              onTap: activeQty < maxQty
                                  ? () => onRefundQuantityChanged!(
                                      (activeQty + 1).clamp(0, maxQty),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  if (item.bundle != null) ...[
                    SizedBox(height: 4.h),
                    _Row(label: item.bundle!.name, value: item.bundle!.price),
                    SizedBox(height: 4.h),
                    _Row(
                      label: item.bundle!.discountLabel,
                      value: item.bundle!.discountAmount,
                    ),
                    SizedBox(height: 4.h),
                    _Row(
                      label: 'Sub Total',
                      value: item.bundle!.subtotal,
                      emphasize: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26.w,
        height: 26.w,
        decoration: BoxDecoration(
          color: enabled ? AppColors.onboardingBackground : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, size: 15.sp, color: Colors.white),
      ),
    );
  }
}

class _CheckboxIndicator extends StatelessWidget {
  final bool selected;

  const _CheckboxIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(
          color: selected ? AppColors.authLink : AppColors.chipInactiveText,
        ),
        gradient: selected
            ? const LinearGradient(
                colors: [
                  AppColors.checkboxGradientStart,
                  AppColors.checkboxGradientEnd,
                ],
              )
            : null,
      ),
      child: selected
          ? Icon(Icons.check, size: 14.sp, color: Colors.white)
          : null,
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getTextStyle(
            fontSize: 14.6,
            fontWeight: FontWeight.w500,
            color: AppColors.authTextDark,
          ),
        ),
        Text(
          AppHelperFunctions.formatCurrency(value),
          style: getTextStyle(
            fontSize: emphasize ? 16.4 : 14.6,
            fontWeight: emphasize ? FontWeight.w500 : FontWeight.w400,
            color: AppColors.onboardingBackground,
          ),
        ),
      ],
    );
  }
}
