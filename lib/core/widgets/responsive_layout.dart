import 'package:flutter/material.dart';

/// Standard screen breakpoint definitions for CryoRoots
class ResponsiveBreakpoints {
  static const double mobileMax = 599.0;
  static const double tabletMax = 899.0;
  static const double desktopMin = 900.0;
  static const double maxContentWidth = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileMax && width < desktopMin;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMin;

  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopMin) return 24.0;
    if (width > mobileMax) return 20.0;
    return 16.0;
  }
}

/// A wrapper widget that centers content and constrains its maximum width
/// on desktop and wide screens, preventing distorted or bloated stretched layouts.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal:
                    ResponsiveBreakpoints.responsiveHorizontalPadding(context),
              ),
          child: child,
        ),
      ),
    );
  }
}
