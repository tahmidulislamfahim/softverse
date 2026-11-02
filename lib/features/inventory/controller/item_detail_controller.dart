import 'package:get/get.dart';

import '../../../core/services/network_caller.dart';
import '../../../core/services/offline_database_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/helpers/app_helper.dart';
import '../../../routes/app_routes.dart';
import '../models/inventory_product.dart';
import '../models/modifier_group.dart';

class ItemDetailController extends GetxController {
  final NetworkCaller _networkCaller;
  final InventoryProduct? _initialProduct;

  ItemDetailController({
    NetworkCaller? networkCaller,
    InventoryProduct? initialProduct,
  }) : _networkCaller = networkCaller ?? NetworkCaller(),
       _initialProduct = initialProduct;

  late final Rx<InventoryProduct> _product;
  InventoryProduct get product => _product.value;

  final isLoading = false.obs;
  final soldBy = 'PCS'.obs;
  final manufacturingDate = ''.obs;
  final expireDate = ''.obs;
  final expirationAlertQuantity = RxnInt();

  final modifierEnabled = false.obs;
  final trackExpiryDate = false.obs;
  final activityEnabled = true.obs;
  final selectedModifierOptionIndex = 0.obs;
  final modifierGroup = const ModifierGroup().obs;

  @override
  void onInit() {
    super.onInit();
    final arg = _initialProduct ?? Get.arguments;
    final initial = arg is InventoryProduct
        ? arg
        : const InventoryProduct(
            name: '',
            sku: '',
            price: 0,
            cost: 0,
            barcode: '',
            inStock: 0,
            lowStockThreshold: 0,
            imageUrl: '',
          );
    _product = initial.obs;
    _applyProduct(initial);
    fetchItemDetail();
  }

  Future<void> fetchItemDetail() async {
    final id = product.id;
    if (id == null || id.isEmpty) return;

    _loadCachedItemDetail(id);
    if (id.startsWith('local-')) return;

    isLoading.value = true;
    final response = await _networkCaller.getRequest(ApiConstants.item(id));
    isLoading.value = false;
    if (!response.isSuccess || response.responseData is! Map) return;

    final data = Map<String, dynamic>.from(response.responseData as Map);
    await OfflineDatabaseService.saveCache('item_$id', data);
    _applyItemJson(data);
  }

  void _loadCachedItemDetail(String id) {
    final cachedDetail = OfflineDatabaseService.readCache<Map<String, dynamic>>(
      'item_$id',
    );
    if (cachedDetail != null) {
      _applyItemJson(cachedDetail);
      return;
    }

    final cachedItems = OfflineDatabaseService.readCache<List<dynamic>>(
      'items',
    );
    if (cachedItems == null) return;
    for (final entry in cachedItems.whereType<Map>()) {
      if (entry['id']?.toString() == id) {
        _applyItemJson(Map<String, dynamic>.from(entry));
        return;
      }
    }
  }

  void _applyItemJson(Map<String, dynamic> json) {
    final updated = InventoryProduct.fromApi(
      json,
      storeId: StorageService.storeId,
      fallback: product,
    );
    _applyProduct(updated);
  }

  void _applyProduct(InventoryProduct item) {
    _product.value = item;
    soldBy.value = item.soldBy.toLowerCase() == 'weight' ? 'Weight' : 'PCS';
    modifierEnabled.value = item.modifierEnabled;
    modifierGroup.value = item.modifierGroup;
    if (selectedModifierOptionIndex.value >= item.modifierGroup.options.length) {
      selectedModifierOptionIndex.value = 0;
    }
    trackExpiryDate.value = item.trackExpiration;
    manufacturingDate.value = item.manufacturingDate;
    expireDate.value = item.expirationDate;
    expirationAlertQuantity.value = item.expirationAlertQuantity;
    activityEnabled.value = item.isActive;
  }

  Future<void> toggleModifier() async {
    final next = !modifierEnabled.value;
    modifierEnabled.value = next;
    await _patchItem({'modifierEnabled': next});
  }

  Future<void> toggleTrackExpiryDate() async {
    final next = !trackExpiryDate.value;
    trackExpiryDate.value = next;
    await _patchItem({'trackExpiration': next});
  }

  Future<void> toggleActivity() async {
    final next = !activityEnabled.value;
    activityEnabled.value = next;
    await _patchItem({'isActive': next});
  }

  Future<void> _patchItem(Map<String, dynamic> body) async {
    final id = product.id;
    if (id == null || id.isEmpty || id.startsWith('local-') || !canEdit) {
      return;
    }
    await _networkCaller.patchRequest(ApiConstants.item(id), body: body);
  }

  void selectModifierOption(int index) =>
      selectedModifierOptionIndex.value = index;

  bool get canEdit => PermissionService.has(AppPermission.createEditProducts);

  Future<void> openEdit() async {
    if (!canEdit) {
      AppHelperFunctions.showErrorSnackBar(
        'You do not have permission to edit items.',
      );
      return;
    }
    final id = product.id;
    if (id == null || id.isEmpty || id.startsWith('local-')) {
      AppHelperFunctions.showWarningSnackBar(
        'This item cannot be edited yet - it hasn\'t finished syncing.',
      );
      return;
    }
    await Get.toNamed(AppRoute.getCreateItemScreen(), arguments: id);
    await fetchItemDetail();
  }
}
