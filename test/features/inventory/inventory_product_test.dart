import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:softverse/core/models/response_data.dart';
import 'package:softverse/core/services/network_caller.dart';
import 'package:softverse/core/services/storage_service.dart';
import 'package:softverse/features/inventory/controller/item_detail_controller.dart';
import 'package:softverse/features/inventory/models/inventory_product.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: 'BASE_URL=https://phase-one.test');
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  InventoryProduct product({
    String? id,
    required bool trackStock,
    required int inStock,
    int lowStock = 5,
  }) {
    return InventoryProduct(
      id: id,
      name: 'Item',
      sku: 'SKU',
      price: 10,
      cost: 5,
      barcode: 'BAR',
      trackStock: trackStock,
      inStock: inStock,
      lowStockThreshold: lowStock,
      imageUrl: '',
    );
  }

  test('untracked item has no stock status', () {
    final item = product(trackStock: false, inStock: 0);

    expect(item.stockLabel, isEmpty);
    expect(item.isOutOfStock, isFalse);
    expect(item.isLowStock, isFalse);
  });

  test('tracked item exposes in, low, and out statuses', () {
    expect(product(trackStock: true, inStock: 8).stockLabel, '8 In Stock');
    expect(product(trackStock: true, inStock: 5).stockLabel, 'Low Stock');
    expect(product(trackStock: true, inStock: 0).stockLabel, 'Out of Stock');
  });

  test(
    'item detail controller has no static modifiers by default and loads from API',
    () async {
      final caller = _FakeItemDetailCaller({
        'id': 'item-1',
        'name': 'Papier Thermal 58mm',
        'sku': 'PT-58',
        'soldBy': 'weight',
        'price': 50,
        'cost': 25,
        'barcode': '123456',
        'inventory': {'trackStock': true, 'inStock': 231, 'lowStock': 20},
        'modifiers': {
          'enabled': true,
          'groups': [
            {
              'label': 'Roll Bundle',
              'products': [
                {'name': '5 Rolls', 'price': 220},
                {'name': '10 Rolls', 'price': 400},
              ],
            },
          ],
        },
        'expiration': {
          'trackExpiration': true,
          'manufacturingDate': '2026-01-01',
          'expirationDate': '2028-01-01',
          'alertQuantity': 15,
        },
      });

      final initial = product(id: 'item-1', trackStock: true, inStock: 231);
      expect(initial.modifierEnabled, isFalse);
      expect(initial.modifierGroup.options, isEmpty);

      final controller = ItemDetailController(
        networkCaller: caller,
        initialProduct: initial,
      );
      controller.onInit();
      await Future<void>.delayed(Duration.zero);

      expect(caller.requestedUrls, ['https://phase-one.test/items/item-1']);
      expect(controller.product.name, 'Papier Thermal 58mm');
      expect(controller.soldBy.value, 'Weight');
      expect(controller.modifierEnabled.value, isTrue);
      expect(controller.modifierGroup.value.options.length, 1);
      expect(controller.modifierGroup.value.options.first.label, 'Roll Bundle');
      expect(
        controller.modifierGroup.value.options.first.products
            .map((p) => '${p.name}:${p.price}')
            .toList(),
        ['5 Rolls:220.0', '10 Rolls:400.0'],
      );
      expect(controller.trackExpiryDate.value, isTrue);
      expect(controller.manufacturingDate.value, '2026-01-01');
      expect(controller.expireDate.value, '2028-01-01');
      expect(controller.expirationAlertQuantity.value, 15);
    },
  );
}

class _FakeItemDetailCaller extends NetworkCaller {
  final Map<String, dynamic> payload;
  final requestedUrls = <String>[];

  _FakeItemDetailCaller(this.payload);

  @override
  Future<ResponseData> getRequest(String url, {String? token}) async {
    requestedUrls.add(url);
    return ResponseData(
      isSuccess: true,
      statusCode: 200,
      errorMessage: '',
      responseData: payload,
    );
  }
}
