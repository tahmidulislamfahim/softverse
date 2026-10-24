import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/app_back_button.dart';
import '../../../../core/common/widgets/icon_bubble.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/common/widgets/step_progress_indicator.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/auth_controller.dart';

class EnterOtpScreen extends GetView<AuthController> {
  const EnterOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: isLand ? 10.h : 16.h,
          ),
          child: ResponsiveCenter(
            maxWidth: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isLand ? 8.h : 20.h),
                const AppBackButton(),
                SizedBox(height: isLand ? 10.h : 20.h),
                const StepProgressIndicator(stepCount: 3, activeIndex: 1),
                SizedBox(height: isLand ? 12.h : 36.h),
                Center(
                  child: IconBubble(
                    imagePath: 'assets/icon/mail.png',
                    backgroundColor: AppColors.iconBubbleBlue,
                  ),
                ),
                SizedBox(height: isLand ? 12.h : 24.h),
                Text(
                  'Enter OTP',
                  textAlign: TextAlign.center,
                  style: getTextStyle(
                    fontSize: isLand ? 22 : 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextDark,
                  ),
                ),
                SizedBox(height: isLand ? 8.h : 12.h),
                Text(
                  'Enter the OTP code we just sent you on your registered Email/Phone number',
                  textAlign: TextAlign.center,
                  style: getTextStyle(
                    fontSize: isLand ? 12.0 : 12.8,
                    color: AppColors.mutedText,
                  ),
                ),
                SizedBox(height: isLand ? 16.h : 28.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: isLand ? 42.0 : 46.0,
                      height: isLand ? 48.0 : 58.0,
                      margin: EdgeInsets.symmetric(
                        horizontal: isLand ? 4.w : 5.w,
                      ),
                      child: TextField(
                        controller: controller.otpControllers[index],
                        focusNode: controller.otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: getTextStyle(
                          fontSize: isLand ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authTextDark,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) =>
                            controller.onOtpChanged(index, value),
                      ),
                    );
                  }),
                ),
                SizedBox(height: isLand ? 14.h : 22.h),
                Obx(
                  () => Column(
                    children: [
                      LinearProgressIndicator(
                        value: controller.otpSecondsLeft.value / 120,
                        minHeight: 4.h,
                        borderRadius: BorderRadius.circular(99.r),
                        color: AppColors.onboardingBackground,
                        backgroundColor: AppColors.fieldBackground,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'OTP expires in ${controller.otpTimerLabel}',
                        textAlign: TextAlign.center,
                        style: getTextStyle(
                          fontSize: 11.9,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isLand ? 14.h : 22.h),
                Obx(
                  () => PrimaryButton(
                    label: controller.currentOtpFlow.value == OtpFlow.signup
                        ? 'Verify Account'
                        : 'Reset Password',
                    isLoading: controller.isOtpSubmitting.value,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    textColor: Colors.white,
                    height: isLand ? 46 : 52,
                    borderRadius: 12,
                    fontSize: 14.6,
                    onPressed: controller.submitOtp,
                  ),
                ),
                SizedBox(height: 15.h),
                Obx(
                  () => GestureDetector(
                    onTap: controller.canResendOtp
                        ? controller.resendOtp
                        : null,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Didn't get OTP? ",
                            style: getTextStyle(
                              fontSize: 11.9,
                              color: AppColors.helperText,
                            ),
                          ),
                          TextSpan(
                            text: controller.isResendingOtp.value
                                ? 'Sending...'
                                : 'Resend OTP',
                            style: getTextStyle(
                              fontSize: 11.9,
                              color: controller.canResendOtp
                                  ? AppColors.authLink
                                  : AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
