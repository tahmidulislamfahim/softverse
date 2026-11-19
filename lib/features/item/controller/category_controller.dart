import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/network_caller.dart';
import '../../../core/services/offline_database_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/constants/api_constants.dart';
import '../../../core/utils/helpers/app_helper.dart';
import '../../../routes/app_routes.dart';
import '../../home/controller/home_controller.dart';
import '../../inventory/controller/inventory_controller.dart';
import '../data/category_repository.dart';
import '../models/category_model.dart';

class CategoryAssignableItem {
  final String id;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String sku;

  const CategoryAssignableItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.sku = '',
  });
}

class CategoryController extends GetxController {
  final CategoryRepository _repository;

  CategoryController({CategoryRepository? repository})
    : _repository = repository ?? HttpCategoryRepository();

  final categories = <CategoryModel>[].obs;
  final isLoading = false.obs;

  bool get canEdit => PermissionService.has(AppPermission.createEditCategories);

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    isLoading.value = true;
    final response = await _repository.fetchAdminCategories();
    isLoading.value = false;
    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }
    final raw = (response.responseData as Map)['categories'];
    categories.assignAll(
      raw is List
          ? raw.whereType<Map>().map(
              (value) =>
                  CategoryModel.fromJson(Map<String, dynamic>.from(value)),
            )
          : const <CategoryModel>[],
    );
  }

  Future<void> openCreate() async {
    if (!canEdit) {
      _permissionDenied();
      return;
    }
    final saved = await Get.toNamed(AppRoute.getCategoryFormScreen());
    if (saved is CategoryModel) await fetchCategories();
  }

  Future<void> openEdit(CategoryModel category) async {
    if (!canEdit) {
      _permissionDenied();
      return;
    }
    final saved = await Get.toNamed(
      AppRoute.getCategoryFormScreen(),
      arguments: category,
    );
    if (saved is CategoryModel) await fetchCategories();
  }

  Future<void> delete(CategoryModel category) async {
    if (!canEdit) {
      _permissionDenied();
      return;
    }
    if (!_isOnline) {
      AppHelperFunctions.showWarningSnackBar(
        'Connect to the internet to delete a category.',
      );
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          category.itemCount > 0
              ? '${category.name} is assigned to ${category.itemCount} item(s) and cannot be deleted.'
              : 'Delete ${category.name}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          if (category.itemCount == 0)
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
    if (confirmed != true) return;
    final response = await _repository.deleteCategory(category.id);
    if (!response.isSuccess) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }
    categories.removeWhere((entry) => entry.id == category.id);
    await _refreshPickerCache();
    AppHelperFunctions.showSuccessSnackBar('Category deleted.');
  }

  bool get _isOnline =>
      !Get.isRegistered<SyncService>() ||
      Get.find<SyncService>().isOnline.value;

  Future<void> _refreshPickerCache() async {
    final response = await _repository.fetchCategories();
    if (response.isSuccess && response.responseData is List) {
      await OfflineDatabaseService.saveCache(
        'categories',
        List<dynamic>.from(response.responseData as List),
      );
    }
  }

  void _permissionDenied() => AppHelperFunctions.showErrorSnackBar(
    'You do not have permission to manage categories.',
  );
}

class CategoryFormController extends GetxController {
  final CategoryRepository _repository;
  final NetworkCaller _networkCaller;

  CategoryFormController({
    CategoryRepository? repository,
    NetworkCaller? networkCaller,
  }) : _repository = repository ?? HttpCategoryRepository(),
       _networkCaller = networkCaller ?? NetworkCaller();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final isActive = true.obs;
  final isSaving = false.obs;
  final selectedColorIndex = 0.obs;
  final selectedShapeIndex = 0.obs;
  final availableItems = <CategoryAssignableItem>[].obs;
  final selectedItemIds = <String>{}.obs;
  final isLoadingItems = false.obs;
  final itemsModified = false.obs;
  final itemSearchQuery = ''.obs;
  CategoryModel? category;

  bool get isEditing => category != null;

  List<CategoryAssignableItem> get filteredAvailableItems {
    final query = itemSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return availableItems;
    return availableItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.sku.toLowerCase().contains(query) ||
              (item.categoryName ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is CategoryModel) {
      category = Get.arguments as CategoryModel;
      nameController.text = category!.name;
      descriptionController.text = category!.description ?? '';
      isActive.value = category!.isActive;
      selectedColorIndex.value = category!.colorIndex.clamp(0, 7);
      selectedShapeIndex.value = _shapeIndex(category!.shape);
      selectedItemIds.addAll(category!.itemIds);
    }
    _seedItemsFromMemoryOrCache();
    if (!Get.testMode) {
      unawaited(loadAssignableItems());
    }
  }

  void _seedItemsFromMemoryOrCache() {
    final byId = <String, CategoryAssignableItem>{};
    if (Get.isRegistered<HomeController>()) {
      for (final p in Get.find<HomeController>().products) {
        final id = p.id?.trim();
        if (id != null && id.isNotEmpty) {
          byId[id] = CategoryAssignableItem(
            id: id,
            name: p.name,
            categoryId: p.categoryId,
            categoryName: p.categoryName,
            sku: p.sku,
          );
        }
      }
    }
    final cached = OfflineDatabaseService.readCache<List<dynamic>>('items');
    if (cached != null) {
      for (final raw in cached.whereType<Map>()) {
        final id = raw['id']?.toString().trim();
        if (id != null && id.isNotEmpty && !byId.containsKey(id)) {
          final cat = raw['category'] is Map
              ? Map<String, dynamic>.from(raw['category'] as Map)
              : const <String, dynamic>{};
          byId[id] = CategoryAssignableItem(
            id: id,
            name: raw['name']?.toString() ?? 'Unnamed Item',
            categoryId: (raw['categoryId'] ?? cat['id'])?.toString(),
            categoryName: (raw['categoryName'] ?? cat['name'])?.toString(),
            sku: raw['sku']?.toString() ?? '',
          );
        }
      }
    }
    if (byId.isNotEmpty) {
      _applyAssignableItems(byId.values);
    }
  }

  Future<void> loadAssignableItems() async {
    isLoadingItems.value = true;
    final response = await _networkCaller.getRequest(ApiConstants.items);
    isLoadingItems.value = false;
    if (!response.isSuccess) return;
    final rawList = response.responseData is List
        ? List<dynamic>.from(response.responseData as List)
        : response.responseData is Map
        ? List<dynamic>.from(
            (response.responseData as Map)['items'] as List? ?? const [],
          )
        : const <dynamic>[];
    final items = <CategoryAssignableItem>[];
    for (final raw in rawList.whereType<Map>()) {
      final id = raw['id']?.toString().trim();
      if (id == null || id.isEmpty) continue;
      final cat = raw['category'] is Map
          ? Map<String, dynamic>.from(raw['category'] as Map)
          : const <String, dynamic>{};
      items.add(
        CategoryAssignableItem(
          id: id,
          name: raw['name']?.toString() ?? 'Unnamed Item',
          categoryId: (raw['categoryId'] ?? cat['id'])?.toString(),
          categoryName: (raw['categoryName'] ?? cat['name'])?.toString(),
          sku: raw['sku']?.toString() ?? '',
        ),
      );
    }
    if (items.isNotEmpty) {
      _applyAssignableItems(items);
    }
  }

  void _applyAssignableItems(Iterable<CategoryAssignableItem> source) {
    final sorted = source.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    availableItems.assignAll(sorted);
    if (isEditing && !itemsModified.value && category != null) {
      final targetId = category!.id.trim();
      final targetName = category!.name.trim().toLowerCase();
      for (final item in sorted) {
        final matchId = targetId.isNotEmpty && item.categoryId == targetId;
        final matchName =
            targetName.isNotEmpty &&
            (item.categoryName ?? '').trim().toLowerCase() == targetName;
        if (matchId || matchName) {
          selectedItemIds.add(item.id);
        }
      }
      selectedItemIds.refresh();
    }
  }

  void toggleItemSelection(String itemId) {
    itemsModified.value = true;
    if (selectedItemIds.contains(itemId)) {
      selectedItemIds.remove(itemId);
    } else {
      selectedItemIds.add(itemId);
    }
    selectedItemIds.refresh();
  }

  void selectColor(int index) => selectedColorIndex.value = index.clamp(0, 7);

  void selectShape(int index) => selectedShapeIndex.value = index.clamp(0, 3);

  Map<String, dynamic>? buildPayload() {
    final name = nameController.text.trim();
    if (name.isEmpty) return null;
    return {
      'name': name,
      if (descriptionController.text.trim().isNotEmpty)
        'description': descriptionController.text.trim(),
      'colorIndex': selectedColorIndex.value,
      'shape': _shapeValue(selectedShapeIndex.value),
      'isActive': isActive.value,
      if (itemsModified.value || selectedItemIds.isNotEmpty)
        'itemIds': selectedItemIds.toList(),
    };
  }

  Future<void> save() async {
    if (isSaving.value) return;
    if (!PermissionService.has(AppPermission.createEditCategories)) {
      AppHelperFunctions.showErrorSnackBar(
        'You do not have permission to manage categories.',
      );
      return;
    }
    final payload = buildPayload();
    if (payload == null) {
      AppHelperFunctions.showWarningSnackBar('Category name is required.');
      return;
    }
    final online =
        !Get.isRegistered<SyncService>() ||
        Get.find<SyncService>().isOnline.value;
    if (!online) {
      AppHelperFunctions.showWarningSnackBar(
        'Connect to the internet to create or edit a category.',
      );
      return;
    }

    isSaving.value = true;
    final response = isEditing
        ? await _repository.updateCategory(category!.id, payload)
        : await _repository.createCategory(payload);
    isSaving.value = false;
    if (!response.isSuccess || response.responseData is! Map) {
      AppHelperFunctions.showErrorSnackBar(response.errorMessage);
      return;
    }
    final saved = CategoryModel.fromJson(
      Map<String, dynamic>.from(response.responseData as Map),
    );
    final activeResponse = await _repository.fetchCategories();
    if (activeResponse.isSuccess && activeResponse.responseData is List) {
      await OfflineDatabaseService.saveCache(
        'categories',
        List<dynamic>.from(activeResponse.responseData as List),
      );
    }
    if (Get.isRegistered<HomeController>()) {
      unawaited(Get.find<HomeController>().forceSync(showMessage: false));
    }
    if (Get.isRegistered<InventoryController>()) {
      unawaited(Get.find<InventoryController>().fetchCategories());
      unawaited(Get.find<InventoryController>().fetchInventory());
    }
    Get.back(result: saved);
    AppHelperFunctions.showSuccessSnackBar(
      isEditing ? 'Category updated.' : 'Category created.',
    );
  }

  String _shapeValue(int index) => switch (index) {
    1 => 'circle',
    2 => 'star',
    3 => 'hexagon',
    _ => 'square',
  };

  int _shapeIndex(String? shape) => switch (shape?.toLowerCase()) {
    'circle' => 1,
    'star' => 2,
    'hexagon' => 3,
    _ => 0,
  };

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
