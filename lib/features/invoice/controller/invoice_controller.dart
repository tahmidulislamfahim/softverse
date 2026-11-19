import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/business_profile_service.dart';
import '../../../core/services/feature_settings.dart';
import '../../../core/services/network_caller.dart';
import '../../../core/services/kds_order_sender.dart';
import '../../../core/services/storage_service.dart';
import '../../store/controller/store_controller.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/constants/product_images.dart';
import '../../../core/utils/helpers/app_helper.dart';
import '../../../core/utils/helpers/invoice_pdf_exporter.dart';
import '../../../core/utils/helpers/payment_receipt.dart';
import '../../../routes/app_routes.dart';
import '../../checkout/models/cart_item.dart';
import '../../transaction/models/transaction_record.dart';
import '../../home/controller/home_controller.dart';
import '../../main_nav/controller/main_nav_controller.dart';
import '../../printer/controller/printer_controller.dart';
import '../../transaction/controller/transaction_controller.dart';

class InvoiceController extends GetxController {
  final NetworkCaller _networkCaller = NetworkCaller();
  final KdsOrderSender _kdsOrderSender = KdsOrderSender();
  final checkoutOrderId = RxnString();
  final invoiceNumber = 'INV 00012'.obs;
  final refundInvoiceNumber = 'RINV 00001';
  final paymentType = PaymentType.cash.obs;
  final customerName = 'Abs Corporation'.obs;
  final orderId = 'POS-1 Order-1'.obs;
  final receiptPdfUrl = RxnString();
  final tableId = RxnString();
  final tableName = RxnString();
  final status = ''.obs;
  final isClearingTable = false.obs;
  final isPreparingPdf = false.obs;
  final isPrinting = false.obs;
  final isRefunding = false.obs;
  final localPdfPath = RxnString();
  final subtotalValue = 0.0.obs;
  final taxValue = 0.0.obs;
  final discountValue = 0.0.obs;
  final totalValue = 0.0.obs;
  final amountReceivedValue = 0.0.obs;
  final changeToReturnValue = 0.0.obs;
  final amountDueValue = 0.0.obs;
  final isCollectingDuePayment = false.obs;
  final orderCreatedAt = Rxn<DateTime>();
  final servedBy = RxnString();
  final posName = RxnString();
  final branchName = RxnString();
  final paymentAllocations = <Map<String, dynamic>>[].obs;

  final taxRate = 0.075;
  final _hasOrderData = false.obs;

  final selectedRefundIndex = Rx<int?>(null);
  final alreadyRefundedQuantities = <int, int>{}.obs;
  final refundQuantities = <int, int>{}.obs;
  final lastRefundedItems = <CartItem>[].obs;
  final lastRefundTotal = 0.0.obs;
  final refundReasonController = TextEditingController();

  final items = <CartItem>[
    CartItem(
      name: 'A4Ttech Keyboard',
      price: 800,
      imageUrl: ProductImages.keyboard,
      quantity: 1,
    ),
    CartItem(
      name: 'A4Ttech Mouse',
      price: 400,
      imageUrl: ProductImages.mouse,
      quantity: 1,
    ),
    CartItem(
      name: 'HP Monitor',
      price: 18000,
      imageUrl: ProductImages.monitor,
      quantity: 1,
    ),
  ].obs;

  double get subtotal => _hasOrderData.value
      ? subtotalValue.value
      : items.fold<double>(
          0,
          (sum, item) =>
              sum + (item.bundle?.subtotal ?? item.price) * item.quantity,
        );

  double get tax => _hasOrderData.value ? taxValue.value : subtotal * taxRate;

  double get effectiveTaxRate => subtotal > 0 ? tax / subtotal : 0;

  double get totalAmount =>
      _hasOrderData.value ? totalValue.value : subtotal + tax;

  double get amountReceived => amountReceivedValue.value;

  double get changeToReturn => changeToReturnValue.value;

  double get amountDue => amountDueValue.value;

  int maxRefundableQuantity(int index) {
    if (index < 0 || index >= items.length) return 0;
    final purchased = items[index].quantity;
    final already = alreadyRefundedQuantities[index] ?? 0;
    return (purchased - already).clamp(0, purchased);
  }

  int selectedRefundQuantity(int index) => refundQuantities[index] ?? 0;

  bool isItemSelectedForRefund(int index) => selectedRefundQuantity(index) > 0;

  int get selectedRefundItemCount =>
      refundQuantities.values.fold(0, (sum, qty) => sum + (qty > 0 ? qty : 0));

  bool get areAllRefundableItemsSelected {
    if (items.isEmpty) return false;
    var hasAnyRefundable = false;
    for (var i = 0; i < items.length; i++) {
      final maxQty = maxRefundableQuantity(i);
      if (maxQty > 0) {
        hasAnyRefundable = true;
        if (selectedRefundQuantity(i) < maxQty) return false;
      }
    }
    return hasAnyRefundable;
  }

  double get refundAmount {
    if (refundQuantities.isEmpty) return totalAmount;
    var isFullOriginalOrder = items.isNotEmpty;
    var selectedLinesSubtotal = 0.0;
    for (var i = 0; i < items.length; i++) {
      final qty = selectedRefundQuantity(i);
      if (qty != items[i].quantity) {
        isFullOriginalOrder = false;
      }
      if (qty > 0) {
        final unitPrice = items[i].bundle?.subtotal ?? items[i].price;
        selectedLinesSubtotal += unitPrice * qty;
      }
    }
    if (selectedLinesSubtotal <= 0) return 0;
    if (isFullOriginalOrder) return totalAmount;
    if (subtotal <= 0) return selectedLinesSubtotal;
    final ratio = (selectedLinesSubtotal / subtotal).clamp(0.0, 1.0);
    return double.parse((totalAmount * ratio).toStringAsFixed(2));
  }

  List<CartItem> get displayedRefundedItems =>
      lastRefundedItems.isNotEmpty ? lastRefundedItems : items;

  double get displayedRefundTotal =>
      lastRefundTotal.value > 0 ? lastRefundTotal.value : totalAmount;

  bool get _isCreditSale =>
      paymentType.value == PaymentType.due ||
      paymentType.value == PaymentType.installment;

  String get _printPaymentLabel {
    if (paymentAllocations.length > 1) {
      return paymentAllocations
          .map(
            (p) =>
                '${p['subMethod'] ?? p['label'] ?? p['method']}: ${AppHelperFunctions.formatCurrency(_toDouble(p['amount']))}',
          )
          .join(', ');
    }
    if (paymentAllocations.length == 1) {
      final p = paymentAllocations.first;
      final label = (p['subMethod'] ?? p['label'])?.toString().trim();
      if (label != null && label.isNotEmpty) return label;
    }
    return _isCreditSale && amountDue <= 0 ? 'Paid' : paymentType.value.label;
  }

  bool get canCollectDuePayment =>
      _isCreditSale && amountDue > 0 && !isRefunded;

  String get formattedDateTime {
    final dt = orderCreatedAt.value ?? DateTime.now();
    return AppHelperFunctions.getFormattedDate(
      dt,
      format: 'dd MMM yyyy, hh:mm a',
    );
  }

  void loadFromOrder(
    Map<String, dynamic> order, {
    String? fallbackTableId,
    String? fallbackTableName,
  }) {
    invoiceNumber.value =
        order['invoiceNumber']?.toString() ??
        order['orderNumber']?.toString() ??
        invoiceNumber.value;
    checkoutOrderId.value = _cleanText(order['id']);
    orderCreatedAt.value = DateTime.tryParse(
      order['createdAt']?.toString() ?? '',
    );
    customerName.value =
        order['customerName']?.toString().trim().isNotEmpty == true
        ? order['customerName'].toString()
        : 'Not registered';
    orderId.value = order['orderNumber']?.toString() ?? invoiceNumber.value;
    receiptPdfUrl.value = order['receiptPdfUrl']?.toString();
    status.value = order['status']?.toString() ?? '';
    tableId.value = _cleanText(order['tableId']) ?? _cleanText(fallbackTableId);
    tableName.value =
        _cleanText(order['tableName']) ?? _cleanText(fallbackTableName);
    subtotalValue.value = _toDouble(order['subtotal']);
    taxValue.value = _toDouble(order['taxAmount']);
    discountValue.value = _toDouble(order['discountAmount']);
    servedBy.value = _cleanText(order['createdByName']);
    posName.value = _cleanText(order['posDeviceName']);
    branchName.value = _storeName(_cleanText(order['storeId']));
    totalValue.value = _toDouble(order['totalAmount']);
    amountReceivedValue.value = _toDouble(order['amountReceived']);
    changeToReturnValue.value = _toDouble(order['changeToReturn']);
    amountDueValue.value = order.containsKey('amountDue')
        ? _toDouble(order['amountDue'])
        : (totalValue.value - amountReceivedValue.value)
              .clamp(0, totalValue.value)
              .toDouble();
    _hasOrderData.value = true;
    paymentType.value = status.value == 'refunded'
        ? PaymentType.refund
        : _paymentTypeFrom(order['paymentMethod']?.toString());

    final rawPayments = order['payments'];
    if (rawPayments is List) {
      paymentAllocations.assignAll(
        rawPayments
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(),
      );
    } else {
      paymentAllocations.clear();
    }

    final rawItems = order['items'] is List
        ? List<dynamic>.from(order['items'] as List)
        : <dynamic>[];
    final nextAlreadyRefunded = <int, int>{};
    final parsedItems = <CartItem>[];
    var idx = 0;
    for (final entry in rawItems.whereType<Map>()) {
      final item = Map<String, dynamic>.from(entry);
      final qty =
          (_toDouble(item['quantity']) == 0 ? 1 : _toDouble(item['quantity']))
              .round();
      final refundedQty = _toDouble(
        item['refundedQuantity'] ?? item['refundedQty'],
      ).round().clamp(0, qty);
      if (refundedQty > 0) {
        nextAlreadyRefunded[idx] = refundedQty;
      }
      parsedItems.add(
        CartItem(
          itemId: item['itemId']?.toString(),
          name: item['name']?.toString() ?? 'Item',
          price: _toDouble(item['unitPrice']),
          imageUrl: item['imageUrl']?.toString() ?? '',
          quantity: qty,
        ),
      );
      idx++;
    }
    items.assignAll(parsedItems);
    alreadyRefundedQuantities.assignAll(nextAlreadyRefunded);
    selectAllForRefund();
  }

  void selectRefundItem(int index) {
    selectedRefundIndex.value = index;
    toggleRefundItem(index);
  }

  void toggleRefundItem(int index) {
    final current = selectedRefundQuantity(index);
    if (current > 0) {
      refundQuantities[index] = 0;
    } else {
      final maxQty = maxRefundableQuantity(index);
      if (maxQty > 0) {
        refundQuantities[index] = maxQty;
      }
    }
    selectedRefundIndex.value = index;
    refundQuantities.refresh();
  }

  void setRefundItemQuantity(int index, int quantity) {
    final maxQty = maxRefundableQuantity(index);
    refundQuantities[index] = quantity.clamp(0, maxQty);
    selectedRefundIndex.value = index;
    refundQuantities.refresh();
  }

  void selectAllForRefund() {
    final next = <int, int>{};
    for (var i = 0; i < items.length; i++) {
      final maxQty = maxRefundableQuantity(i);
      if (maxQty > 0) {
        next[i] = maxQty;
      }
    }
    refundQuantities.assignAll(next);
  }

  void clearRefundSelection() {
    refundQuantities.clear();
  }

  bool get isRefunded => status.value == 'refunded';

  void goToRefund() {
    if (checkoutOrderId.value == null || checkoutOrderId.value!.isEmpty) {
      AppHelperFunctions.showWarningSnackBar(
        'This invoice cannot be refunded.',
      );
      return;
    }
    if (isRefunded) {
      AppHelperFunctions.showWarningSnackBar(
        'This invoice is already refunded.',
      );
      return;
    }
    refundReasonController.clear();
    selectAllForRefund();
    Get.toNamed(AppRoute.getRefundScreen());
  }

  void cancelRefund() => Get.back();

  Future<void> confirmRefund() async {
    final id = checkoutOrderId.value;
    if (id == null || id.isEmpty || isRefunding.value) return;

    final refundLines = <Map<String, dynamic>>[];
    final refundedSnapshot = <CartItem>[];
    for (var i = 0; i < items.length; i++) {
      final qty = selectedRefundQuantity(i);
      if (qty > 0) {
        refundLines.add({
          'lineIndex': i,
          if (items[i].itemId != null && items[i].itemId!.isNotEmpty)
            'itemId': items[i].itemId,
          'quantity': qty,
        });
        refundedSnapshot.add(items[i].copyWith(quantity: qty));
      }
    }

    if (refundLines.isEmpty) {
      AppHelperFunctions.showWarningSnackBar(
        'Select at least one item to refund.',
      );
      return;
    }

    final snapshotTotal = refundAmount;
    final reason = refundReasonController.text.trim();
    final body = <String, dynamic>{
      'items': refundLines,
      if (reason.isNotEmpty) 'reason': reason,
    };

    isRefunding.value = true;
    final response = await _networkCaller.postRequest(
      ApiConstants.refundCheckout(id),
      body: body,
    );
    isRefunding.value = false;

    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }

    lastRefundedItems.assignAll(refundedSnapshot);
    lastRefundTotal.value = snapshotTotal;
    loadFromOrder(Map<String, dynamic>.from(response.responseData as Map));
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().fetchItems();
    }
    if (Get.isRegistered<TransactionController>()) {
      await Get.find<TransactionController>().fetchTransactions();
    }
    AppHelperFunctions.showSuccessSnackBar('Refund completed.');
    Get.offNamed(AppRoute.getRefundInvoiceScreen());
  }

  Future<void> collectDuePayment(double amount) async {
    final id = checkoutOrderId.value;
    if (id == null || id.isEmpty || isCollectingDuePayment.value) return;
    if (amount <= 0) {
      AppHelperFunctions.showWarningSnackBar('Enter an amount to collect.');
      return;
    }
    if (amount > amountDue) {
      AppHelperFunctions.showWarningSnackBar(
        'Amount cannot exceed the outstanding due balance.',
      );
      return;
    }

    final previousDue = amountDue;
    isCollectingDuePayment.value = true;
    final response = await _networkCaller.postRequest(
      ApiConstants.collectDuePayment(id),
      body: {'amount': amount},
    );
    isCollectingDuePayment.value = false;

    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }

    final data = Map<String, dynamic>.from(response.responseData as Map);
    loadFromOrder(data);
    if (Get.isRegistered<TransactionController>()) {
      await Get.find<TransactionController>().fetchTransactions();
    }
    AppHelperFunctions.showSuccessSnackBar('Payment collected.');

    await handOverPaymentReceipt(
      orderNumber: invoiceNumber.value,
      customerName: customerName.value,
      previousDue: previousDue,
      amountPaid: amount,
      remainingDue: amountDue,
      paymentReceiptUrl: _cleanText(data['paymentReceiptUrl']),
    );
  }

  String? _storeName(String? storeId) {
    if (storeId == null) return null;
    if (Get.isRegistered<StoreController>()) {
      final match = Get.find<StoreController>().stores.firstWhereOrNull(
        (store) => store.id == storeId,
      );
      if (match != null) return match.name;
    }
    return StorageService.storeId == storeId ? StorageService.storeName : null;
  }

  void viewOriginalInvoice() {
    paymentType.value = PaymentType.cash;
    Get.toNamed(AppRoute.getInvoiceScreen());
  }

  void openNotifications() {}

  void openMail() {}

  Future<void> openPrint() async {
    if (isPrinting.value) return;
    if (!Get.isRegistered<PrinterController>()) {
      AppHelperFunctions.showWarningSnackBar('Add a receipt printer first.');
      return;
    }

    isPrinting.value = true;
    await Get.find<PrinterController>().printReceipt(
      invoiceNumber: invoiceNumber.value,
      customerName: customerName.value,
      orderId: orderId.value,
      dateTime: orderCreatedAt.value ?? DateTime.now(),
      items: items.toList(),
      subtotal: subtotal,
      discount: discountValue.value,
      tax: tax,
      totalAmount: totalAmount,
      amountReceived: amountReceived,
      changeToReturn: changeToReturn,
      amountDue: amountDue,
      paymentLabel: _printPaymentLabel,
      branchName: branchName.value,
      servedBy: servedBy.value,
      posName: posName.value,
    );
    isPrinting.value = false;
  }

  void returnHome() {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().changeTab(0);
    }
    Get.until((route) => route.settings.name == AppRoute.getHomeScreen());
  }

  Future<void> markTableEmpty() async {
    final id = tableId.value;
    if (id == null || id.isEmpty) {
      AppHelperFunctions.showWarningSnackBar(
        'This invoice is not linked to a table.',
      );
      return;
    }

    isClearingTable.value = true;
    final response = await _networkCaller.postRequest(
      ApiConstants.clearTable(id),
      body: const {},
    );
    isClearingTable.value = false;

    if (!response.isSuccess) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }

    tableId.value = null;
    tableName.value = null;
    if (FeatureSettings.isEnabled('kitchen_printers')) {
      await _kdsOrderSender.completeAny([
        checkoutOrderId.value,
        orderId.value,
        id,
      ]);
    }
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().fetchTables();
    }
    AppHelperFunctions.showSuccessSnackBar('Table marked empty.');
  }

  Future<void> exportPdf() async {
    if (isPreparingPdf.value) return;

    isPreparingPdf.value = true;
    try {
      final file = await _downloadBackendReceipt() ?? await _createLocalPdf();
      localPdfPath.value = file.path;
      Get.toNamed(AppRoute.getReceiptPreviewScreen());
    } catch (_) {
      AppHelperFunctions.showErrorSnackBar('Could not prepare receipt PDF.');
    } finally {
      isPreparingPdf.value = false;
    }
  }

  Future<void> exportAndDownloadPdf() async {
    if (isPreparingPdf.value) return;

    isPreparingPdf.value = true;
    try {
      final file = await _downloadBackendReceipt() ?? await _createLocalPdf();
      localPdfPath.value = file.path;
      await InvoicePdfExporter.saveToDevice(file);
    } catch (_) {
      AppHelperFunctions.showErrorSnackBar('Could not prepare receipt PDF.');
    } finally {
      isPreparingPdf.value = false;
    }
  }

  Future<void> downloadGeneratedPdf() async {
    final path = localPdfPath.value;
    if (path == null || path.isEmpty) return;
    await InvoicePdfExporter.saveToDevice(File(path));
  }

  Future<File> _createLocalPdf() {
    return InvoicePdfExporter.exportInvoice(
      invoiceNumber: invoiceNumber.value,
      customerName: customerName.value,
      dateTime: orderCreatedAt.value ?? DateTime.now(),
      items: items.toList(),
      subtotal: subtotal,
      discount: discountValue.value,
      tax: tax,
      totalAmount: totalAmount,
      amountReceived: amountReceived,
      changeToReturn: changeToReturn,
      amountDue: amountDue,
      paymentLabel: _printPaymentLabel,
      businessName: BusinessProfileService.name,
      businessAddress: BusinessProfileService.address,
      businessPhone: BusinessProfileService.phone,
      branchName: branchName.value ?? StorageService.storeName,
      servedBy: servedBy.value ?? StorageService.fullName,
      posName: posName.value ?? StorageService.posDeviceName,
    );
  }

  Future<File?> _downloadBackendReceipt() async {
    final url = _backendReceiptUrl();
    final token = StorageService.accessToken;
    if (url == null || token == null || token.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode != 200 || !contentType.contains('pdf')) {
        return null;
      }

      final filename =
          '${invoiceNumber.value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.pdf';
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  String? _backendReceiptUrl() {
    final id = checkoutOrderId.value;
    if (id != null && id.isNotEmpty) return ApiConstants.checkoutReceipt(id);
    final url = _cleanText(receiptPdfUrl.value);
    if (url == null) return null;
    return ApiConstants.resolveAssetUrl(url);
  }

  double _toDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String? _cleanText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  PaymentType _paymentTypeFrom(String? value) {
    return switch (value) {
      'card' => PaymentType.card,
      'due' => PaymentType.due,
      'installment' => PaymentType.installment,
      _ => PaymentType.cash,
    };
  }

  @override
  void onClose() {
    refundReasonController.dispose();
    super.onClose();
  }
}
