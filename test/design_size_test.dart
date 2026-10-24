import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softverse/core/utils/responsive.dart';

void main() {
  test('Test design size calculation across devices', () {
    final devices = {
      'Phone Portrait (iPhone 14/15)': const Size(393, 852),
      'Phone Landscape': const Size(852, 393),
      'Tablet Portrait (800x1280)': const Size(800, 1280),
      'POS 10" Landscape (1280x800)': const Size(1280, 800),
      'POS 15.6" Landscape (1366x768)': const Size(1366, 768),
      'POS 15.6" Landscape (1920x1080)': const Size(1920, 1080),
    };

    for (final entry in devices.entries) {
      final size = entry.value;
      final ds = AppResponsive.getDesignSize(size);
      final sw = size.width / ds.width;
      final sh = size.height / ds.height;
      expect(sw, inInclusiveRange(0.8, 1.6));
      expect(sh, inInclusiveRange(0.8, 1.6));
    }
  });
}
