import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/common/widgets/product_image.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/edit_customer_controller.dart';
import '../../widgets/customer_form_field.dart';

class EditCustomerScreen extends GetView<EditCustomerController> {
  const EditCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          controller.customer.name,
          style: getTextStyle(
            fontSize: 16.4,
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
            vertical: AppResponsive.isLandscape(context) ? 10.h : 16.h,
          ),
          child: ResponsiveCenter(
            maxWidth: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Obx(
                  () => GestureDetector(
                    onTap: controller.choosePhoto,
                    child: controller.selectedImage.value == null
                        ? ProductImage(
                            imageUrl: controller.customer.imageUrl,
                            size: AppResponsive.isLandscape(context) ? 60 : 80,
                            borderRadius: AppResponsive.isLandscape(context)
                                ? 30
                                : 40,
                          )
                        : Container(
                            width: AppResponsive.isLandscape(context)
                                ? 60.0
                                : 80.0,
                            height: AppResponsive.isLandscape(context)
                                ? 60.0
                                : 80.0,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Image.file(
                              controller.selectedImage.value!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Iconsax.image,
                                    size: AppResponsive.isLandscape(context)
                                        ? 24.sp
                                        : 32.sp,
                                    color: AppColors.chipInactiveText,
                                  ),
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: AppResponsive.isLandscape(context) ? 14.h : 28.h,
              ),
              CustomerFormField(
                label: 'Name',
                controller: controller.nameController,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Email',
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Phone',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Address',
                controller: controller.addressController,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'City',
                controller: controller.cityController,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Region',
                controller: controller.regionController,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Postal Code',
                controller: controller.postalCodeController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Country',
                controller: controller.countryController,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Customer code',
                controller: controller.customerCodeController,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Credit Limit',
                controller: controller.creditLimitController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
              CustomerFormField(
                label: 'Note',
                controller: controller.noteController,
                maxLines: AppResponsive.isLandscape(context) ? 3 : 5,
              ),
              SizedBox(
                height: AppResponsive.isLandscape(context) ? 16.h : 32.h,
              ),
              Center(
                child: Obx(
                  () => PrimaryButton(
                    label: controller.isSaving.value ? 'Saving...' : 'Save',
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.save,
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    textColor: Colors.white,
                    width: 180,
                    height: AppResponsive.isLandscape(context) ? 44.0 : 50.0,
                    fontSize: 15,
                    borderRadius: 10,
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
