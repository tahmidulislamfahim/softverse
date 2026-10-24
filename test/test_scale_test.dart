import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softverse/core/utils/responsive.dart';

void main() {
  test('Test 1:1 scaling on landscape and widescreen', () {
    final landscapePhone = const Size(915, 412);
    final pos15Inch1080p = const Size(1920, 1080);
    final pos15Inch800p = const Size(1280, 800);

    for (final size in [landscapePhone, pos15Inch1080p, pos15Inch800p]) {
      final ds = AppResponsive.getDesignSize(size);
      expect(ds.width, equals(size.width));
      expect(ds.height, equals(size.height));
    }
  });
}
