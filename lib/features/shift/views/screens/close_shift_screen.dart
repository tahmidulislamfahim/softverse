import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/dashed_divider.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/helpers/app_helper.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/close_shift_controller.dart';

class CloseShiftScreen extends GetView<CloseShiftController> {
  const CloseShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);
    final iconSize = AppResponsive.appBarIconSize(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: AppResponsive.appBarHeight(context),
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.posHeaderStart, AppColors.posHeaderEnd],
            ),
          ),
        ),
        title: Text(
          'Close shift',
          style: getTextStyle(
            fontSize: isLand ? 16.4 : 21.9,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: ResponsiveCenter(
            maxWidth: 540,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                      label: 'Expected cash amount',
                      value:
                          AppHelperFunctions.formatCurrency(controller.shift.expectedCashAmount),
                    ),
                    SizedBox(height: 6.h),
                    const DashedDivider(),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actual cash amount',
                          style: getTextStyle(
                            fontSize: 14.6,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          height: 36.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          alignment: Alignment.center,
                          color: Colors.white,
                          child: Text(
                            AppHelperFunctions.formatCurrency(controller.shift.expectedCashAmount),
                            style: getTextStyle(
                              fontSize: 14.6,
                              color: AppColors.authTextDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    const DashedDivider(),
                    SizedBox(height: 6.h),
                    _Row(
                      label: 'Difference',
                      value:
                          AppHelperFunctions.formatCurrency(controller.difference),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: AppResponsive.isLandscape(context) ? 16.h : 32.h,
              ),
              Center(
                child: PrimaryButton(
                  label: 'CLOSE SHIFT',
                  onPressed: controller.closeShift,
                  backgroundColor: AppColors.dangerRed,
                  textColor: Colors.white,
                  width: 180,
                  height: AppResponsive.isLandscape(context) ? 44.0 : 50.0,
                  fontSize: 15,
                  borderRadius: 10,
                  letterSpacing: 0.16,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
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
            fontWeight: emphasize ? FontWeight.w500 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: getTextStyle(
            fontSize: emphasize ? 16.4 : 14.6,
            fontWeight: emphasize ? FontWeight.w500 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
