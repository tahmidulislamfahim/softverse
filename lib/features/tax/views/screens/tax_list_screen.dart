import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/app_routes.dart';
import '../../controller/tax_controller.dart';
import '../../widgets/tax_list_tile.dart';

class TaxListScreen extends GetView<TaxController> {
  const TaxListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);

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
          'TAX',
          style: getTextStyle(
            fontSize: AppResponsive.appBarTitleSize(context),
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.taxes.isEmpty) {
                return Center(
                  child: Text(
                    'No taxes found.',
                    style: getTextStyle(
                      fontSize: 16.4,
                      color: AppColors.onboardingBackground,
                    ),
                  ),
                );
              }
              return ResponsiveCenter(
                maxWidth: 580,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    16.w,
                    16.w,
                    isLand ? 90.0 : 90.h,
                  ),
                  itemCount: controller.taxes.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final tax = controller.taxes[index];
                    return TaxListTile(
                      tax: tax,
                      onTap: () => Get.toNamed(
                        AppRoute.getEditTaxScreen(),
                        arguments: tax.id,
                      ),
                    );
                  },
                ),
              );
            }),
            Positioned(
              right: 16.w,
              bottom: 16.h,
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoute.getAddTaxScreen()),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: const BoxDecoration(
                    color: AppColors.onboardingBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.add, color: Colors.white, size: 24.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
