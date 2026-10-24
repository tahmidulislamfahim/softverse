import 'package:flutter/material.dart';

/// Centralized responsive design utilities for Softverse.
/// Supports phones (portrait/landscape), tablets, and widescreen Android POS terminals (e.g. 15.6" 1080p/800p).
class AppResponsive {
  AppResponsive._();

  /// Standard breakpoints (in logical pixels)
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  /// Default max content widths for forms, cards, and dialogs on wide displays.
  static const double maxFormWidth = 540.0;
  static const double maxCardWidth = 720.0;
  static const double maxReceiptWidth = 480.0;
  static const double maxDialogWidth = 500.0;
  static const double maxContentWidth = 1100.0;

  /// Determines whether the current view is landscape based on width > height.
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  /// Determines whether the screen should use a dual-pane / split register layout
  /// (phones in landscape, tablets, or foldables opened to width >= 600).
  static bool isDualPane(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= mobileBreakpoint || size.width > size.height;
  }

  /// Determines whether the current view is considered a wide screen (tablet, unfolded fold, or POS terminal).
  static bool isWide(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= mobileBreakpoint || size.width > size.height;
  }

  /// Determines whether the screen is tablet/desktop scale (width >= 600).
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= mobileBreakpoint;
  }

  /// Calculates dynamic design size for [ScreenUtilInit].
  ///
  /// - Mobile Portrait (width < 600, height > width): 390x884 (Figma reference phone design)
  /// - Any Landscape (phones, tablets, and 15.6" POS terminals) or wide screens:
  ///   Returns 1:1 design size ([screenSize.width], [screenSize.height]).
  ///   This guarantees scale factors of exactly 1.0, preventing text, buttons, and
  ///   containers from being artificially magnified by 1.5x on 1080p POS displays or
  ///   oversized on landscape phones.
  static Size getDesignSize(Size screenSize) {
    final isLand = screenSize.width > screenSize.height;

    if (!isLand && screenSize.width < mobileBreakpoint) {
      return const Size(390, 884);
    }
    return Size(screenSize.width, screenSize.height);
  }

  /// Responsive toolbar height for AppBars.
  /// Uses compact height (46px) in landscape where vertical height is limited,
  /// and standard height (56-58px) in portrait.
  static double appBarHeight(BuildContext context, {double portraitHeight = 58.0}) {
    return isLandscape(context) ? 46.0 : portraitHeight;
  }

  /// Responsive icon size for AppBar action icons.
  static double appBarIconSize(BuildContext context, {double portraitSize = 26.0}) {
    return isLandscape(context) ? 22.0 : portraitSize;
  }

  /// Responsive title font size for AppBars.
  static double appBarTitleSize(BuildContext context, {double portraitSize = 20.0}) {
    return isLandscape(context) ? 16.0 : portraitSize;
  }

  /// Calculates responsive crossAxisCount for grids based on available width.
  static int gridAxisCount(
    BuildContext context, {
    double itemWidth = 180,
    int min = 2,
    int max = 6,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final count = (width / itemWidth).floor();
    return count.clamp(min, max);
  }

  /// Calculates responsive crossAxisCount given a specific width constraint.
  static int gridAxisCountForWidth(
    double width, {
    double itemWidth = 180,
    int min = 2,
    int max = 6,
  }) {
    final count = (width / itemWidth).floor();
    return count.clamp(min, max);
  }
}

/// A wrapper widget that centers its child and constrains its max width on wide screens.
/// On small screens (width < [maxWidth]), the child spans full width naturally.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppResponsive.maxFormWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// A responsive split-pane layout.
/// Displays [first] and [second] in a side-by-side [Row] on wide screens (width >= [breakpoint]),
/// or in a stacked [Column] on narrow screens.
class ResponsiveTwoPane extends StatelessWidget {
  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;
  final double spacing;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveTwoPane({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.spacing = 16,
    this.breakpoint = 800,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= breakpoint;
        if (isWide) {
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Expanded(flex: firstFlex, child: first),
              SizedBox(width: spacing),
              Expanded(flex: secondFlex, child: second),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: spacing),
              second,
            ],
          );
        }
      },
    );
  }
}
