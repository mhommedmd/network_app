import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

enum AppCardVariant {
  elevated,
  outlined,
  glass,
  gradient,
}

class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.animated = true,
    this.elevation,
    this.border,
  });
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool animated;
  final double? elevation;
  final Border? border;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _elevationAnimation = Tween<double>(
      begin: _getDefaultElevation(),
      end: _getDefaultElevation() + 4,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getDefaultElevation() {
    switch (widget.variant) {
      case AppCardVariant.elevated:
        return widget.elevation ?? 4.0;
      case AppCardVariant.outlined:
        return widget.elevation ?? 0.0;
      case AppCardVariant.glass:
        return widget.elevation ?? 8.0;
      case AppCardVariant.gradient:
        return widget.elevation ?? 6.0;
    }
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case AppCardVariant.elevated:
      case AppCardVariant.outlined:
        return Colors.white;
      case AppCardVariant.glass:
        return Colors.white.withValues(alpha: 0.8);
      case AppCardVariant.gradient:
        return Colors.transparent;
    }
  }

  BoxDecoration _getDecoration() {
    return BoxDecoration(
      color: widget.gradient == null ? _getBackgroundColor() : null,
      gradient: widget.gradient ?? _getDefaultGradient(),
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
      border: widget.border ?? _getDefaultBorder(),
      boxShadow: _getShadow(),
    );
  }

  Gradient? _getDefaultGradient() {
    switch (widget.variant) {
      case AppCardVariant.gradient:
        return AppColors.primaryGradient;
      case AppCardVariant.elevated:
      case AppCardVariant.outlined:
      case AppCardVariant.glass:
        return null;
    }
  }

  Border? _getDefaultBorder() {
    switch (widget.variant) {
      case AppCardVariant.outlined:
        return Border.all(color: AppColors.gray200);
      case AppCardVariant.elevated:
      case AppCardVariant.glass:
      case AppCardVariant.gradient:
        return null;
    }
  }

  List<BoxShadow>? _getShadow() {
    final elevation =
        widget.animated ? _elevationAnimation.value : _getDefaultElevation();

    if (elevation == 0) return null;

    switch (widget.variant) {
      case AppCardVariant.elevated:
        return [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ];
      case AppCardVariant.glass:
        return [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ];
      case AppCardVariant.gradient:
        return [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ];
      case AppCardVariant.outlined:
        return null;
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.animated && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.animated && widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.animated && widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: widget.margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
          child: Container(
            padding: widget.padding ?? EdgeInsets.all(16.w),
            decoration: _getDecoration(),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.animated && widget.onTap != null) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            child: Material(
              color: Colors.transparent,
              elevation: _elevationAnimation.value,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius:
                    widget.borderRadius ?? BorderRadius.circular(16.r),
                child: Container(
                  padding: widget.padding ?? EdgeInsets.all(16.w),
                  decoration: _getDecoration(),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return card;
  }
}

class AppCardHeader extends StatelessWidget {
  const AppCardHeader({
    required this.child,
    super.key,
    this.padding,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: 12.h),
      child: child,
    );
  }
}

class AppCardContent extends StatelessWidget {
  const AppCardContent({
    required this.child,
    super.key,
    this.padding,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
  }
}

class AppCardTitle extends StatelessWidget {
  const AppCardTitle({
    required this.title,
    super.key,
    this.style,
  });
  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ??
          Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
    );
  }
}
