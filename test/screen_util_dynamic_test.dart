import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:softverse/core/utils/responsive.dart';

void main() {
  testWidgets('ScreenUtil dynamic update on rotation', (tester) async {
    // Start at Portrait 390x844
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      OrientationBuilder(
        builder: (context, orientation) {
          final media = MediaQueryData.fromView(View.of(context));
          final designSize = AppResponsive.getDesignSize(media.size);
          return ScreenUtilInit(
            key: ValueKey('${designSize.width}_${designSize.height}'),
            designSize: designSize,
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      Text('W: ${100.w.toStringAsFixed(1)}'),
                      Text('H: ${100.h.toStringAsFixed(1)}'),
                      Text('Orientation: $orientation'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('W: 100.0'), findsOneWidget);

    // Rotate to 15.6" POS Landscape: 1280x800
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    expect(find.text('Orientation: Orientation.landscape'), findsOneWidget);
    expect(find.text('W: 100.0'), findsOneWidget);
    expect(find.text('H: 100.0'), findsOneWidget);

    // Test at 1920x1080 (widescreen POS keeps 1:1 scale)
    tester.view.physicalSize = const Size(1920, 1080);
    await tester.pumpAndSettle();

    expect(find.text('Orientation: Orientation.landscape'), findsOneWidget);
    expect(find.text('W: 100.0'), findsOneWidget);
    expect(find.text('H: 100.0'), findsOneWidget);
  });
}
