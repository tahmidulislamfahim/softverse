import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/app_text_field.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/app_lock_controller.dart';
import '../../widgets/pin_keypad.dart';

class AppLockScreen extends GetView<AppLockController> {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Obx(
            () => controller.hasPin.value == false
                ? _SetPinForm(controller: controller)
                : _PinEntry(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _PinEntry extends StatelessWidget {
  final AppLockController controller;

  const _PinEntry({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.isWide(context);

    if (isWide) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.lock,
                        size: 40.sp,
                        color: AppColors.onboardingBackground,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        StorageService.fullName ?? '',
                        style: getTextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Enter your PIN to continue',
                        style: getTextStyle(
                          fontSize: 14,
                          color: AppColors.chipInactiveText,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Obx(
                        () => PinDots(
                          filled: controller.pin.value.length,
                          length: AppLockController.pinLength,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Obx(
                        () => SizedBox(
                          height: 20.h,
                          child: controller.isVerifying.value
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  controller.errorText.value ?? '',
                                  textAlign: TextAlign.center,
                                  style: getTextStyle(
                                    fontSize: 13,
                                    color: AppColors.dangerRed,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 260,
                  color: AppColors.cardBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PinKeypad(
                        onDigit: controller.addDigit,
                        onBackspace: controller.removeDigit,
                      ),
                      SizedBox(height: 12.h),
                      TextButton(
                        onPressed: controller.signOut,
                        child: Text(
                          'Not you? Sign out',
                          style: getTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onboardingBackground,
                          ),
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

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.h),
              Icon(
                Iconsax.lock,
                size: 40.sp,
                color: AppColors.onboardingBackground,
              ),
              SizedBox(height: 16.h),
              Text(
                StorageService.fullName ?? '',
                style: getTextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(
                'Enter your PIN to continue',
                style: getTextStyle(
                  fontSize: 14,
                  color: AppColors.chipInactiveText,
                ),
              ),
              SizedBox(height: 24.h),
              Obx(
                () => PinDots(
                  filled: controller.pin.value.length,
                  length: AppLockController.pinLength,
                ),
              ),
              SizedBox(height: 12.h),
              Obx(
                () => SizedBox(
                  height: 20.h,
                  child: controller.isVerifying.value
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          controller.errorText.value ?? '',
                          textAlign: TextAlign.center,
                          style: getTextStyle(
                            fontSize: 13,
                            color: AppColors.dangerRed,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),
              PinKeypad(
                onDigit: controller.addDigit,
                onBackspace: controller.removeDigit,
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: controller.signOut,
                child: Text(
                  'Not you? Sign out',
                  style: getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onboardingBackground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetPinForm extends StatelessWidget {
  final AppLockController controller;

  const _SetPinForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    final changing = controller.isChangingPin.value;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppResponsive.maxFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24.h),
              Icon(Iconsax.key, size: 40.sp, color: AppColors.onboardingBackground),
              SizedBox(height: 16.h),
              Text(
                changing ? 'Change your PIN' : 'Set a PIN to unlock the app',
                textAlign: TextAlign.center,
                style: getTextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
          SizedBox(height: 6.h),
          Text(
            'The app locks when the screen turns off or it is left unused. '
            'Your PIN unlocks it without signing out.',
            textAlign: TextAlign.center,
            style: getTextStyle(
              fontSize: 13,
              color: AppColors.chipInactiveText,
            ),
          ),
          SizedBox(height: 24.h),
          AppTextField(
            label: 'Your password',
            controller: controller.passwordController,
            obscureText: true,
            backgroundColor: AppColors.fieldBackground,
            borderStyle: AppTextFieldBorder.none,
          ),
          SizedBox(height: 12.h),
          AppTextField(
            label: 'New 4-digit PIN',
            controller: controller.newPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            backgroundColor: AppColors.fieldBackground,
            borderStyle: AppTextFieldBorder.none,
          ),
          SizedBox(height: 12.h),
          AppTextField(
            label: 'Confirm PIN',
            controller: controller.confirmPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            backgroundColor: AppColors.fieldBackground,
            borderStyle: AppTextFieldBorder.none,
          ),
          SizedBox(height: 24.h),
          Obx(
            () => PrimaryButton(
              label: 'Save PIN',
              onPressed: controller.savePin,
              isLoading: controller.isSavingPin.value,
              backgroundColor: AppColors.onboardingBackground,
              textColor: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: changing
                ? controller.cancelChangePin
                : controller.signOut,
            child: Text(
              changing ? 'Cancel' : 'Sign out',
              style: getTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onboardingBackground,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
