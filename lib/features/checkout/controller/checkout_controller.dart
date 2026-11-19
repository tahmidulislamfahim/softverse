import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/utils/constants/colors.dart';
import '../../../core/services/cds_cart_sender.dart';
import '../../../core/services/feature_settings.dart';
import '../../../core/services/kds_order_sender.dart';
import '../../../core/services/network_caller.dart';
import '../../../core/services/offline_database_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/helpers/app_helper.dart';
import '../../../core/services/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../store/controller/store_controller.dart';
import '../../customer/controller/customer_controller.dart';
import '../../customer/models/customer_model.dart';
import '../../home/controller/home_controller.dart';
import '../../home/models/product.dart';
import '../../home/models/table_order.dart';
import '../../invoice/controller/invoice_controller.dart';
import '../../main_nav/controller/main_nav_controller.dart';
import '../../printer/controller/printer_controller.dart';
import '../../tax/controller/tax_controller.dart';
import '../../tax/models/tax_model.dart';
import '../../transaction/controller/transaction_controller.dart';
import '../../../core/services/permission_service.dart';
import '../../item/data/discount_repository.dart';
import '../../item/models/discount_rule_model.dart';
import '../models/cart_item.dart';
import '../widgets/discount_picker_sheet.dart';
import '../models/payment_method.dart';

enum PriceAdjustmentMode { modifier, discount }

class CheckoutController extends GetxController {
  final NetworkCaller _networkCaller = NetworkCaller();
  final DiscountRepository _discountRepository = HttpDiscountRepository();
  final KdsOrderSender _kdsOrderSender = KdsOrderSender();
  final CdsCartSender _cdsCartSender = CdsCartSender();
  final activeOrderId = RxnString();
  final activeOrderNumber = ''.obs;
  final activeTableId = RxnString();
  final activeTableName = RxnString();
  final selectedCustomerId = ''.obs;
  final customerName = 'Not Registered'.obs;

  final priceAdjustmentMode = PriceAdjustmentMode.modifier.obs;
  final amountReceived = 0.0.obs;
  final selectedPaymentMethod = 'cash'.obs;
  final splitPayments = <SplitPaymentEntry>[].obs;
  final isSubmittingCheckout = false.obs;
  final amountEditedManually = false.obs;
  final orders = <Map<String, dynamic>>[].obs;
  final pendingOrders = <Map<String, dynamic>>[].obs;
  final isLoadingPendingOrders = false.obs;
  late final amountReceivedController = TextEditingController(
    text: AppHelperFunctions.getFormattedMoney(amountReceived.value),
  );

  final cartItems = <CartItem>[].obs;

  String get orderId =>
      activeOrderNumber.value.isEmpty ? 'New order' : activeOrderNumber.value;

  static const _defaultPaymentMethods = [
    PaymentMethod(
      key: 'cash',
      label: 'Cash',
      parentMethod: 'cash',
      icon: Iconsax.money,
      gradientStart: AppColors.completeBadgeStart,
      gradientEnd: AppColors.completeBadgeEnd,
    ),
    PaymentMethod(
      key: 'card',
      label: 'Card',
      parentMethod: 'card',
      icon: Iconsax.card,
      gradientStart: AppColors.ongoingBadgeStart,
      gradientEnd: AppColors.ongoingBadgeEnd,
    ),
    PaymentMethod(
      key: 'due',
      label: 'Due',
      parentMethod: 'due',
      icon: Iconsax.dollar_circle,
      gradientStart: AppColors.dueStart,
      gradientEnd: AppColors.dueEnd,
    ),
  ];

  final paymentMethods = <PaymentMethod>[..._defaultPaymentMethods].obs;

  List<PaymentMethod> get visiblePaymentMethods => paymentMethods
      .where(
        (method) =>
            _isPaymentMethodEnabled(method.key) &&
            _isPaymentMethodEnabled(method.parentMethod),
      )
      .toList();

  List<PaymentMethod> get splittablePaymentMethods => visiblePaymentMethods
      .where((method) => method.parentMethod != 'due' && method.key != 'due')
      .toList();

  bool get hasSplitPayments => splitPayments.isNotEmpty;

  double get splitPaymentsTotal =>
      splitPayments.fold(0.0, (sum, entry) => sum + entry.amount);

  bool _isPaymentMethodEnabled(String key) => switch (key.toLowerCase()) {
    'due' => FeatureSettings.isEnabled('credit_sales'),
    'installment' => false,
    _ => true,
  };

  @override
  void onInit() {
    super.onInit();
    fetchPaymentTypes();
    fetchOrders();
    loadCustomers();
    if (Get.isRegistered<TaxController>()) {
      Get.find<TaxController>().fetchTaxes();
    }
  }

  double get subtotal {
    double total = 0;
    for (final item in cartItems) {
      total += (item.bundle?.subtotal ?? item.price) * item.quantity;
    }
    return total;
  }

  double get tax {
    if (!Get.isRegistered<TaxController>()) return 0;
    final taxes = Get.find<TaxController>().taxes;
    return cartItems.fold(0.0, (sum, item) {
      final itemId = item.itemId;
      if (itemId == null) return sum;
      final rate = taxes
          .where(
            (tax) =>
                tax.type == TaxType.addedAtCheckout && tax.appliesTo(itemId),
          )
          .fold(0.0, (total, tax) => total + tax.ratePercent);
      return sum + (item.lineSubtotal * rate / 100);
    });
  }

  double get taxRate => subtotal == 0 ? 0 : tax / subtotal;

  /// Order-level discount picked from the business's discount catalog.
  final appliedDiscount = Rxn<DiscountRuleModel>();

  /// Value typed at the till for a catalog discount created without a fixed
  /// amount ("seller decides at the time of sale").
  final appliedDiscountValue = 0.0.obs;

  double get discountAmount {
    final discount = appliedDiscount.value;
    if (discount == null || subtotal <= 0) return 0;
    final value = appliedDiscountValue.value;
    final raw = discount.type == 'amount' ? value : subtotal * value / 100;
    return double.parse(raw.clamp(0, subtotal).toStringAsFixed(2));
  }

  /// Loyalty points the customer spends on this sale (1 point = 1 unit).
  final pointsToUse = 0.0.obs;

  /// Points of the selected customer; usable only on a sale paid now, not
  /// on paying an order that was saved/sent to a table earlier.
  double get availablePoints {
    if (selectedCustomerId.value.isEmpty || activeOrderId.value != null) {
      return 0;
    }
    if (!Get.isRegistered<CustomerController>()) return 0;
    return Get.find<CustomerController>().customers
            .firstWhereOrNull((c) => c.id == selectedCustomerId.value)
            ?.pointsBalance ??
        0;
  }

  double get loyaltyDiscount {
    final room = subtotal - discountAmount;
    if (room <= 0) return 0;
    final used = pointsToUse.value.clamp(0, availablePoints).clamp(0, room);
    return double.parse(used.toStringAsFixed(2));
  }

  void toggleUsePoints() {
    pointsToUse.value = pointsToUse.value > 0
        ? 0
        : (subtotal - discountAmount).clamp(0, availablePoints).toDouble();
  }

  double get totalAmount => subtotal - discountAmount - loyaltyDiscount + tax;

  double get changeToReturn => amountReceived.value - totalAmount;

  void addProduct({
    String? itemId,
    required String name,
    required double price,
    required String imageUrl,
  }) {
    final index = cartItems.indexWhere((item) => item.name == name);
    if (index != -1) {
      cartItems[index] = cartItems[index].copyWith(
        quantity: cartItems[index].quantity + 1,
      );
    } else {
      cartItems.add(
        CartItem(
          itemId: itemId,
          name: name,
          price: price,
          imageUrl: imageUrl,
          quantity: 1,
        ),
      );
    }
    _syncAmountReceivedWithTotal();
    _syncCds();
  }

  void incrementQuantity(int index) {
    cartItems[index] = cartItems[index].copyWith(
      quantity: cartItems[index].quantity + 1,
    );
    _syncAmountReceivedWithTotal();
    _syncCds();
  }

  void decrementQuantity(int index) {
    if (cartItems[index].quantity <= 1) {
      cartItems.removeAt(index);
      _syncAmountReceivedWithTotal();
      _syncCds();
      return;
    }
    cartItems[index] = cartItems[index].copyWith(
      quantity: cartItems[index].quantity - 1,
    );
    _syncAmountReceivedWithTotal();
    _syncCds();
  }

  void setItemQuantity(int index, int newQuantity) {
    if (index < 0 || index >= cartItems.length) return;
    if (newQuantity <= 0) {
      cartItems.removeAt(index);
    } else {
      cartItems[index] = cartItems[index].copyWith(quantity: newQuantity);
    }
    _syncAmountReceivedWithTotal();
    _syncCds();
  }

  void selectModifier() =>
      priceAdjustmentMode.value = PriceAdjustmentMode.modifier;

  void selectDiscount() {
    priceAdjustmentMode.value = PriceAdjustmentMode.discount;
    _openDiscountPicker();
  }

  Future<void> _openDiscountPicker() async {
    final response = await _discountRepository.fetchDiscountRules();
    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }
    final raw = (response.responseData as Map)['discounts'];
    final storeId = StorageService.storeId;
    final discounts = (raw is List ? raw : const [])
        .whereType<Map>()
        .map(
          (json) => DiscountRuleModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .where(
          (d) =>
              d.isActive &&
              (d.storeId == null || storeId == null || d.storeId == storeId),
        )
        .toList();

    final picked = await Get.bottomSheet<DiscountRuleModel>(
      DiscountPickerSheet(
        discounts: discounts,
        appliedId: appliedDiscount.value?.id,
        onRemove: () {
          removeDiscount();
          Get.back();
        },
      ),
      isScrollControlled: true,
    );
    if (picked != null) await _applyDiscount(picked);
  }

  void removeDiscount() {
    appliedDiscount.value = null;
    appliedDiscountValue.value = 0;
    pointsToUse.value = 0;
    _syncAmountReceivedWithTotal();
    _syncCds();
  }

  Future<void> _applyDiscount(DiscountRuleModel discount) async {
    if (discount.restrictedAccess &&
        !PermissionService.has(AppPermission.giveDiscount)) {
      AppHelperFunctions.showErrorSnackBar(
        'You are not allowed to apply this discount.',
      );
      return;
    }
    var value = discount.value;
    if (value <= 0) {
      final entered = await _askDiscountValue(discount);
      if (entered == null || entered <= 0) return;
      value = entered;
    }
    appliedDiscount.value = discount;
    appliedDiscountValue.value = value;
    _syncAmountReceivedWithTotal();
    _syncCds();
  }

  Future<double?> _askDiscountValue(DiscountRuleModel discount) async {
    final input = TextEditingController();
    final result = await Get.dialog<double>(
      AlertDialog(
        title: Text(discount.name),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: discount.type == 'amount' ? 'Amount' : 'Percentage',
            suffixText: discount.type == 'amount' ? null : '%',
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(
              result: double.tryParse(input.text.trim().replaceAll(',', '')),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    input.dispose();
    if (result != null && discount.type != 'amount' && result > 100) {
      AppHelperFunctions.showWarningSnackBar('Percentage cannot exceed 100.');
      return null;
    }
    return result;
  }

  void setAmountReceived(String value) {
    amountEditedManually.value = true;
    final normalized = value.replaceAll(',', '').replaceAll('\$', '');
    amountReceived.value = double.tryParse(normalized) ?? amountReceived.value;
    _syncCds();
  }

  void addCustomer() => Get.toNamed(AppRoute.getAddCustomerScreen());

  Future<void> loadCustomers() async {
    await Get.find<CustomerController>().fetchCustomers();
  }

  void selectCustomerById(String? id) {
    selectedCustomerId.value = id ?? '';
    pointsToUse.value = 0;
    if (selectedCustomerId.value.isEmpty) {
      customerName.value = 'Not Registered';
      _syncCds();
      return;
    }

    final customerController = Get.find<CustomerController>();
    CustomerModel? selected;
    for (final customer in customerController.customers) {
      if (customer.id == selectedCustomerId.value) {
        selected = customer;
        break;
      }
    }
    if (selected == null) return;
    customerController.selectCustomer(selected);
    customerName.value = selected.name.trim().isEmpty
        ? 'Not Registered'
        : selected.name.trim();
    _syncCds();
  }

  Future<void> sendToTable() async {
    if (!isTableOptionsEnabled) return;
    final homeController = Get.find<HomeController>();
    await homeController.fetchTables();
    final availableTables = homeController.availableTables;

    if (availableTables.isEmpty) {
      AppHelperFunctions.showWarningSnackBar('No table found.');
      return;
    }

    final selected = await Get.bottomSheet<TableOrder>(
      _AvailableTableSheet(tables: availableTables),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );

    if (selected == null) {
      AppHelperFunctions.showWarningSnackBar('Select a table first.');
      return;
    }
    await _submitCheckout(
      sendToTable: true,
      tableId: selected.tableId,
      tableName: selected.tableName,
    );
  }

  Future<void> saveOrder() async {
    await _submitCheckout(saveOrder: true);
  }

  void clearOrder({bool silent = false}) {
    cartItems.clear();
    splitPayments.clear();
    activeOrderId.value = null;
    activeOrderNumber.value = '';
    activeTableId.value = null;
    activeTableName.value = null;
    selectedCustomerId.value = '';
    customerName.value = 'Not Registered';
    amountEditedManually.value = false;
    appliedDiscount.value = null;
    appliedDiscountValue.value = 0;
    _syncAmountReceivedWithTotal(force: true);
    if (!silent && FeatureSettings.isEnabled('customer_displays')) {
      _cdsCartSender.clear();
    }
  }

  Future<void> discardActiveOrder() async {
    final id = activeOrderId.value;
    if (id != null) {
      final response = await _networkCaller.deleteRequest(
        ApiConstants.checkoutOrder(id),
      );
      if (!response.isSuccess) {
        AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      } else if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().fetchTables();
      }
    }
    clearOrder();
  }

  void clearSplitPayments() {
    splitPayments.clear();
    _syncAmountReceivedWithTotal(force: true);
  }

  Future<void> openSplitPaymentSheet(BuildContext context) async {
    if (cartItems.isEmpty || totalAmount <= 0) {
      AppHelperFunctions.showWarningSnackBar(
        'Add items to the order before splitting payment.',
      );
      return;
    }
    final methods = splittablePaymentMethods;
    if (methods.isEmpty) {
      AppHelperFunctions.showWarningSnackBar(
        'No payment methods available for split payment.',
      );
      return;
    }

    final initialSplits = splitPayments.isNotEmpty
        ? splitPayments.toList()
        : <SplitPaymentEntry>[
            SplitPaymentEntry(
              methodKey: methods.first.key,
              parentMethod: methods.first.parentMethod,
              label: methods.first.label,
              subMethod: methods.first.subMethod,
              amount: _money(totalAmount / 2),
            ),
            SplitPaymentEntry(
              methodKey: methods.length > 1
                  ? methods[1].key
                  : methods.first.key,
              parentMethod: methods.length > 1
                  ? methods[1].parentMethod
                  : methods.first.parentMethod,
              label: methods.length > 1
                  ? methods[1].label
                  : methods.first.label,
              subMethod: methods.length > 1
                  ? methods[1].subMethod
                  : methods.first.subMethod,
              amount: _money(totalAmount - _money(totalAmount / 2)),
            ),
          ];

    final result = await showModalBottomSheet<List<SplitPaymentEntry>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SplitPaymentSheet(
        totalAmount: _money(totalAmount),
        availableMethods: methods,
        initialSplits: initialSplits,
      ),
    );

    if (result != null && result.isNotEmpty) {
      splitPayments.assignAll(result);
      final totalPaid = result.fold(0.0, (sum, item) => sum + item.amount);
      amountEditedManually.value = true;
      amountReceived.value = _money(totalPaid);
      amountReceivedController.text = AppHelperFunctions.getFormattedMoney(
        amountReceived.value,
      );
      await submitSplitCheckout();
    }
  }

  Future<void> submitSplitCheckout() async {
    if (splitPayments.isEmpty) return;
    if (splitPaymentsTotal + 0.005 < totalAmount) {
      AppHelperFunctions.showWarningSnackBar(
        'Split payment amounts must cover the total amount.',
      );
      return;
    }
    TableOrder? paymentTable;
    if (isTableOptionsEnabled && activeTableId.value == null) {
      paymentTable = await _selectAvailableTable();
      if (paymentTable == null) return;
    }
    await _submitCheckout(
      tableId: paymentTable?.tableId ?? activeTableId.value,
      tableName: paymentTable?.tableName ?? activeTableName.value,
    );
  }

  Future<void> selectPaymentMethod(PaymentMethod method) async {
    if (!_isPaymentMethodEnabled(method.key) ||
        !_isPaymentMethodEnabled(method.parentMethod)) {
      return;
    }

    splitPayments.clear();

    TableOrder? paymentTable;
    if (isTableOptionsEnabled && activeTableId.value == null) {
      paymentTable = await _selectAvailableTable();
      if (paymentTable == null) return;
    }

    selectedPaymentMethod.value = method.key;
    if (method.parentMethod != 'due' && method.key != 'due') {
      await _submitCheckout(
        tableId: paymentTable?.tableId ?? activeTableId.value,
        tableName: paymentTable?.tableName ?? activeTableName.value,
      );
      return;
    }

    final customer = Get.find<CustomerController>().customer.value;
    if (totalAmount > customer.creditLimit) {
      AppHelperFunctions.showErrorSnackBar(
        'Credit sale denied. ${customer.name} has a ${AppHelperFunctions.formatCurrency(customer.creditLimit)} credit limit.',
      );
      return;
    }

    AppHelperFunctions.showSuccessSnackBar('Credit sale is within limit.');
    await _submitCheckout(
      tableId: paymentTable?.tableId ?? activeTableId.value,
      tableName: paymentTable?.tableName ?? activeTableName.value,
    );
  }

  Future<void> openSearch() => Get.find<HomeController>().openSearch();

  Future<void> openScan() => Get.find<HomeController>().openScan();

  void closeCheckout() => Get.find<MainNavController>().changeTab(0);

  Future<void> printEstimate() async {
    if (cartItems.isEmpty) {
      AppHelperFunctions.showWarningSnackBar(
        'Add items before printing an estimate.',
      );
      return;
    }
    await Get.find<PrinterController>().printEstimate(
      orderId: orderId,
      customerName: customerName.value,
      items: cartItems.toList(),
      subtotal: subtotal,
      tax: tax,
      totalAmount: totalAmount,
    );
  }

  Future<void> forceSync() async {
    if (Get.isRegistered<SyncService>()) {
      await Get.find<SyncService>().syncPendingActions();
    }
    await fetchPaymentTypes();
    await fetchOrders();
    AppHelperFunctions.showSuccessSnackBar('Synced');
  }

  Future<void> fetchOrders() async {
    final cached = OfflineDatabaseService.readCache<List<dynamic>>('orders');
    if (cached != null) {
      orders.assignAll(
        cached.map((entry) => Map<String, dynamic>.from(entry as Map)),
      );
    }
    final response = await _networkCaller.getRequest(ApiConstants.checkout);
    if (!response.isSuccess || response.responseData is! List) return;
    final data = List<dynamic>.from(response.responseData as List);
    await OfflineDatabaseService.saveCache('orders', data);
    orders.assignAll(
      data.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)),
    );
  }

  Future<void> fetchPaymentTypes() async {
    final storeId = StorageService.storeId;
    final url = storeId == null || storeId.isEmpty
        ? ApiConstants.paymentTypes
        : '${ApiConstants.paymentTypes}?storeId=${Uri.encodeQueryComponent(storeId)}';
    final response = await _networkCaller.getRequest(url);
    if (!response.isSuccess) return;

    final rawList = response.responseData is List
        ? List<dynamic>.from(response.responseData as List)
        : response.responseData is Map
        ? List<dynamic>.from(
            (response.responseData as Map)['paymentTypes'] as List? ??
                (response.responseData as Map)['items'] as List? ??
                const [],
          )
        : const <dynamic>[];
    if (rawList.isEmpty) return;

    final parsed = <PaymentMethod>[];
    final seenKeys = <String>{};

    for (final entry in rawList.whereType<Map>()) {
      final isEnabled =
          (entry['available'] ?? entry['isActive'] ?? entry['enabled'] ?? true) ==
          true;
      if (!isEnabled) continue;

      final expanded = _expandPaymentMethodsFromJson(entry);
      for (final method in expanded) {
        if (seenKeys.add(method.key)) {
          parsed.add(method);
        }
      }
    }

    if (parsed.isNotEmpty) {
      paymentMethods.assignAll(parsed);
      if (!parsed.any((method) => method.key == selectedPaymentMethod.value)) {
        selectedPaymentMethod.value = parsed.first.key;
      }
    }
  }

  List<PaymentMethod> _expandPaymentMethodsFromJson(Map<dynamic, dynamic> json) {
    final rawKey = (json['key'] ?? json['method'] ?? json['id'])
        ?.toString()
        .trim();
    final rawLabel = (json['label'] ?? json['name'] ?? rawKey)
        ?.toString()
        .trim();
    if (rawKey == null || rawKey.isEmpty || rawLabel == null || rawLabel.isEmpty) {
      return const [];
    }
    if (rawKey.toLowerCase() == 'installment') return const [];

    final rawParent = json['parentMethod']?.toString().trim().toLowerCase();
    if (rawParent == 'installment') return const [];

    final parentMethod =
        rawParent ??
        (rawKey.toLowerCase() == 'card'
            ? 'card'
            : rawKey.toLowerCase() == 'due'
            ? 'due'
            : 'cash');

    final styleFallback =
        _defaultPaymentMethods.firstWhereOrNull((m) => m.key == rawKey) ??
        _defaultPaymentMethods.firstWhereOrNull(
          (m) => m.key == parentMethod,
        ) ??
        _defaultPaymentMethods.first;

    final rawSubMethods = json['subMethods'];
    final subMethods = rawSubMethods is List
        ? rawSubMethods
              .map((e) => e?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    final isCustomSub =
        rawKey != 'cash' && rawKey != 'card' && rawKey != 'due';
    final result = <PaymentMethod>[
      PaymentMethod(
        key: rawKey,
        label: rawLabel,
        parentMethod: parentMethod,
        subMethod: isCustomSub ? rawLabel : null,
        subMethods: subMethods,
        icon: styleFallback.icon,
        gradientStart: styleFallback.gradientStart,
        gradientEnd: styleFallback.gradientEnd,
      ),
    ];

    for (final sub in subMethods) {
      final subKey =
          '${rawKey}_${sub.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      result.add(
        PaymentMethod(
          key: subKey,
          label: sub,
          parentMethod: parentMethod,
          subMethod: sub,
          icon: styleFallback.icon,
          gradientStart: styleFallback.gradientStart,
          gradientEnd: styleFallback.gradientEnd,
        ),
      );
    }

    return result;
  }

  Future<void> fetchPendingOrders() async {
    isLoadingPendingOrders.value = true;
    final response = await _networkCaller.getRequest(
      ApiConstants.pendingCheckout,
    );
    isLoadingPendingOrders.value = false;
    if (!response.isSuccess || response.responseData is! List) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }

    pendingOrders.assignAll(
      List<dynamic>.from(
        response.responseData as List,
      ).whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)),
    );
  }

  void openPendingOrders() {
    if (!isOpenOrderEnabled) return;
    fetchPendingOrders();
    Get.toNamed(AppRoute.getPendingOrdersScreen());
  }

  bool get isOpenOrderEnabled => FeatureSettings.isEnabled('open_order');

  bool get isTableOptionsEnabled => FeatureSettings.isEnabled('table_options');

  Future<TableOrder?> _selectAvailableTable() async {
    final homeController = Get.find<HomeController>();
    await homeController.fetchTables();
    final availableTables = homeController.availableTables;
    if (availableTables.isEmpty) {
      AppHelperFunctions.showWarningSnackBar('No available table found.');
      return null;
    }
    return Get.bottomSheet<TableOrder>(
      _AvailableTableSheet(tables: availableTables),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  Future<void> _sendToKdsIfEnabled({
    required Map<String, dynamic> order,
    required bool saveOrder,
    required bool sendToTable,
    String? tableId,
    String? tableName,
  }) async {
    if (!FeatureSettings.isEnabled('kitchen_printers')) return;

    try {
      final sent = await _kdsOrderSender.send({
        'id': order['id']?.toString() ?? activeOrderId.value ?? orderId,
        'tableId': tableId,
        'orderId':
            order['orderNumber']?.toString() ??
            (activeOrderNumber.value.isEmpty
                ? orderId
                : activeOrderNumber.value),
        'customerName': customerName.value,
        'tableName': tableName ?? order['tableName']?.toString() ?? 'No Table',
        'status': sendToTable
            ? 'ongoing'
            : saveOrder
            ? 'saved'
            : 'paid',
        'createdAt': DateTime.now().toIso8601String(),
        'items': cartItems
            .map((item) => {'name': item.name, 'quantity': item.quantity})
            .toList(),
      });
      if (!sent) {
        AppHelperFunctions.showWarningSnackBar('KDS is not configured.');
      }
    } catch (_) {
      AppHelperFunctions.showWarningSnackBar('KDS not reachable on WiFi.');
    }
  }

  Future<void> _printKitchenTicketsIfEnabled({
    required Map<String, dynamic> order,
    String? tableName,
  }) async {
    if (!FeatureSettings.isEnabled('kitchen_printers')) return;
    if (!Get.isRegistered<PrinterController>()) return;
    final products = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().products
        : const <Product>[];
    final categoryById = <String?, String?>{
      for (final product in products) product.id: product.categoryId,
    };
    await Get.find<PrinterController>().printKitchenTickets(
      orderLabel:
          order['orderNumber']?.toString() ??
          (activeOrderNumber.value.isEmpty ? orderId : activeOrderNumber.value),
      tableName: tableName ?? order['tableName']?.toString() ?? 'No table',
      customerName: customerName.value,
      items: cartItems.toList(),
      categoryOf: (itemId) => categoryById[itemId],
    );
  }

  void _syncCds() {
    if (!FeatureSettings.isEnabled('customer_displays')) return;
    _cdsCartSender.update(_cdsCartSnapshot());
  }

  String _resolveCdsImageUrl(String imageUrl) {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return '';
    if (File(trimmed).existsSync()) return '';
    return ApiConstants.resolveAssetUrl(trimmed);
  }

  Map<String, dynamic> _cdsCartSnapshot({bool paid = false}) {
    return {
      'status': paid ? 'paid' : 'building',
      'orderNumber': activeOrderNumber.value.isEmpty
          ? null
          : activeOrderNumber.value,
      'customerName': customerName.value,
      'items': cartItems
          .map(
            (item) => {
              'name': item.name,
              'quantity': item.quantity,
              'price': item.price,
              'imageUrl': _resolveCdsImageUrl(item.imageUrl),
              if (item.bundle != null)
                'bundle': {
                  'name': item.bundle!.name,
                  'price': item.bundle!.price,
                  'discountLabel': item.bundle!.discountLabel,
                  'discountAmount': item.bundle!.discountAmount,
                  'subtotal': item.bundle!.subtotal,
                },
            },
          )
          .toList(),
      'subtotal': subtotal,
      'tax': tax,
      'taxRatePercent': taxRate * 100,
      'totalAmount': totalAmount,
      'amountReceived': amountReceived.value,
      'changeToReturn': changeToReturn,
    };
  }

  Future<void> _submitCheckout({
    bool sendToTable = false,
    bool saveOrder = false,
    String? tableId,
    String? tableName,
  }) async {
    if (cartItems.isEmpty) {
      AppHelperFunctions.showWarningSnackBar('Add at least one item first.');
      return;
    }
    if (cartItems.any((item) => item.itemId == null)) {
      AppHelperFunctions.showWarningSnackBar(
        'Sync items from server before checkout.',
      );
      return;
    }
    final payload = _checkoutPayload(
      sendToTable: sendToTable,
      saveOrder: saveOrder,
      tableId: tableId,
      tableName: tableName,
    );

    isSubmittingCheckout.value = true;
    final online = Get.isRegistered<SyncService>()
        ? Get.find<SyncService>().isOnline.value
        : true;
    final currentOrderId = activeOrderId.value;
    final response = online
        ? currentOrderId != null && !sendToTable && !saveOrder
              ? await _networkCaller.postRequest(
                  ApiConstants.payCheckout(currentOrderId),
                  body: _paymentPayload(tableId: tableId, tableName: tableName),
                )
              : currentOrderId != null && saveOrder
              ? await _networkCaller.patchRequest(
                  ApiConstants.checkoutOrder(currentOrderId),
                  body: _updateCheckoutPayload(),
                )
              : await _networkCaller.postRequest(
                  ApiConstants.checkout,
                  body: payload,
                )
        : null;
    isSubmittingCheckout.value = false;

    if (response != null && response.isSuccess) {
      final order = response.responseData is Map
          ? Map<String, dynamic>.from(response.responseData as Map)
          : <String, dynamic>{};
      unawaited(() async {
        try {
          await fetchOrders();
        } catch (_) {}
        if (selectedCustomerId.value.isNotEmpty &&
            Get.isRegistered<CustomerController>()) {
          try {
            await Get.find<CustomerController>().fetchCustomers();
          } catch (_) {}
        }
        if (Get.isRegistered<HomeController>()) {
          try {
            await Get.find<HomeController>().fetchTables();
          } catch (_) {}
        }
        if (Get.isRegistered<TransactionController>()) {
          try {
            await Get.find<TransactionController>().fetchTransactions();
          } catch (_) {}
        }
        try {
          await _sendToKdsIfEnabled(
            order: order,
            saveOrder: saveOrder,
            sendToTable: sendToTable,
            tableId: tableId,
            tableName: tableName,
          );
        } catch (_) {}
        if (sendToTable || (!saveOrder && currentOrderId == null)) {
          try {
            await _printKitchenTicketsIfEnabled(
              order: order,
              tableName: tableName,
            );
          } catch (_) {}
        }
      }());
      if (!saveOrder && !sendToTable) {
        if (FeatureSettings.isEnabled('customer_displays')) {
          _cdsCartSender.complete(_cdsCartSnapshot(paid: true));
        }
        _openInvoice(order);
        clearOrder(silent: true);
      } else if (sendToTable) {
        activeOrderId.value = order['id']?.toString() ?? activeOrderId.value;
        activeOrderNumber.value =
            order['orderNumber']?.toString() ?? activeOrderNumber.value;
        _syncCds();
      } else if (saveOrder) {
        clearOrder();
        openPendingOrders();
      }
      AppHelperFunctions.showSuccessSnackBar(
        sendToTable
            ? 'Order sent to ${tableName ?? 'table'}.'
            : saveOrder
            ? 'Order saved.'
            : 'Checkout completed.',
      );
      return;
    }

    if (response != null &&
        response.statusCode != 0 &&
        response.statusCode != 408) {
      if (response.errorMessage.contains('storeId is required')) {
        AppHelperFunctions.showWarningSnackBar('Choose a store first.');
        await Get.find<StoreController>().ensureSelected(forcePicker: true);
        return;
      }
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }

    await OfflineDatabaseService.enqueue(
      type: OfflineActionType.createCheckout,
      payload: payload,
    );
    AppHelperFunctions.showWarningSnackBar(
      'Saved offline. It will sync when internet is back.',
    );
  }

  List<Map<String, dynamic>> _cartItemsPayload() {
    return cartItems
        .where((item) => item.itemId != null)
        .map(
          (item) => {
            'itemId': item.itemId,
            'quantity': item.quantity,
            if (item.bundle != null)
              'modifiers': [
                {'name': item.bundle!.name, 'price': item.bundle!.price},
              ],
            if (item.bundle != null)
              'discountAmount': item.bundle!.discountAmount,
          },
        )
        .toList();
  }

  Map<String, bool> _buildPaymentFlags() {
    if (splitPayments.isNotEmpty) {
      final hasCash = splitPayments.any((p) => p.parentMethod == 'cash');
      final hasCard = splitPayments.any((p) => p.parentMethod == 'card');
      return {
        'cash': hasCash || !hasCard,
        'card': hasCard,
        'due': false,
        'installment': false,
      };
    }
    final selected = paymentMethods.firstWhereOrNull(
      (m) => m.key == selectedPaymentMethod.value,
    );
    final parent = selected?.parentMethod ?? selectedPaymentMethod.value;
    return {
      'cash': parent == 'cash',
      'card': parent == 'card',
      'due': parent == 'due',
      'installment': false,
    };
  }

  List<Map<String, dynamic>> _buildBackendPaymentsArray() {
    final targetTotal = _money(totalAmount);
    if (targetTotal <= 0) return const [];

    if (splitPayments.isNotEmpty) {
      var remaining = targetTotal;
      final result = <Map<String, dynamic>>[];
      for (var i = 0; i < splitPayments.length; i++) {
        final entry = splitPayments[i];
        final isLast = i == splitPayments.length - 1;
        final allocated = isLast
            ? remaining
            : _money(entry.amount.clamp(0, remaining).toDouble());
        remaining = _money(
          (remaining - allocated).clamp(0, remaining).toDouble(),
        );
        if (allocated <= 0) continue;
        result.add({
          'method': entry.parentMethod == 'card' ? 'card' : 'cash',
          'label': entry.label,
          if (entry.subMethod != null && entry.subMethod!.isNotEmpty)
            'subMethod': entry.subMethod,
          'amount': allocated,
        });
      }
      return result;
    }

    final selected = paymentMethods.firstWhereOrNull(
      (m) => m.key == selectedPaymentMethod.value,
    );
    if (selected != null &&
        selected.parentMethod != 'due' &&
        (selected.subMethod != null ||
            (selected.key != 'cash' && selected.key != 'card'))) {
      return [
        {
          'method': selected.parentMethod == 'card' ? 'card' : 'cash',
          'label': selected.label,
          'subMethod': selected.subMethod ?? selected.label,
          'amount': targetTotal,
        },
      ];
    }
    return const [];
  }

  Map<String, dynamic> _checkoutPayload({
    required bool sendToTable,
    required bool saveOrder,
    String? tableId,
    String? tableName,
  }) {
    final paymentsArray = (!saveOrder && !sendToTable)
        ? _buildBackendPaymentsArray()
        : const <Map<String, dynamic>>[];
    return {
      'customerName': customerName.value == 'Not Registered'
          ? null
          : customerName.value,
      'items': _cartItemsPayload(),
      'taxAmount': _money(tax),
      'discountAmount': _money(discountAmount),
      if (!saveOrder && !sendToTable && loyaltyDiscount > 0)
        'loyaltyPointsRedeemed': _money(loyaltyDiscount),
      'amountReceived': _money(amountReceived.value),
      'storeId': ?StorageService.storeId,
      'posDeviceId': ?StorageService.posDeviceId,
      'payment': _buildPaymentFlags(),
      if (paymentsArray.isNotEmpty) 'payments': paymentsArray,
      'saveOrder': saveOrder,
      'sendToTable': sendToTable,
      'tableId': ?tableId,
      'tableName': ?tableName,
    };
  }

  Map<String, dynamic> _updateCheckoutPayload() {
    return {
      'customerName': customerName.value == 'Not Registered'
          ? null
          : customerName.value,
      'items': _cartItemsPayload(),
      'discountAmount': _money(discountAmount),
    };
  }

  Map<String, dynamic> _paymentPayload({String? tableId, String? tableName}) {
    final paymentsArray = _buildBackendPaymentsArray();
    return {
      'amountReceived': _money(amountReceived.value),
      'storeId': ?StorageService.storeId,
      'posDeviceId': ?StorageService.posDeviceId,
      'payment': _buildPaymentFlags(),
      if (paymentsArray.isNotEmpty) 'payments': paymentsArray,
      'tableId': ?tableId,
      'tableName': ?tableName,
    };
  }

  double _money(double value) => double.parse(value.toStringAsFixed(2));

  Future<bool> loadOrderForCheckout(String orderId) async {
    final response = await _networkCaller.getRequest(
      ApiConstants.checkoutOrder(orderId),
    );
    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar('Unable to open order.');
      return false;
    }

    final order = Map<String, dynamic>.from(response.responseData as Map);
    activeOrderId.value = order['id']?.toString();
    activeOrderNumber.value = order['orderNumber']?.toString() ?? '';
    activeTableId.value = order['tableId']?.toString();
    activeTableName.value = order['tableName']?.toString();
    selectedCustomerId.value = '';
    final savedCustomerName = order['customerName']?.toString().trim() ?? '';
    customerName.value = savedCustomerName.isEmpty
        ? 'Not Registered'
        : savedCustomerName;
    cartItems.assignAll(_cartItemsFromOrderJson(order));
    splitPayments.clear();
    amountEditedManually.value = false;
    amountReceived.value =
        double.tryParse(order['totalAmount']?.toString() ?? '') ??
        amountReceived.value;
    amountReceivedController.text = AppHelperFunctions.getFormattedMoney(
      amountReceived.value,
    );
    Get.find<MainNavController>().changeTab(1);
    _syncCds();
    return true;
  }

  List<CartItem> _cartItemsFromOrderJson(Map<String, dynamic> order) {
    final items = order['items'] is List
        ? List<dynamic>.from(order['items'] as List)
        : <dynamic>[];
    return items.whereType<Map>().map((entry) {
      final item = Map<String, dynamic>.from(entry);
      return CartItem(
        itemId: item['itemId']?.toString(),
        name: item['name']?.toString() ?? 'Item',
        price: double.tryParse(item['unitPrice']?.toString() ?? '') ?? 0,
        imageUrl: item['imageUrl']?.toString() ?? '',
        quantity: (double.tryParse(item['quantity']?.toString() ?? '') ?? 1)
            .round(),
      );
    }).toList();
  }

  Future<void> printPendingOrder(String orderId) async {
    final response = await _networkCaller.getRequest(
      ApiConstants.checkoutOrder(orderId),
    );
    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar('Unable to load order.');
      return;
    }

    final order = Map<String, dynamic>.from(response.responseData as Map);
    final rawCustomerName = order['customerName']?.toString().trim() ?? '';
    await Get.find<PrinterController>().printEstimate(
      orderId: order['orderNumber']?.toString() ?? orderId,
      customerName: rawCustomerName.isEmpty
          ? 'Not Registered'
          : rawCustomerName,
      items: _cartItemsFromOrderJson(order),
      subtotal: double.tryParse(order['subtotal']?.toString() ?? '') ?? 0,
      tax: double.tryParse(order['taxAmount']?.toString() ?? '') ?? 0,
      totalAmount: double.tryParse(order['totalAmount']?.toString() ?? '') ?? 0,
    );
  }

  Future<void> deletePendingOrder(String orderId) async {
    final response = await _networkCaller.deleteRequest(
      ApiConstants.checkoutOrder(orderId),
    );
    if (!response.isSuccess) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }
    pendingOrders.removeWhere((order) => order['id']?.toString() == orderId);
    AppHelperFunctions.showSuccessSnackBar('Order deleted.');
  }

  void _syncAmountReceivedWithTotal({bool force = false}) {
    if (!force && amountEditedManually.value) return;
    final value = totalAmount < 0 ? 0.0 : totalAmount;
    amountReceived.value = value;
    amountReceivedController.text = AppHelperFunctions.getFormattedMoney(value);
  }

  void _openInvoice(Map<String, dynamic> order) {
    if (order.isEmpty) return;
    Get.find<InvoiceController>().loadFromOrder(order);
    Get.toNamed(AppRoute.getInvoiceScreen());
  }

  @override
  void onClose() {
    amountReceivedController.dispose();
    super.onClose();
  }
}

class _SplitPaymentSheet extends StatefulWidget {
  final double totalAmount;
  final List<PaymentMethod> availableMethods;
  final List<SplitPaymentEntry> initialSplits;

  const _SplitPaymentSheet({
    required this.totalAmount,
    required this.availableMethods,
    required this.initialSplits,
  });

  @override
  State<_SplitPaymentSheet> createState() => _SplitPaymentSheetState();
}

class _SplitPaymentSheetState extends State<_SplitPaymentSheet> {
  late final List<SplitPaymentEntry> _splits;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _splits = List<SplitPaymentEntry>.from(widget.initialSplits);
    for (final split in _splits) {
      _controllers.add(
        TextEditingController(
          text: AppHelperFunctions.getFormattedMoney(split.amount),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _paidTotal =>
      _splits.fold(0.0, (sum, entry) => sum + entry.amount);

  double get _remaining =>
      double.parse((widget.totalAmount - _paidTotal).toStringAsFixed(2));

  void _updateMethod(int index, String? methodKey) {
    if (methodKey == null) return;
    final method = widget.availableMethods.firstWhereOrNull(
      (m) => m.key == methodKey,
    );
    if (method == null) return;
    setState(() {
      _splits[index] = _splits[index].copyWith(
        methodKey: method.key,
        parentMethod: method.parentMethod,
        label: method.label,
        subMethod: method.subMethod,
      );
    });
  }

  void _updateAmount(int index, String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(cleaned) ?? 0.0;
    setState(() {
      _splits[index] = _splits[index].copyWith(amount: parsed);
      // Auto-balance the last row if the user edits an earlier row in a 2-split setup
      if (_splits.length == 2 && index == 0) {
        final secondAmount = (widget.totalAmount - parsed)
            .clamp(0.0, widget.totalAmount)
            .toDouble();
        final rounded = double.parse(secondAmount.toStringAsFixed(2));
        _splits[1] = _splits[1].copyWith(amount: rounded);
        _controllers[1].text = AppHelperFunctions.getFormattedMoney(rounded);
      }
    });
  }

  void _addSplit() {
    final method = widget.availableMethods.first;
    final rem = _remaining > 0 ? _remaining : 0.0;
    setState(() {
      _splits.add(
        SplitPaymentEntry(
          methodKey: method.key,
          parentMethod: method.parentMethod,
          label: method.label,
          subMethod: method.subMethod,
          amount: rem,
        ),
      );
      _controllers.add(
        TextEditingController(
          text: AppHelperFunctions.getFormattedMoney(rem),
        ),
      );
    });
  }

  void _removeSplit(int index) {
    if (_splits.length <= 2) return;
    setState(() {
      _splits.removeAt(index);
      _controllers.removeAt(index).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canComplete = _paidTotal + 0.005 >= widget.totalAmount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Split Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextDark,
                    ),
                  ),
                  Text(
                    'Total: ${AppHelperFunctions.formatCurrency(widget.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onboardingBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < _splits.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            widget.availableMethods.any(
                              (m) => m.key == _splits[i].methodKey,
                            )
                            ? _splits[i].methodKey
                            : widget.availableMethods.first.key,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Method ${i + 1}',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: widget.availableMethods
                            .map(
                              (m) => DropdownMenuItem<String>(
                                value: m.key,
                                child: Text(
                                  m.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => _updateMethod(i, val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _controllers[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (val) => _updateAmount(i, val),
                      ),
                    ),
                    if (_splits.length > 2)
                      IconButton(
                        onPressed: () => _removeSplit(i),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.dangerRed,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addSplit,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Payment Method'),
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _remaining > 0 ? 'Remaining Balance:' : 'Change to Return:',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppHelperFunctions.formatCurrency(_remaining.abs()),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: _remaining > 0
                          ? AppColors.dangerRed
                          : AppColors.completeBadgeEnd,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: canComplete
                    ? () => Navigator.of(context).pop(_splits)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.onboardingBackground,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Charge Split (${AppHelperFunctions.formatCurrency(widget.totalAmount)})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _AvailableTableSheet extends StatelessWidget {
  final List<TableOrder> tables;

  const _AvailableTableSheet({required this.tables});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Table',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextDark,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tables.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    title: Text(table.tableName),
                    subtitle: table.capacity == null
                        ? const Text('Available')
                        : Text('Available • ${table.capacity} seats'),
                    trailing: const Icon(Iconsax.arrow_right_3),
                    onTap: () => Get.back(result: table),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
