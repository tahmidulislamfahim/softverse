class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final int itemCount;
  final int colorIndex;
  final String? shape;
  final List<String> itemIds;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.itemCount = 0,
    this.colorIndex = 0,
    this.shape,
    this.itemIds = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawItemIds = json['itemIds'] ?? json['items'];
    final parsedIds = <String>[];
    if (rawItemIds is List) {
      for (final entry in rawItemIds) {
        if (entry is Map) {
          final id = entry['id']?.toString().trim();
          if (id != null && id.isNotEmpty) parsedIds.add(id);
        } else if (entry != null) {
          final id = entry.toString().trim();
          if (id.isNotEmpty) parsedIds.add(id);
        }
      }
    }
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['isActive'] != false,
      itemCount:
          int.tryParse(json['itemCount']?.toString() ?? '') ??
          parsedIds.length,
      colorIndex: int.tryParse(json['colorIndex']?.toString() ?? '') ?? 0,
      shape: json['shape']?.toString(),
      itemIds: parsedIds,
    );
  }
}
