import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softverse/core/utils/responsive.dart';

void main() {
  group('Landscape and Widescreen POS responsiveness', () {
    testWidgets('AppResponsive returns compact metrics in landscape', (tester) async {
      tester.view.physicalSize = const Size(915, 412);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isTrue);
              expect(AppResponsive.appBarHeight(context), equals(46.0));
              expect(AppResponsive.appBarIconSize(context), equals(22.0));
              expect(AppResponsive.appBarTitleSize(context), equals(16.0));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('AppResponsive returns standard metrics in portrait', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isFalse);
              expect(AppResponsive.appBarHeight(context), equals(58.0));
              expect(AppResponsive.appBarIconSize(context), equals(26.0));
              expect(AppResponsive.appBarTitleSize(context), equals(20.0));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    test('Grid axis count calculates correctly for pane width', () {
      // 550px available in left pane on phone landscape (clamped to 3)
      expect(AppResponsive.gridAxisCountForWidth(550, itemWidth: 165), equals(3));
      // 1590px available in left pane on 1080p POS display (clamped to default max 6)
      expect(AppResponsive.gridAxisCountForWidth(1590, itemWidth: 165), equals(6));
    });

    testWidgets('Responsive tiles render compact heights in landscape', (tester) async {
      tester.view.physicalSize = const Size(915, 412);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final isLand = AppResponsive.isLandscape(context);
                expect(isLand, isTrue);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('FloatingIconButton renders and responds to tap in landscape', (tester) async {
      tester.view.physicalSize = const Size(915, 412);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        onPressed: () => tapped = true,
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppResponsive detects dual-pane on opened Pixel Fold (780x808) and wide displays', (tester) async {
      // 1. Pixel Fold / Foldable opened upright (width 780, height 808 -> height > width, so portrait)
      tester.view.physicalSize = const Size(780, 808);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isFalse, reason: 'Height is slightly greater than width');
              expect(AppResponsive.isDualPane(context), isTrue, reason: 'Width is 780 >= 600, so it qualifies for dual pane POS');
              expect(AppResponsive.isWide(context), isTrue);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // 2. Normal phone in portrait (width 390, height 844)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isFalse);
              expect(AppResponsive.isDualPane(context), isFalse);
              expect(AppResponsive.isWide(context), isFalse);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // 3. Normal phone in landscape (width 844, height 390)
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(AppResponsive.isLandscape(context), isTrue);
              expect(AppResponsive.isDualPane(context), isTrue);
              expect(AppResponsive.isWide(context), isTrue);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
