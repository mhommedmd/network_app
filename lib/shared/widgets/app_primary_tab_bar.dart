import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

/// Unified primary tab bar used across POS Vendor & Network Owner contexts.
/// Features:
/// - Consistent height, rounded indicator
/// - Optional count badges per tab
/// - Supports icons + text
/// - Adaptive theming (light over colored backgrounds)
class AppPrimaryTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPrimaryTabBar({
    required this.tabs,
    super.key,
    this.controller,
    this.onTap,
    this.style = AppTabBarStyle.glass,
    this.isDense = false,
    this.backgroundColor,
    this.indicatorColor,
    this.padding,
    this.enableBlur = true,
    this.blurSigma = 14,
    this.scrollable = false,
    this.underlineThickness = 3,
    this.radius,
    this.badgeColor,
    this.outlineColor,
  });

  final List<AppPrimaryTab> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final AppTabBarStyle style;
  final bool isDense;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final EdgeInsetsGeometry? padding;
  final bool enableBlur;
  final double blurSigma;
  final bool scrollable;
  final double underlineThickness;
  final double? radius;
  final Color? badgeColor;
  final Color? outlineColor;

  @override
  Size get preferredSize => Size.fromHeight(isDense ? 46.h : 58.h);

  bool get _isUnderline => style == AppTabBarStyle.underline;
  bool get _isMinimal => style == AppTabBarStyle.minimal;
  bool get _isFilledSegment => style == AppTabBarStyle.filledSegment;

  @override
  Widget build(BuildContext context) {
    final indicatorClr = indicatorColor ?? AppColors.primary;
    final r = radius ?? 16.r;

    final effectiveBg = () {
      switch (style) {
        case AppTabBarStyle.glass:
          return backgroundColor ?? Colors.white.withValues(alpha: 0.12);
        case AppTabBarStyle.filled:
          return backgroundColor ??
              AppColors.primaryDark.withValues(alpha: 0.35);
        case AppTabBarStyle.filledSegment:
          return backgroundColor ?? Colors.white;
        case AppTabBarStyle.underline:
        case AppTabBarStyle.minimal:
          return Colors.transparent;
      }
    }();

    final tabBar = TabBar(
      isScrollable: scrollable,
      controller: controller,
      onTap: onTap,
      indicatorSize:
          _isUnderline ? TabBarIndicatorSize.label : TabBarIndicatorSize.tab,
      indicator: _isUnderline
          ? UnderlineTabIndicator(
              borderSide:
                  BorderSide(color: indicatorClr, width: underlineThickness),
              insets: EdgeInsets.symmetric(horizontal: 12.w),
            )
          : (_isMinimal
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(r * 0.6),
                  color: indicatorClr.withValues(alpha: 0.18),
                )
              : _isFilledSegment
                  ? BoxDecoration(
                      color: indicatorClr,
                      borderRadius: BorderRadius.circular(12.r),
                    )
                  : BoxDecoration(
                      color: indicatorClr,
                      borderRadius: BorderRadius.circular(r * 0.55),
                      boxShadow: [
                        BoxShadow(
                          color: indicatorClr.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    )),
      splashBorderRadius: BorderRadius.circular(r * 0.6),
      labelColor: () {
        if (style == AppTabBarStyle.underline ||
            style == AppTabBarStyle.minimal) {
          return indicatorClr; // active label color for underline/minimal
        }
        // For filledSegment and other filled styles we want white active text.
        return Colors.white;
      }(),
      unselectedLabelColor: () {
        if (style == AppTabBarStyle.underline ||
            style == AppTabBarStyle.minimal) {
          return AppColors.gray600;
        }
        if (style == AppTabBarStyle.filledSegment) {
          // Inactive text inside white segment container uses black per design request
          return Colors.black;
        }
        return Colors.white.withValues(alpha: 0.68);
      }(),
      labelStyle: TextStyle(
        fontSize: (isDense ? 12 : 14).sp,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: (isDense ? 12 : 14).sp,
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        for (final t in tabs)
          _TabContent(
            tab: t,
            dense: isDense,
            badgeColor: badgeColor,
            style: style,
          ),
      ],
    );

    if (_isUnderline || _isMinimal) {
      return _wrapBase(tabBar, r, effectiveBg, applyChrome: false);
    }
    if (_isFilledSegment) {
      return _wrapBase(
        tabBar,
        r,
        effectiveBg,
        outlineColor: outlineColor ?? AppColors.gray200,
      );
    }
    return _wrapBase(tabBar, r, effectiveBg);
  }

  Widget _wrapBase(
    Widget tabBar,
    double r,
    Color bg, {
    bool applyChrome = true,
    bool addSeparators = false,
    Color? outlineColor,
  }) {
    final content = Container(
      height: preferredSize.height,
      padding: padding ??
          EdgeInsets.symmetric(horizontal: 14.w, vertical: isDense ? 4.h : 6.h),
      decoration: applyChrome
          ? BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(r),
              border: outlineColor != null
                  ? Border.all(color: outlineColor)
                  : style == AppTabBarStyle.filledSegment
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
            )
          : null,
      child: Stack(
        children: [
          if (addSeparators)
            Positioned.fill(
              child: Row(
                children: [
                  for (int i = 0; i < tabs.length - 1; i++) ...[
                    const Expanded(child: SizedBox()),
                    Container(
                      width: 1,
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      color: AppColors.gray200.withValues(alpha: 0.9),
                    ),
                  ],
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          tabBar,
        ],
      ),
    );

    if (!enableBlur ||
        style == AppTabBarStyle.filled ||
        style == AppTabBarStyle.minimal ||
        style == AppTabBarStyle.filledSegment) {
      return content;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}

enum AppTabBarStyle { glass, filled, underline, minimal, filledSegment }

class AppPrimaryTab {
  const AppPrimaryTab({
    required this.label,
    this.icon,
    this.count,
    this.customBadge,
  });
  final String label;
  final IconData? icon;
  final int? count;
  final Widget? customBadge; // advanced use-case
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tab,
    required this.dense,
    required this.style,
    this.badgeColor,
  });
  final AppPrimaryTab tab;
  final bool dense;
  final AppTabBarStyle style;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final showCount = tab.count != null || tab.customBadge != null;
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: (dense ? 12 : 14).sp,
          fontWeight: FontWeight.w600,
        );
    return Tab(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey('${tab.label}_${tab.count}_${dense}_${style.name}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tab.icon != null) ...[
                  Icon(tab.icon, size: (dense ? 14 : 18).w),
                  SizedBox(width: 6.w),
                ],
                Text(tab.label, style: textStyle),
                if (showCount) ...[
                  SizedBox(width: 6.w),
                  tab.customBadge ??
                      _CountBadge(
                        count: tab.count ?? 0,
                        color: style == AppTabBarStyle.filledSegment
                            ? Colors.red
                            : (badgeColor ?? Colors.red),
                        compact: dense,
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.color, this.compact = false});
  final int count;
  final Color? color;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.white.withValues(alpha: 0.22);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5.w : 7.w,
        vertical: compact ? 2.h : 3.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: (compact ? 10 : 11).sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
