import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/responsive.dart';
import '../../controller/category_controller.dart';
import '../../widgets/color_shape_picker.dart';

class CategoryFormScreen extends GetView<CategoryFormController> {
  const CategoryFormScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(controller.isEditing ? 'Edit Category' : 'Create Category'),
    ),
    body: ResponsiveCenter(
      maxWidth: 600,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: controller.nameController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.descriptionController,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'POS color and shape',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Obx(
            () => ColorShapePicker(
              selectedColorIndex: controller.selectedColorIndex.value,
              onColorSelected: controller.selectColor,
              selectedShapeIndex: controller.selectedShapeIndex.value,
              onShapeSelected: controller.selectShape,
            ),
          ),
          if (controller.isEditing)
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text(
                  'Inactive categories cannot be selected for items.',
                ),
                value: controller.isActive.value,
                onChanged: (value) => controller.isActive.value = value,
              ),
            ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign Items (${controller.selectedItemIds.length} selected)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (controller.isLoadingItems.value)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => controller.itemSearchQuery.value = value,
            decoration: const InputDecoration(
              hintText: 'Search items to assign to this category...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final items = controller.filteredAvailableItems;
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.isLoadingItems.value
                      ? 'Loading business items...'
                      : 'No items found.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Obx(() {
                    final checked = controller.selectedItemIds.contains(
                      item.id,
                    );
                    final existingCategory = item.categoryName?.trim();
                    final subtitleParts = <String>[
                      if (item.sku.trim().isNotEmpty) 'SKU: ${item.sku.trim()}',
                      if (existingCategory != null &&
                          existingCategory.isNotEmpty)
                        'Category: $existingCategory',
                    ];
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      onChanged: (_) => controller.toggleItemSelection(item.id),
                      title: Text(item.name),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(subtitleParts.join(' • ')),
                    );
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 20),
          Obx(
            () => FilledButton(
              onPressed: controller.isSaving.value ? null : controller.save,
              child: controller.isSaving.value
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    ),
  );
}
