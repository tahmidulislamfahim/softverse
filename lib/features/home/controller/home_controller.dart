import 'package:get/get.dart';

import '../../../core/services/business_profile_service.dart';
import '../../../core/services/feature_settings.dart';
import '../../../core/common/widgets/catalog_search_sheet.dart';
import '../../../core/services/network_caller.dart';
import '../../../core/services/offline_database_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/helpers/app_helper.dart';
import '../../../routes/app_routes.dart';
import '../../checkout/controller/checkout_controller.dart';
import '../../invoice/controller/invoice_controller.dart';
import '../../main_nav/controller/main_nav_controller.dart';
import '../models/product.dart';
import '../models/table_order.dart';
import '../data/home_repository.dart';

class HomeController extends GetxController {
  final NetworkCaller _networkCaller;
  final HomeRepository _homeRepository;

  HomeController({NetworkCaller? networkCaller, HomeRepository? homeRepository})
    : _networkCaller = networkCaller ?? NetworkCaller(),
      _homeRepository = homeRepository ?? HttpHomeRepository();
  final isOrderTabSelected = true.obs;
  final selectedCategoryIndex = 0.obs;
  final isLoadingCatalog = false.obs;
  final isLoadingTables = false.obs;

  String get orderId => Get.find<CheckoutController>().orderId;

  int get orderItemCount => Get.find<CheckoutController>().cartItems.fold(
    0,
    (sum, item) => sum + item.quantity,
  );

  double get orderTotal => Get.find<CheckoutController>().subtotal;

  final categories = <String>['All Item'].obs;
  final _categoryIdByName = <String, String>{};
  final _categoryNameById = <String, String>{};
  final products = <Product>[].obs;
  final tableOrders = <TableOrder>[].obs;

  List<TableOrder> get availableTables => tableOrders
      .where((table) => table.isAvailable && table.tableId.isNotEmpty)
      .toList(growable: false);

  List<TableOrder> get visibleTableOrders =>
      tableOrders.where((table) => table.hasOrder).toList(growable: false);

  List<Product> get visibleProducts {
    if (selectedCategoryIndex.value <= 0 ||
        selectedCategoryIndex.value >= categories.length) {
      return products;
    }
    final selected = categories[selectedCategoryIndex.value];
    final normalizedSelected = selected.trim().toLowerCase();
    final selectedId = _categoryIdByName[normalizedSelected];
    return products
        .where((product) {
          if (selectedId != null &&
              selectedId.isNotEmpty &&
              product.categoryId == selectedId) {
            return true;
          }
          final catName =
              product.categoryName ??
              (product.categoryId != null
                  ? _categoryNameById[product.categoryId]
                  : null) ??
              '';
          return catName.trim().toLowerCase() == normalizedSelected;
        })
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    _loadCachedCatalog();
    _loadCachedTables();
    forceSync(showMessage: false);
    BusinessProfileService.fetch();
  }

  Future<void> openTableOrder(TableOrder tableOrder) async {
    if (!tableOrder.hasOrder) return;
    if (tableOrder.status == OrderStatus.complete ||
        tableOrder.status == OrderStatus.paid) {
      final response = await _networkCaller.getRequest(
        ApiConstants.checkoutOrder(tableOrder.id!),
      );
      if (response.isSuccess && response.responseData is Map) {
        Get.find<InvoiceController>().loadFromOrder(
          Map<String, dynamic>.from(response.responseData as Map),
          fallbackTableId: tableOrder.tableId,
          fallbackTableName: tableOrder.tableName,
        );
        Get.toNamed(AppRoute.getInvoiceScreen());
      }
      return;
    }

    await Get.find<CheckoutController>().loadOrderForCheckout(tableOrder.id!);
  }

  void selectOrderTab() => isOrderTabSelected.value = true;

  void selectTableTab() {
    isOrderTabSelected.value = false;
    fetchTables();
  }

  void selectCategory(int index) => selectedCategoryIndex.value = index;

  void checkout() => Get.find<MainNavController>().changeTab(1);

  void openPendingOrders() =>
      Get.find<CheckoutController>().openPendingOrders();

  bool addToCart(Product product) {
    if (product.isOutOfStock &&
        FeatureSettings.isEnabled('negative_stock_alerts')) {
      AppHelperFunctions.showWarningSnackBar(
        '${product.name} is out of stock.',
      );
      return false;
    }
    Get.find<CheckoutController>().addProduct(
      itemId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
    );
    return true;
  }

  Product? findProductByBarcode(String barcode) {
    final normalized = barcode.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return products.firstWhereOrNull(
      (product) => product.barcode.trim().toLowerCase() == normalized,
    );
  }

  bool addProductByBarcode(String barcode, {bool showFeedback = true}) {
    final product = findProductByBarcode(barcode);
    if (product == null) {
      if (showFeedback) {
        AppHelperFunctions.showWarningSnackBar(
          'No item found for barcode $barcode.',
        );
      }
      return false;
    }
    final added = addToCart(product);
    if (added && showFeedback) {
      AppHelperFunctions.showSuccessSnackBar(
        '${product.name} added to checkout.',
      );
    }
    return added;
  }

  Future<void> openSearch() async {
    final selected = await showCatalogSearchSheet(
      title: 'Search products',
      items: products
          .map(
            (product) => CatalogSearchEntry(
              key: product.id ?? product.name,
              name: product.name,
              sku: product.sku,
              barcode: product.barcode,
              subtitle: product.stockLabel,
            ),
          )
          .toList(),
    );
    if (selected == null) return;
    final product = products.firstWhereOrNull(
      (item) => (item.id ?? item.name) == selected.key,
    );
    if (product != null) addToCart(product);
  }

  Future<void> openScan() async {
    final result = await Get.toNamed(AppRoute.getScanBarcodeScreen());
    if (result is! String || result.trim().isEmpty) return;
    final barcode = result.trim();
    addProductByBarcode(barcode);
  }

  Future<void> forceSync({bool showMessage = true}) async {
    await Future.wait([fetchCategories(), fetchItems(), fetchTables()]);
    if (showMessage) {
      AppHelperFunctions.showSuccessSnackBar('Synced');
    }
  }

  Future<void> fetchCategories() async {
    final response = await _homeRepository.fetchCategories();
    if (!response.isSuccess || response.responseData is! List) return;
    final data = List<dynamic>.from(response.responseData as List);
    await OfflineDatabaseService.saveCache('categories', data);
    _applyCategories(data);
  }

  Future<void> fetchItems() async {
    isLoadingCatalog.value = true;
    final response = await _homeRepository.fetchItems();
    isLoadingCatalog.value = false;
    if (!response.isSuccess) return;
    final data = response.responseData is Map
        ? List<dynamic>.from(
            (response.responseData as Map)['items'] as List? ?? <dynamic>[],
          )
        : List<dynamic>.from(response.responseData as List? ?? <dynamic>[]);
    await OfflineDatabaseService.saveCache('items', data);
    _applyItems(data);
  }

  Future<void> fetchTables() async {
    isLoadingTables.value = true;
    final response = await _homeRepository.fetchTables();
    isLoadingTables.value = false;
    if (!response.isSuccess || response.responseData is! Map) return;
    final data = Map<String, dynamic>.from(response.responseData as Map);
    await OfflineDatabaseService.saveCache('tables', data);
    _applyTables(data);
  }

  void _loadCachedCatalog() {
    final cachedCategories = OfflineDatabaseService.readCache<List<dynamic>>(
      'categories',
    );
    final cachedItems = OfflineDatabaseService.readCache<List<dynamic>>(
      'items',
    );
    if (cachedCategories != null) _applyCategories(cachedCategories);
    if (cachedItems != null) {
      _applyItems(cachedItems);
    }
  }

  void _loadCachedTables() {
    final cachedTables = OfflineDatabaseService.readCache<Map<String, dynamic>>(
      'tables',
    );
    if (cachedTables != null) _applyTables(cachedTables);
  }

  void _applyCategories(List<dynamic> data) {
    _categoryIdByName.clear();
    _categoryNameById.clear();
    final nameSet = <String>{};
    for (final entry in data.whereType<Map>()) {
      final id = entry['id']?.toString().trim();
      final name = entry['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        nameSet.add(name);
        if (id != null && id.isNotEmpty) {
          _categoryIdByName[name.toLowerCase()] = id;
          _categoryNameById[id] = name;
        }
      }
    }
    for (final product in products) {
      final pCat = product.categoryName?.trim();
      if (pCat != null && pCat.isNotEmpty) {
        nameSet.add(pCat);
      }
    }
    final names = nameSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    categories.assignAll(['All Item', ...names]);
    if (selectedCategoryIndex.value >= categories.length) {
      selectedCategoryIndex.value = 0;
    }
  }

  void _applyItems(List<dynamic> data) {
    final mapped = data.whereType<Map>().map((entry) {
      return Product.fromApi(Map<String, dynamic>.from(entry));
    }).toList();
    mapped.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    products.assignAll(mapped);
    final existingLower = categories.map((c) => c.trim().toLowerCase()).toSet();
    final extraNames = <String>[];
    for (final product in mapped) {
      final catName = product.categoryName?.trim();
      if (catName != null &&
          catName.isNotEmpty &&
          !existingLower.contains(catName.toLowerCase())) {
        existingLower.add(catName.toLowerCase());
        extraNames.add(catName);
      }
      if (catName != null &&
          catName.isNotEmpty &&
          product.categoryId != null &&
          product.categoryId!.isNotEmpty) {
        _categoryIdByName.putIfAbsent(
          catName.toLowerCase(),
          () => product.categoryId!,
        );
        _categoryNameById.putIfAbsent(product.categoryId!, () => catName);
      }
    }
    if (extraNames.isNotEmpty) {
      final allNames = [...categories.skip(1), ...extraNames]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      categories.assignAll(['All Item', ...allNames]);
    }
  }

  Future<void> addLocalItem(Map<String, dynamic> item) async {
    final cachedItems =
        OfflineDatabaseService.readCache<List<dynamic>>('items') ?? <dynamic>[];
    final nextItems = [item, ...cachedItems];
    await OfflineDatabaseService.saveCache('items', nextItems);
    _applyItems(nextItems);
  }

  void _applyTables(Map<String, dynamic> data) {
    final rawTables = data['tables'];
    if (rawTables is! List) return;
    tableOrders.assignAll(
      rawTables
          .whereType<Map>()
          .map((entry) => TableOrder.fromApi(Map<String, dynamic>.from(entry)))
          .toList(),
    );
  }
}
