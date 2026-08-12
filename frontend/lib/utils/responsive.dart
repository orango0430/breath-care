import 'package:flutter/material.dart';

/// Screen Breakpoints for Responsive Design
class ResponsiveBreakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
}

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobileMax &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tabletMax;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Returns recommended maximum content width for readability on large screens (tablets)
  static double maxContentWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 800) {
      return 720;
    }
    return width;
  }

  /// Calculates responsive grid cross axis count based on screen width
  static int gridCrossAxisCount(BuildContext context, {int mobileCount = 2, int tabletCount = 4}) {
    if (isMobile(context)) {
      return mobileCount;
    } else {
      return tabletCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= ResponsiveBreakpoints.tabletMax && desktop != null) {
      return desktop!;
    }
    if (width >= ResponsiveBreakpoints.mobileMax && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Helper wrapper that centers content and limits max width on tablets for consistent layout
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
