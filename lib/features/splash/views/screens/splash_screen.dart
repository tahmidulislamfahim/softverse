import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/theme/app_colors_extension.dart';
import '../../controller/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.cardBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 180),
          child: Image.asset(
            'assets/logo/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
