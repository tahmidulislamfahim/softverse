import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/common/styles/global_text_style.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/responsive.dart';

class WalkthroughSlide extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const WalkthroughSlide({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);

    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(
                    imagePath,
                    width: 320,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: getTextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authTextDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: getTextStyle(
                          fontSize: 15,
                          color: AppColors.mutedText,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 27.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.asset(
              imagePath,
              width: 300.w,
              height: 242.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 29.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: getTextStyle(
              fontSize: 18.2,
              fontWeight: FontWeight.w500,
              color: AppColors.authTextDark,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: getTextStyle(fontSize: 14.6, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
