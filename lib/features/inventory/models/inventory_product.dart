import 'modifier_group.dart';

class InventoryProduct {
  final String? id;
  final String? categoryName;
  final String name;
  final String description;
  final String sku;
  final String soldBy;
  final double price;
  final double cost;
  final String barcode;
  final bool trackStock;
  final int inStock;
  final int lowStockThreshold;
  final String imageUrl;
  final bool modifierEnabled;
  final ModifierGroup modifierGroup;
  final bool trackExpiration;
  final String manufacturingDate;
  final String expirationDate;
  final int? expirationAlertQuantity;
  final bool isActive;

  const InventoryProduct({
    this.id,
    this.categoryName,
    required this.name,
    this.description = '',
    required this.sku,
    this.soldBy = 'pcs',
    required this.price,
    required this.cost,
    required this.barcode,
    this.trackStock = true,
    required this.inStock,
    required this.lowStockThreshold,
    required this.imageUrl,
    this.modifierEnabled = false,
    this.modifierGroup = const ModifierGroup(),
    this.trackExpiration = false,
    this.manufacturingDate = '',
    this.expirationDate = '',
    this.expirationAlertQuantity,
    this.isActive = true,
  });

  int get displayInStock => inStock < 0 ? 0 : inStock;

  bool get isOutOfStock => trackStock && inStock <= 0;

  bool get isLowStock =>
      trackStock &&
      !isOutOfStock &&
      lowStockThreshold > 0 &&
      inStock <= lowStockThreshold;

  String get stockLabel {
    if (!trackStock) return '';
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return '$displayInStock In Stock';
  }

  factory InventoryProduct.fromApi(
    Map<String, dynamic> json, {
    String? storeId,
    InventoryProduct? fallback,
  }) {
    final inventory = json['inventory'] is Map
        ? Map<String, dynamic>.from(json['inventory'] as Map)
        : <String, dynamic>{};
    final representation = json['representation'] is Map
        ? Map<String, dynamic>.from(json['representation'] as Map)
        : <String, dynamic>{};
    final modifiers = json['modifiers'] is Map
        ? Map<String, dynamic>.from(json['modifiers'] as Map)
        : <String, dynamic>{};
    final expiration = json['expiration'] is Map
        ? Map<String, dynamic>.from(json['expiration'] as Map)
        : <String, dynamic>{};

    Map<String, dynamic>? matchedStore;
    if (storeId != null && storeId.isNotEmpty) {
      final rawStores = json['stores'] ?? inventory['stores'];
      if (rawStores is List) {
        for (final entry in rawStores.whereType<Map>()) {
          final entryStoreId = (entry['id'] ?? entry['storeId'])?.toString();
          if (entryStoreId == storeId) {
            matchedStore = Map<String, dynamic>.from(entry);
            break;
          }
        }
      }
    }

    final trackStock = json.containsKey('trackStock')
        ? json['trackStock'] == true
        : inventory.containsKey('trackStock')
        ? inventory['trackStock'] == true
        : (fallback?.trackStock ?? false);

    final inStockRaw =
        matchedStore?['inStock'] ??
        json['inStock'] ??
        inventory['inStock'] ??
        fallback?.inStock;
    final lowStockRaw =
        matchedStore?['lowStock'] ??
        json['lowStock'] ??
        inventory['lowStock'] ??
        fallback?.lowStockThreshold;

    final rawImageUrl = (json['imageUrl'] ?? representation['imageUrl'])
        ?.toString();
    final imageUrl = rawImageUrl != null && rawImageUrl.isNotEmpty
        ? rawImageUrl
        : (fallback?.imageUrl ?? '');

    final modifierEnabled = modifiers.containsKey('enabled')
        ? modifiers['enabled'] == true
        : json.containsKey('modifierEnabled')
        ? json['modifierEnabled'] == true
        : (fallback?.modifierEnabled ?? false);
    final rawGroups = modifiers['groups'] ?? json['modifierGroups'];
    final modifierGroup = rawGroups != null
        ? ModifierGroup.fromApi(rawGroups)
        : (fallback?.modifierGroup ?? const ModifierGroup());

    final trackExpiration = expiration.containsKey('trackExpiration')
        ? expiration['trackExpiration'] == true
        : json.containsKey('trackExpiration')
        ? json['trackExpiration'] == true
        : (fallback?.trackExpiration ?? false);
    final manufacturingDate =
        (expiration['manufacturingDate'] ?? json['manufacturingDate'])
            ?.toString() ??
        (fallback?.manufacturingDate ?? '');
    final expirationDate =
        (expiration['expirationDate'] ?? json['expirationDate'])?.toString() ??
        (fallback?.expirationDate ?? '');
    final rawAlertQty =
        expiration['alertQuantity'] ?? json['expirationAlertQuantity'];
    final alertQty = rawAlertQty == null
        ? fallback?.expirationAlertQuantity
        : _intFrom(rawAlertQty);

    final isActive = json.containsKey('isActive') || json.containsKey('active')
        ? (json['isActive'] ?? json['active']) != false
        : (fallback?.isActive ?? true);

    return InventoryProduct(
      id: json['id']?.toString() ?? fallback?.id,
      categoryName: json['categoryName']?.toString() ?? fallback?.categoryName,
      name: json['name']?.toString() ?? fallback?.name ?? 'Unnamed Item',
      description:
          json['description']?.toString() ?? fallback?.description ?? '',
      sku: json['sku']?.toString() ?? fallback?.sku ?? '',
      soldBy: json['soldBy']?.toString() ?? fallback?.soldBy ?? 'pcs',
      price:
          double.tryParse(
            '${matchedStore?['price'] ?? json['price'] ?? fallback?.price ?? 0}',
          ) ??
          0,
      cost:
          double.tryParse('${json['cost'] ?? fallback?.cost ?? 0}') ?? 0,
      barcode: json['barcode']?.toString() ?? fallback?.barcode ?? '',
      trackStock: trackStock,
      inStock: _intFrom(inStockRaw),
      lowStockThreshold: _intFrom(lowStockRaw),
      imageUrl: imageUrl,
      modifierEnabled: modifierEnabled,
      modifierGroup: modifierGroup,
      trackExpiration: trackExpiration,
      manufacturingDate: manufacturingDate,
      expirationDate: expirationDate,
      expirationAlertQuantity: alertQty,
      isActive: isActive,
    );
  }

  static int _intFrom(dynamic value) =>
      (double.tryParse('${value ?? 0}') ?? 0).round();
}
