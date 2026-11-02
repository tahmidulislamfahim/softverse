import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/product_image.dart';
import '../../../../core/services/feature_settings.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/helpers/app_helper.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/item_detail_controller.dart';
import '../../widgets/barcode_graphic.dart';
import '../../widgets/date_field_row.dart';
import '../../widgets/labeled_row.dart';
import '../../widgets/modifier_section.dart';
import '../../widgets/toggle_field_row.dart';

class ItemDetailScreen extends GetView<ItemDetailController> {
  const ItemDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: Obx(
          () => Text(
            controller.product.name,
            style: getTextStyle(
              fontSize: AppResponsive.appBarTitleSize(context),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.openEdit,
            icon: Icon(
              Iconsax.edit,
              color: Colors.white,
              size: AppResponsive.appBarIconSize(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: ResponsiveCenter(
            maxWidth: 560,
            child: Obx(
              () {
                final product = controller.product;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 16.h),
                    Center(
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        size: 109,
                        borderRadius: 12,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: getTextStyle(
                        fontSize: 14.6,
                        fontWeight: FontWeight.w500,
                        color: AppColors.authTextDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      product.sku,
                      textAlign: TextAlign.center,
                      style: getTextStyle(
                        fontSize: 12.8,
                        color: AppColors.onboardingBackground,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    LabeledRow(
                      label: 'Sold by',
                      value: controller.soldBy.value,
                    ),
                    LabeledRow(
                      label: 'Price',
                      value: AppHelperFunctions.formatCurrency(product.price),
                    ),
                    LabeledRow(
                      label: 'Cost',
                      value: AppHelperFunctions.formatCurrency(product.cost),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Barcode',
                                style: getTextStyle(
                                  fontSize: 16.4,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onboardingBackground,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                product.barcode,
                                style: getTextStyle(
                                  fontSize: 12.8,
                                  color: AppColors.authTextDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const BarcodeGraphic(),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    LabeledRow(
                      label: 'Stock tracking',
                      value: product.trackStock ? 'On' : 'Off',
                    ),
                    if (product.trackStock) ...[
                      LabeledRow(
                        label: 'Stock status',
                        value: product.stockLabel,
                      ),
                      LabeledRow(
                        label: 'Low stock threshold',
                        value: '${product.lowStockThreshold}',
                      ),
                    ],
                    SizedBox(height: 16.h),
                    ModifierSection(
                      group: controller.modifierGroup.value,
                      enabled: controller.modifierEnabled.value,
                      onEnabledChanged: (_) => controller.toggleModifier(),
                      selectedOptionIndex:
                          controller.selectedModifierOptionIndex.value,
                      onOptionSelected: controller.selectModifierOption,
                    ),
                    if (FeatureSettings.isEnabled(
                      'product_expiration_information',
                    )) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'Expire Date',
                        style: getTextStyle(
                          fontSize: 16.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onboardingBackground,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ToggleFieldRow(
                        label: 'Track Date',
                        value: controller.trackExpiryDate.value,
                        onChanged: (_) => controller.toggleTrackExpiryDate(),
                        boxed: true,
                      ),
                      if (controller.trackExpiryDate.value) ...[
                        if (controller.manufacturingDate.value.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Text(
                            'Manufacturing Date',
                            style: getTextStyle(
                              fontSize: 16.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onboardingBackground,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          DateFieldRow(
                            value: controller.manufacturingDate.value,
                          ),
                        ],
                        if (controller.expireDate.value.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Text(
                            'Expire Date',
                            style: getTextStyle(
                              fontSize: 16.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onboardingBackground,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          DateFieldRow(value: controller.expireDate.value),
                        ],
                        if (controller.expirationAlertQuantity.value !=
                            null) ...[
                          SizedBox(height: 12.h),
                          LabeledRow(
                            label: 'Expiration alert quantity',
                            value:
                                '${controller.expirationAlertQuantity.value}',
                          ),
                        ],
                        SizedBox(height: 8.h),
                        Text(
                          'Quantity at which you will be notified about Expire Date',
                          style: getTextStyle(
                            fontSize: 12.8,
                            color: AppColors.chipInactiveText,
                          ),
                        ),
                      ],
                    ],
                    SizedBox(height: 16.h),
                    ToggleFieldRow(
                      label: 'Activity',
                      value: controller.activityEnabled.value,
                      onChanged: (_) => controller.toggleActivity(),
                    ),
                    SizedBox(height: 16.h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
