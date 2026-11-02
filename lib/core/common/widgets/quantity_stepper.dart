import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../utils/constants/colors.dart';
import '../styles/global_text_style.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int>? onQuantityChanged;
  final double width;
  final double height;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.onQuantityChanged,
    this.width = 114,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: height.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999.r),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onDecrement,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Icon(Iconsax.minus, size: 18.sp, color: Colors.white),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final textController = TextEditingController(text: '$quantity');
              final result = await showDialog<int>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Enter Quantity'),
                  content: TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final val = int.tryParse(textController.text.trim());
                        if (val != null && val >= 0) {
                          Navigator.of(ctx).pop(val);
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              if (result != null && onQuantityChanged != null) {
                onQuantityChanged!(result);
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Text(
                '$quantity',
                style: getTextStyle(
                  fontSize: 16.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Icon(Iconsax.add, size: 18.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
