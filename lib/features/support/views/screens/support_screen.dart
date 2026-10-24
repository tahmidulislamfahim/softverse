import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/app_text_field.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/support_controller.dart';

class SupportScreen extends GetView<SupportController> {
  const SupportScreen({super.key});

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
          'Support',
          style: getTextStyle(
            fontSize: AppResponsive.appBarTitleSize(context),
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: isLand
            ? ResponsiveCenter(
                maxWidth: 900,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFaq(context)),
                      SizedBox(width: 20.w),
                      Expanded(child: _buildContactForm(context, isLand: true)),
                    ],
                  ),
                ),
              )
            : ResponsiveCenter(
                maxWidth: 540,
                child: ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    _buildFaq(context),
                    SizedBox(height: 24.h),
                    _buildContactForm(context, isLand: false),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFaq(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently asked questions',
          style: getTextStyle(fontSize: 15.2, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Obx(() {
          if (controller.isLoadingFaqs.value && controller.faqs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Column(
            children: [
              for (final faq in controller.faqs)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      faq.question,
                      style: getTextStyle(
                        fontSize: 14.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Text(
                            faq.answer,
                            style: getTextStyle(
                              fontSize: 13.6,
                              color: AppColors.chipInactiveText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildContactForm(BuildContext context, {required bool isLand}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact support',
          style: getTextStyle(fontSize: 15.2, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: isLand ? 8.h : 12.h),
        AppTextField(
          label: 'Email',
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          borderStyle: AppTextFieldBorder.outline,
        ),
        SizedBox(height: isLand ? 8.h : 12.h),
        AppTextField(
          label: 'Contact number',
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          borderStyle: AppTextFieldBorder.outline,
        ),
        SizedBox(height: isLand ? 8.h : 12.h),
        AppTextField(
          label: 'Message',
          hintText: 'Describe the problem',
          controller: controller.messageController,
          maxLines: isLand ? 3 : 5,
          borderStyle: AppTextFieldBorder.outline,
        ),
        SizedBox(height: isLand ? 12.h : 20.h),
        Obx(
          () => PrimaryButton(
            label: 'Send',
            isLoading: controller.isSending.value,
            onPressed: controller.submit,
            backgroundColor: AppColors.onboardingBackground,
            textColor: Colors.white,
            width: isLand ? 180 : double.infinity,
            height: isLand ? 44 : 50,
            borderRadius: 10,
          ),
        ),
      ],
    );
  }
}
