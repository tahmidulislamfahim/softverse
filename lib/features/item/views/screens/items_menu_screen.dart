import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../controller/items_menu_controller.dart';
import '../../widgets/item_menu_tile.dart';

class ItemsMenuScreen extends GetView<ItemsMenuController> {
  const ItemsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLand = AppResponsive.isLandscape(context);
    final tiles = <Widget>[
      if (controller.canEditProducts)
        ItemMenuTile(
          icon: Iconsax.task_square,
          label: 'Create Items',
          onTap: controller.openCreateItems,
        ),
      if (controller.canEditCategories)
        ItemMenuTile(
          icon: Iconsax.category,
          label: 'Category',
          onTap: controller.openCategory,
        ),
      ItemMenuTile(
        icon: Iconsax.edit_2,
        label: 'Modifiers',
        onTap: controller.openModifiers,
      ),
      ItemMenuTile(
        icon: Iconsax.tag,
        label: 'Discounts',
        onTap: controller.openDiscounts,
      ),
    ];

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
          'Items',
          style: getTextStyle(
            fontSize: AppResponsive.appBarTitleSize(context),
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
            vertical: isLand ? 12.h : 16.h,
          ),
          child: ResponsiveCenter(
            maxWidth: 580,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLand) ...[
                  for (int i = 0; i < tiles.length; i += 2) ...[
                    if (i > 0) SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(child: tiles[i]),
                        SizedBox(width: 12.w),
                        if (i + 1 < tiles.length)
                          Expanded(child: tiles[i + 1])
                        else
                          const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ],
                ] else ...[
                  for (int i = 0; i < tiles.length; i++) ...[
                    if (i > 0) SizedBox(height: 8.h),
                    tiles[i],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
