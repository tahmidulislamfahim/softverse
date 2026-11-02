import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/primary_button.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/helpers/app_helper.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/invoice_controller.dart';
import '../../widgets/invoice_item_card.dart';
import '../../widgets/payment_type_badge.dart';
import '../../widgets/read_only_bill_card.dart';

class InvoiceScreen extends GetView<InvoiceController> {
  const InvoiceScreen({super.key});

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
        title: Obx(
          () => Text(
            controller.invoiceNumber.value.isNotEmpty
                ? controller.invoiceNumber.value
                : 'Invoice',
            style: getTextStyle(
              fontSize: 16.4,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Obx(() {
            if (controller.isRefunded) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Center(
                  child: Text(
                    'Refunded',
                    style: getTextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
            return Container(
              margin: EdgeInsets.symmetric(vertical: 11.h, horizontal: 4.w),
              child: TextButton(
                onPressed: controller.goToRefund,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.dangerRed,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                child: const Text(
                  'Refund',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            );
          }),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white, size: iconSize),
            tooltip: 'Invoice actions',
            onSelected: (value) {
              switch (value) {
                case 'print':
                  controller.openPrint();
                  break;
                case 'email':
                  controller.openMail();
                  break;
                case 'download':
                  controller.exportPdf();
                  break;
                case 'collect_due':
                  _showCollectDuePaymentDialog(context, controller);
                  break;
                case 'mark_empty':
                  controller.markTableEmpty();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Iconsax.printer, size: 20),
                    SizedBox(width: 10),
                    Text('Print Receipt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'email',
                child: Row(
                  children: [
                    Icon(Iconsax.sms, size: 20),
                    SizedBox(width: 10),
                    Text('Email / Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Iconsax.document_download, size: 20),
                    SizedBox(width: 10),
                    Text('Download PDF'),
                  ],
                ),
              ),
              if (controller.canCollectDuePayment)
                const PopupMenuItem(
                  value: 'collect_due',
                  child: Row(
                    children: [
                      Icon(Iconsax.card_tick, size: 20),
                      SizedBox(width: 10),
                      Text('Collect Due Payment'),
                    ],
                  ),
                ),
              if ((controller.tableId.value ?? '').isNotEmpty)
                const PopupMenuItem(
                  value: 'mark_empty',
                  child: Row(
                    children: [
                      Icon(Icons.table_restaurant, size: 20),
                      SizedBox(width: 10),
                      Text('Mark Table Empty'),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(width: 6.w),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: ResponsiveCenter(
            maxWidth: 580,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Item',
                        style: getTextStyle(
                          fontSize: 16.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.authTextDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Obx(
                        () => Text(
                          controller.formattedDateTime,
                          style: getTextStyle(
                            fontSize: 12.0,
                            color: AppColors.chipInactiveText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(
                    () => PaymentTypeBadge(
                      paymentType: controller.paymentType.value,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Obx(
                () => Column(
                  children: controller.items
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: InvoiceItemCard(item: item),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Bill Amounts',
                style: getTextStyle(
                  fontSize: 16.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.authTextDark,
                ),
              ),
              SizedBox(height: 12.h),
              Obx(
                () => ReadOnlyBillCard(
                  subtotal: controller.subtotal,
                  tax: controller.tax,
                  taxRate: controller.effectiveTaxRate,
                  totalAmount: controller.totalAmount,
                  amountReceived: controller.amountReceived,
                  changeToReturn: controller.changeToReturn,
                ),
              ),
              SizedBox(height: 16.h),
              Obx(
                () => controller.canCollectDuePayment
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: PrimaryButton(
                          label:
                              'Collect Due Payment (${AppHelperFunctions.getFormattedMoney(controller.amountDue)})',
                          onPressed: () =>
                              _showCollectDuePaymentDialog(context, controller),
                          isLoading: controller.isCollectingDuePayment.value,
                          backgroundColor: AppColors.onboardingBackground,
                          textColor: Colors.white,
                          height: 55,
                          fontSize: 16.4,
                          borderRadius: 12,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              PrimaryButton(
                label: 'Done / Return Home',
                onPressed: controller.returnHome,
                backgroundColor: AppColors.onboardingBackground,
                textColor: Colors.white,
                height: 51,
                fontSize: 16.4,
                borderRadius: 12,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

void _showCollectDuePaymentDialog(
  BuildContext context,
  InvoiceController controller,
) {
  final amountController = TextEditingController(
    text: controller.amountDue.toStringAsFixed(2),
  );
  Get.dialog<void>(
    AlertDialog(
      title: const Text('Collect Due Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outstanding balance: ${AppHelperFunctions.getFormattedMoney(controller.amountDue)}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount received',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(amountController.text.trim());
            Get.back();
            if (amount != null) controller.collectDuePayment(amount);
          },
          child: const Text('Collect'),
        ),
      ],
    ),
  );
}
