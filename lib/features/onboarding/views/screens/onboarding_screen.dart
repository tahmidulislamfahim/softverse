import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.onboardingBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 850 : 420),
                child: isWide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Image.asset(
                                'assets/logo/Logo-white.png',
                                width: 280,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 200,
                            color: Colors.white.withValues(alpha: 0.2),
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PrimaryButton(
                                  label: 'REGISTRATION',
                                  backgroundColor: Colors.white,
                                  textColor: AppColors.onboardingBackground,
                                  height: 51,
                                  fontSize: 16.4,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.08,
                                  onPressed: controller.goToRegistration,
                                ),
                                SizedBox(height: 18.h),
                                PrimaryButton(
                                  label: 'SIGN IN',
                                  backgroundColor: Colors.transparent,
                                  textColor: AppColors.lightBorder,
                                  borderColor: AppColors.lightBorder,
                                  height: 51,
                                  fontSize: 16.4,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.08,
                                  onPressed: controller.goToSignIn,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 32.h),
                          Image.asset(
                            'assets/logo/Logo-white.png',
                            width: 260.w,
                          ),
                          SizedBox(height: 80.h),
                          PrimaryButton(
                            label: 'REGISTRATION',
                            backgroundColor: Colors.white,
                            textColor: AppColors.onboardingBackground,
                            height: 51,
                            fontSize: 16.4,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.08,
                            onPressed: controller.goToRegistration,
                          ),
                          SizedBox(height: 18.h),
                          PrimaryButton(
                            label: 'SIGN IN',
                            backgroundColor: Colors.transparent,
                            textColor: AppColors.lightBorder,
                            borderColor: AppColors.lightBorder,
                            height: 51,
                            fontSize: 16.4,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.08,
                            onPressed: controller.goToSignIn,
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
