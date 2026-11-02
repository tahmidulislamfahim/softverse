class ModifierProduct {
  final String name;
  final double price;

  const ModifierProduct({required this.name, required this.price});

  factory ModifierProduct.fromApi(Map<String, dynamic> json) {
    return ModifierProduct(
      name: json['name']?.toString() ?? '',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
    );
  }
}

class ModifierOption {
  final String label;
  final List<ModifierProduct> products;

  const ModifierOption({required this.label, required this.products});

  factory ModifierOption.fromApi(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = (rawProducts is List ? rawProducts : const [])
        .whereType<Map>()
        .map(
          (product) =>
              ModifierProduct.fromApi(Map<String, dynamic>.from(product)),
        )
        .where((product) => product.name.isNotEmpty)
        .toList(growable: false);
    return ModifierOption(
      label: json['label']?.toString() ?? '',
      products: products,
    );
  }
}

class ModifierGroup {
  final List<ModifierOption> options;

  const ModifierGroup({this.options = const []});

  factory ModifierGroup.fromApi(dynamic rawGroups) {
    if (rawGroups is! List) return const ModifierGroup();
    final options = rawGroups
        .whereType<Map>()
        .map((group) => ModifierOption.fromApi(Map<String, dynamic>.from(group)))
        .where((option) => option.label.isNotEmpty || option.products.isNotEmpty)
        .toList(growable: false);
    return ModifierGroup(options: options);
  }
}
