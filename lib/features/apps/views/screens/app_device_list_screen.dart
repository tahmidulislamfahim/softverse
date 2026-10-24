import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/apps_controller.dart';
import '../../models/app_device_model.dart';
import '../../widgets/app_device_list_tile.dart';

class AppDeviceListScreen extends GetView<AppsController> {
  const AppDeviceListScreen({super.key});

  AppDeviceType get _type => Get.arguments as AppDeviceType;

  @override
  Widget build(BuildContext context) {
    final type = _type;
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
          type.label,
          style: getTextStyle(
            fontSize: AppResponsive.appBarTitleSize(context),
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final ips = controller.connectedIpsOfType(type);
          if (ips.isEmpty) {
            return Center(
              child: Text(
                'No ${type.label} device connected right now.',
                textAlign: TextAlign.center,
                style: getTextStyle(
                  fontSize: 14.6,
                  color: AppColors.chipInactiveText,
                ),
              ),
            );
          }
          final isLand = AppResponsive.isLandscape(context);
          return ResponsiveCenter(
            maxWidth: 520,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: isLand ? 10.h : 16.h,
              ),
              itemCount: ips.length,
              separatorBuilder: (_, _) => SizedBox(height: isLand ? 8.h : 12.h),
              itemBuilder: (context, index) =>
                  AppDeviceListTile(type: type, ipAddress: ips[index]),
            ),
          );
        }),
      ),
    );
  }
}
