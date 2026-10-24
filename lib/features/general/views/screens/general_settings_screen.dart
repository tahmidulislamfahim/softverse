import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/app_routes.dart';
import '../../controller/general_controller.dart';
import '../../widgets/language_picker.dart';

class GeneralSettingsScreen extends GetView<GeneralController> {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);
    final fieldHeight = isLand ? 44.0 : 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: AppResponsive.appBarHeight(context),
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: AppResponsive.appBarIconSize(context),
          ),
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
          'General'.tr,
          style: getTextStyle(
            fontSize: AppResponsive.appBarTitleSize(context),
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: isLand ? 12.h : 16.h,
          ),
          child: ResponsiveCenter(
            maxWidth: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Use camera to scan barcodes'.tr,
                        style: getTextStyle(
                          fontSize: 14.6,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onboardingBackground,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    Obx(
                      () => Switch(
                        value: controller.cameraScanEnabled.value,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.onboardingBackground,
                        inactiveTrackColor: AppColors.toggleTrackOff,
                        onChanged: controller.toggleCameraScan,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLand ? 8.h : 14.h),
                GestureDetector(
                  onTap: () =>
                      Get.toNamed(AppRoute.getHomeScreenItemLayoutScreen()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Home screen item layout'.tr,
                        style: getTextStyle(
                          fontSize: 14.6,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onboardingBackground,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: fieldHeight,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Obx(
                          () => Text(
                            controller.homeScreenLayoutLabel,
                            style: getTextStyle(
                              fontSize: 14.6,
                              color: AppColors.chipInactiveText,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isLand ? 10.h : 16.h),
                Text(
                  'Language'.tr,
                  style: getTextStyle(
                    fontSize: 14.6,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onboardingBackground,
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(height: 6.h),
                Obx(
                  () => GestureDetector(
                    onTap: () async {
                      final result = await showLanguagePicker(
                        context: context,
                        selected: controller.language.value,
                      );
                      if (result != null) {
                        controller.selectLanguage(result);
                      }
                    },
                    child: Container(
                      height: fieldHeight,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.chipBackground,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.language.value.tr,
                              style: getTextStyle(
                                fontSize: 14.6,
                                color: AppColors.chipInactiveText,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          Icon(
                            Iconsax.arrow_down_1,
                            size: 20.sp,
                            color: AppColors.chipInactiveText,
                          ),
                        ],
                      ),
                    ),
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
