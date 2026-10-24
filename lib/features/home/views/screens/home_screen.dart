import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/common/widgets/till_identity_title.dart';

import '../../../../core/common/styles/global_text_style.dart';
import '../../../../core/common/widgets/app_nav_drawer.dart';
import '../../../../core/common/widgets/floating_icon_button.dart';
import '../../../../core/services/feature_settings.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../general/controller/general_controller.dart';
import '../../controller/home_controller.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/order_summary_card.dart';
import '../../widgets/order_tab_selector.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/product_row.dart';
import '../../widgets/table_order_card.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDualPane = AppResponsive.isDualPane(context);
    final iconSize = AppResponsive.appBarIconSize(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppNavDrawer(),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: AppResponsive.appBarHeight(context),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
        title: const TillIdentityTitle(),
        actions: [
          Obx(
            () => FeatureSettings.isEnabled('open_order')
                ? IconButton(
                    onPressed: controller.openPendingOrders,
                    icon: Icon(
                      Iconsax.clock,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Icon(Iconsax.notification, color: Colors.white, size: iconSize),
          SizedBox(width: isDualPane ? 12 : 16.w),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            isDualPane
                ? _buildLandscapeBody(context)
                : _buildPortraitBody(context),
            Obx(
              () => controller.isOrderTabSelected.value
                  ? Positioned(
                      right: 16.w,
                      bottom: 16.h,
                      child: Column(
                        children: [
                          FloatingIconButton(
                            icon: Iconsax.search_normal,
                            tooltip: 'Search products',
                            backgroundColor: AppColors.chipBackground,
                            iconColor: AppColors.onboardingBackground,
                            onTap: controller.openSearch,
                          ),
                          SizedBox(height: 15.h),
                          FloatingIconButton(
                            icon: Iconsax.scan,
                            tooltip: 'Scan item barcode',
                            backgroundColor: AppColors.onboardingBackground,
                            iconColor: Colors.white,
                            onTap: controller.openScan,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => FeatureSettings.isEnabled('table_options')
              ? Padding(
                  padding: EdgeInsets.all(16.w),
                  child: OrderTabSelector(
                    isOrderSelected: controller.isOrderTabSelected.value,
                    onOrderTap: controller.selectOrderTab,
                    onTableTap: controller.selectTableTab,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Obx(
            () =>
                controller.isOrderTabSelected.value ||
                    !FeatureSettings.isEnabled('table_options')
                ? _OrderTabBody(controller: controller)
                : _TableTabBody(controller: controller),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeBody(BuildContext context) {
    return Obx(() {
      final showTableTab =
          FeatureSettings.isEnabled('table_options') &&
          !controller.isOrderTabSelected.value;

      if (showTableTab) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: OrderTabSelector(
                isOrderSelected: controller.isOrderTabSelected.value,
                onOrderTap: controller.selectOrderTab,
                onTableTap: controller.selectTableTab,
              ),
            ),
            Expanded(child: _TableTabBody(controller: controller)),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Pane: Catalog categories & scrollable products
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Obx(
                    () => CategoryTabs(
                      categories: controller.categories,
                      selectedIndex: controller.selectedCategoryIndex.value,
                      onSelected: controller.selectCategory,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.forceSync,
                    child: _ProductGridOrList(
                      controller: controller,
                      bottomPadding: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.cardBorder,
          ),
          // Right Pane: Order Cart & Checkout Actions
          SizedBox(
            width: 330,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (FeatureSettings.isEnabled('table_options'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OrderTabSelector(
                        isOrderSelected: controller.isOrderTabSelected.value,
                        onOrderTap: controller.selectOrderTab,
                        onTableTap: controller.selectTableTab,
                      ),
                    ),
                  Obx(
                    () => OrderSummaryCard(
                      orderId: controller.orderId,
                      itemCount: controller.orderItemCount,
                      total: controller.orderTotal,
                      onCheckout: controller.checkout,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _OrderTabBody extends StatelessWidget {
  final HomeController controller;

  const _OrderTabBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
          child: Obx(
            () => OrderSummaryCard(
              orderId: controller.orderId,
              itemCount: controller.orderItemCount,
              total: controller.orderTotal,
              onCheckout: controller.checkout,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Obx(
            () => CategoryTabs(
              categories: controller.categories,
              selectedIndex: controller.selectedCategoryIndex.value,
              onSelected: controller.selectCategory,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.forceSync,
            child: _ProductGridOrList(
              controller: controller,
              bottomPadding: 96.h,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductGridOrList extends StatelessWidget {
  final HomeController controller;
  final double bottomPadding;

  const _ProductGridOrList({
    required this.controller,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottomPadding),
          physics: const AlwaysScrollableScrollPhysics(),
          child: GetX<HomeController>(
            builder: (homeController) {
              final generalController = Get.find<GeneralController>();
              final products = homeController.visibleProducts;
              if (products.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: const Center(child: Text('No items found')),
                );
              }
              if (generalController.homeScreenLayout.value ==
                  HomeScreenLayout.grid) {
                final crossAxisCount = AppResponsive.gridAxisCountForWidth(
                  constraints.maxWidth,
                  itemWidth: 165,
                  min: 2,
                  max: 6,
                );
                return GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductGridCard(
                      product: product,
                      onAdd: () => homeController.addToCart(product),
                    );
                  },
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: products
                    .map(
                      (product) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: ProductRow(
                          product: product,
                          onAdd: () => homeController.addToCart(product),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }
}

class _TableTabBody extends StatelessWidget {
  final HomeController controller;

  const _TableTabBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.forceSync,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Obx(() {
            final tables = controller.visibleTableOrders;
            if (tables.isEmpty) {
              return SizedBox(
                height: 220.h,
                child: Center(
                  child: Text(
                    'No table found',
                    style: getTextStyle(
                      fontSize: 16.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.chipInactiveText,
                    ),
                  ),
                ),
              );
            }
            final isWide = AppResponsive.isWide(context);
            if (isWide) {
              return Wrap(
                spacing: 16.w,
                runSpacing: 16.h,
                children: tables
                    .map(
                      (tableOrder) => SizedBox(
                        width: 380,
                        child: TableOrderCard(
                          tableOrder: tableOrder,
                          onOpenOrder: () =>
                              controller.openTableOrder(tableOrder),
                        ),
                      ),
                    )
                    .toList(),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: tables
                  .map(
                    (tableOrder) => Padding(
                      padding: EdgeInsets.only(bottom: 24.h),
                      child: TableOrderCard(
                        tableOrder: tableOrder,
                        onOpenOrder: () =>
                            controller.openTableOrder(tableOrder),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}
