import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/widgets/till_identity_title.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/app_nav_drawer.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/services/feature_settings.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/more_controller.dart';
import '../../widgets/more_menu_tile.dart';
import '../../widgets/more_profile_card.dart';

class MoreScreen extends GetView<MoreController> {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iconSize = AppResponsive.appBarIconSize(context);

    final isLand = AppResponsive.isLandscape(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppNavDrawer(),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: AppResponsive.appBarHeight(context),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
        titleSpacing: 16.w,
        title: const TillIdentityTitle(),
        actions: [
          Icon(Iconsax.mobile, color: Colors.white, size: iconSize),
          SizedBox(width: 15.w),
          Icon(Iconsax.notification, color: Colors.white, size: iconSize),
          SizedBox(width: 16.w),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: isLand ? 10.h : 16.h,
          ),
          child: ResponsiveCenter(
            maxWidth: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => MoreProfileCard(
                    name: controller.profileName,
                    role: controller.profileRole,
                    posLabel: controller.posLabel,
                  ),
                ),
                SizedBox(height: isLand ? 10.h : 16.h),
                if (isLand) ...[
                  Obx(() {
                    final hasShift = FeatureSettings.isEnabled('shifts');
                    final hasTables = FeatureSettings.isEnabled('table_options');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (hasShift) ...[
                              Expanded(
                                child: MoreMenuTile(
                                  icon: Iconsax.clock,
                                  label: 'Shift'.tr,
                                  onTap: controller.openShift,
                                ),
                              ),
                              SizedBox(width: 12.w),
                            ],
                            Expanded(
                              child: MoreMenuTile(
                                icon: Iconsax.task_square,
                                label: 'Item'.tr,
                                onTap: controller.openItem,
                              ),
                            ),
                            if (!hasShift) ...[
                              SizedBox(width: 12.w),
                              Expanded(
                                child: MoreMenuTile(
                                  icon: Iconsax.user,
                                  label: 'Customer'.tr,
                                  onTap: controller.openCustomer,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasShift || hasTables) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              if (hasTables) ...[
                                Expanded(
                                  child: MoreMenuTile(
                                    icon: Icons.table_restaurant,
                                    label: 'Tables'.tr,
                                    onTap: controller.openTables,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                              ],
                              if (hasShift)
                                Expanded(
                                  child: MoreMenuTile(
                                    icon: Iconsax.user,
                                    label: 'Customer'.tr,
                                    onTap: controller.openCustomer,
                                  ),
                                ),
                              if (!hasShift && hasTables)
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ],
                      ],
                    );
                  }),
                ] else ...[
                  Obx(
                    () => FeatureSettings.isEnabled('shifts')
                        ? MoreMenuTile(
                            icon: Iconsax.clock,
                            label: 'Shift'.tr,
                            onTap: controller.openShift,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => FeatureSettings.isEnabled('shifts')
                        ? SizedBox(height: 12.h)
                        : const SizedBox.shrink(),
                  ),
                  MoreMenuTile(
                    icon: Iconsax.task_square,
                    label: 'Item'.tr,
                    onTap: controller.openItem,
                  ),
                  SizedBox(height: 12.h),
                  Obx(
                    () => FeatureSettings.isEnabled('table_options')
                        ? MoreMenuTile(
                            icon: Icons.table_restaurant,
                            label: 'Tables'.tr,
                            onTap: controller.openTables,
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => FeatureSettings.isEnabled('table_options')
                        ? SizedBox(height: 12.h)
                        : const SizedBox.shrink(),
                  ),
                  MoreMenuTile(
                    icon: Iconsax.user,
                    label: 'Customer'.tr,
                    onTap: controller.openCustomer,
                  ),
                ],
                SizedBox(height: isLand ? 12.h : 20.h),
                Row(
                  children: [
                    Icon(
                      Iconsax.setting_2,
                      size: isLand ? 18.sp : 22.sp,
                      color: AppColors.chipInactiveText,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Settings'.tr,
                      style: getTextStyle(
                        fontSize: isLand ? 13.5 : 14.6,
                        fontWeight: FontWeight.w500,
                        color: AppColors.chipInactiveText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLand ? 8.h : 12.h),
                Row(
                  children: [
                    Expanded(
                      child: MoreMenuTile(
                        icon: Iconsax.printer,
                        label: 'Printer'.tr,
                        centered: true,
                        onTap: controller.openPrinterSettings,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MoreMenuTile(
                        icon: Iconsax.mobile,
                        label: 'Apps'.tr,
                        centered: true,
                        onTap: controller.openAppsSettings,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLand ? 8.h : 12.h),
                Row(
                  children: [
                    Expanded(
                      child: MoreMenuTile(
                        icon: Iconsax.cpu_setting,
                        label: 'General'.tr,
                        centered: true,
                        onTap: controller.openGeneralSettings,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MoreMenuTile(
                        icon: Iconsax.percentage_circle,
                        label: 'Taxes'.tr,
                        centered: true,
                        onTap: controller.openTaxesSettings,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isLand ? 8.h : 16.h),
                if (isLand) ...[
                  Row(
                    children: [
                      Expanded(
                        child: MoreMenuTile(
                          icon: Iconsax.key,
                          label: 'PIN lock'.tr,
                          onTap: controller.openPinSettings,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: MoreMenuTile(
                          icon: Iconsax.headphone,
                          label: 'Supports'.tr,
                          onTap: controller.openSupport,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  MoreMenuTile(
                    icon: Iconsax.key,
                    label: 'PIN lock'.tr,
                    onTap: controller.openPinSettings,
                  ),
                  SizedBox(height: 12.h),
                  MoreMenuTile(
                    icon: Iconsax.headphone,
                    label: 'Supports'.tr,
                    onTap: controller.openSupport,
                  ),
                ],
                SizedBox(height: isLand ? 16.h : 28.h),
                Center(
                  child: PrimaryButton(
                    label: 'Log out'.tr,
                    onPressed: controller.logout,
                    backgroundColor: AppColors.dangerRed,
                    textColor: Colors.white,
                    width: 180,
                    height: isLand ? 44 : 50,
                    fontSize: 15,
                    borderRadius: 10,
                    letterSpacing: 0.08,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
