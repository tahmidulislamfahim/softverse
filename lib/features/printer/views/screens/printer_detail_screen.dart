import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/helpers/app_helper.dart';
import '../../../../core/utils/responsive.dart';
import '../../../inventory/widgets/toggle_field_row.dart';
import '../../controller/printer_controller.dart';
import '../../models/printer_model.dart';
import '../../widgets/printer_select_row.dart';

class PrinterDetailScreen extends GetView<PrinterController> {
  const PrinterDetailScreen({super.key});

  String get _printerId => Get.arguments as String;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final printer = controller.printers.firstWhereOrNull(
        (p) => p.id == _printerId,
      );

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
            printer?.printerModel ?? 'Printer',
            style: getTextStyle(
              fontSize: AppResponsive.appBarTitleSize(context),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: printer == null
              ? const SizedBox.shrink()
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: AppResponsive.isLandscape(context) ? 10.h : 16.h,
                  ),
                  child: ResponsiveCenter(
                    maxWidth: 520,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Icon(
                            Iconsax.printer,
                            size: AppResponsive.isLandscape(context)
                                ? 46.0
                                : 70.0,
                            color: AppColors.onboardingBackground,
                          ),
                        ),
                        SizedBox(
                          height: AppResponsive.isLandscape(context)
                              ? 4.h
                              : 8.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: printer.isConnected || printer.isVirtual
                                    ? AppColors.stockBadgeText
                                    : AppColors.chipInactiveText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              printer.isVirtual
                                  ? 'Ready (Virtual)'
                                  : printer.isConnected
                                  ? 'Connected'
                                  : 'Disconnected',
                              style: getTextStyle(
                                fontSize: 14.6,
                                color: AppColors.chipInactiveText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: AppResponsive.isLandscape(context)
                              ? 10.h
                              : 16.h,
                        ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(label: 'Name', value: printer.name),
                            SizedBox(height: 8.h),
                            _InfoRow(
                              label: 'Printer Model',
                              value: printer.printerModel,
                            ),
                            SizedBox(height: 8.h),
                            _InfoRow(
                              label: 'Connection Type',
                              value: printer.connectionType,
                            ),
                            if (printer.startTime.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              _InfoRow(
                                label: 'Start Time',
                                value: printer.startTime,
                              ),
                            ],
                            if (printer.closeTime.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              _InfoRow(
                                label: 'Close Time',
                                value: printer.closeTime,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ToggleFieldRow(
                        label: 'Print Receipt and Bills',
                        value: printer.printReceiptAndBills,
                        onChanged: (_) =>
                            controller.togglePrintReceiptAndBills(printer.id),
                      ),
                      SizedBox(height: 8.h),
                      ToggleFieldRow(
                        label: 'Print Orders',
                        value: printer.printOrders,
                        onChanged: (_) =>
                            controller.togglePrintOrders(printer.id),
                      ),
                      if (printer.printOrders) ...[
                        SizedBox(height: 8.h),
                        PrinterSelectRow(
                          label: 'Kitchen printer group',
                          value: controller.kitchenGroupName(
                            printer.kitchenGroupId,
                          ),
                          onTap: () async {
                            await controller.fetchKitchenGroups();
                            if (!context.mounted) return;
                            final groups = controller.kitchenGroups;
                            final selected = await showPrinterOptionPicker(
                              context: context,
                              title: 'Kitchen printer group',
                              options: [
                                'All items',
                                ...groups.map((group) => group.name),
                              ],
                              selected: controller.kitchenGroupName(
                                printer.kitchenGroupId,
                              ),
                            );
                            if (selected == null) return;
                            controller.setKitchenGroup(
                              printer.id,
                              groups
                                      .firstWhereOrNull(
                                        (group) => group.name == selected,
                                      )
                                      ?.id ??
                                  '',
                            );
                          },
                        ),
                      ],
                      SizedBox(height: 8.h),
                      PrinterSelectRow(
                        label: 'Paper size',
                        value: printer.paperSize,
                        onTap: () async {
                          final selected = await showPrinterOptionPicker(
                            context: context,
                            title: 'Paper size',
                            options: const ['58mm', '80mm'],
                            selected: printer.paperSize,
                          );
                          if (selected != null) {
                            controller.setPaperSize(printer.id, selected);
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                      PrinterSelectRow(
                        label: 'Print Density',
                        value: printer.printDensity,
                        onTap: () async {
                          final selected = await showPrinterOptionPicker(
                            context: context,
                            title: 'Print Density',
                            options: const ['Light', 'Medium', 'Dark'],
                            selected: printer.printDensity,
                          );
                          if (selected != null) {
                            controller.setPrintDensity(printer.id, selected);
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                      ToggleFieldRow(
                        label: 'Auto Cut',
                        value: printer.autoCut,
                        onChanged: (_) => controller.toggleAutoCut(printer.id),
                      ),
                      SizedBox(height: 8.h),
                      ToggleFieldRow(
                        label: 'Default Printer',
                        value: printer.isDefault,
                        onChanged: (_) => controller.toggleDefault(printer.id),
                      ),
                      SizedBox(
                        height: AppResponsive.isLandscape(context)
                            ? 12.h
                            : 20.h,
                      ),
                      GestureDetector(
                        onTap: () => controller.printTest(printer),
                        child: Container(
                          height: AppResponsive.isLandscape(context)
                              ? 44.0
                              : 50.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.onboardingBackground,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.printer,
                                size: 20.sp,
                                color: AppColors.onboardingBackground,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'PRINT TEST',
                                style: getTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onboardingBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: AppResponsive.isLandscape(context)
                            ? 10.h
                            : 16.h,
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: AppResponsive.isLandscape(context)
                              ? 10.h
                              : 14.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, AppColors.rowGradientEnd],
                          ),
                          border: Border.all(
                            color: AppColors.onboardingBackground,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.sun_1,
                              size: 20.sp,
                              color: AppColors.onboardingBackground,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tips',
                                    style: getTextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onboardingBackground,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    printer.isVirtual
                                        ? 'Virtual prints open as an on-screen preview; no hardware is required.'
                                        : 'Make sure the printer is powered on and paper is loaded properly',
                                    style: getTextStyle(
                                      fontSize: 11,
                                      color: AppColors.chipInactiveText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: AppResponsive.isLandscape(context)
                            ? 16.h
                            : 32.h,
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () => _confirmRemove(context, printer),
                          child: Container(
                            width: 180,
                            height: AppResponsive.isLandscape(context)
                                ? 44.0
                                : 50.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.dangerRed,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'Remove',
                              style: getTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
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
    });
  }

  void _confirmRemove(BuildContext context, PrinterModel printer) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove printer?'),
        content: Text(
          'This will remove ${printer.printerModel} from your printer list.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.removePrinter(printer.id);
              Get.back();
              Get.back();
              Future<void>.delayed(const Duration(milliseconds: 120), () {
                AppHelperFunctions.showSuccessSnackBar('Printer removed.');
              });
            },
            child: Text('Remove', style: TextStyle(color: AppColors.dangerRed)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 144.w,
          child: Text(
            label,
            style: getTextStyle(
              fontSize: 14.6,
              color: AppColors.chipInactiveText,
            ),
          ),
        ),
        Text(
          ': $value',
          style: getTextStyle(
            fontSize: 14.6,
            color: AppColors.onboardingBackground,
          ),
        ),
      ],
    );
  }
}
