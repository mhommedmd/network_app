import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ui_tokens.dart';

enum AppButtonVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  outline,
  ghost,
}

enum AppButtonSize {
  small,
  medium,
  large,
  extraLarge,
}

class AppButton extends StatefulWidget {
  const AppButton({
    required this.text,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
    this.animated = true,
    this.padding,
    this.borderRadius,
  });
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool loading;
  final bool fullWidth;
  final bool animated;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
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

  Color _getBackgroundColor() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.success:
        return AppColors.success;
      case AppButtonVariant.warning:
        return AppColors.warning;
      case AppButtonVariant.error:
        return AppColors.error;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.success:
      case AppButtonVariant.warning:
      case AppButtonVariant.error:
        return Colors.white;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  BorderSide? _getBorder() {
    switch (widget.variant) {
      case AppButtonVariant.outline:
        return const BorderSide(color: AppColors.primary, width: 1.5);
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.success:
      case AppButtonVariant.warning:
      case AppButtonVariant.error:
      case AppButtonVariant.ghost:
        return null;
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 32.h;
      case AppButtonSize.medium:
        return 44.h;
      case AppButtonSize.large:
        return 52.h;
      case AppButtonSize.extraLarge:
        return 60.h;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.padding != null) return widget.padding!;

    switch (widget.size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w);
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 24.w);
      case AppButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 32.w);
      case AppButtonSize.extraLarge:
        return EdgeInsets.symmetric(horizontal: 48.w);
    }
  }

  TextStyle _resolveTextStyle() {
    // Base button token
    var style = AppTypography.button;
    switch (widget.size) {
      case AppButtonSize.small:
        style = style.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w500);
      case AppButtonSize.medium:
        style = style.copyWith(fontSize: 14.sp);
      case AppButtonSize.large:
        style = style.copyWith(fontSize: 16.sp);
      case AppButtonSize.extraLarge:
        style = style.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w600);
    }
    return style.copyWith(color: _getTextColor());
  }

  BoxShadow? _getShadow() {
    if (widget.variant == AppButtonVariant.outline ||
        widget.variant == AppButtonVariant.ghost) {
      return null;
    }

    return BoxShadow(
      color: _getBackgroundColor().withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.animated) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.animated) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.animated) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: _getHeight(),
      width: widget.fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
        border:
            _getBorder() != null ? Border.fromBorderSide(_getBorder()!) : null,
        boxShadow: _getShadow() != null ? [_getShadow()!] : null,
        gradient: widget.variant == AppButtonVariant.primary
            ? AppColors.primaryGradient
            : widget.variant == AppButtonVariant.secondary
                ? AppColors.secondaryGradient
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.loading ? null : widget.onPressed,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
          child: Container(
            padding: _getPadding(),
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading) ...[
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getTextColor()),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ] else if (widget.icon != null) ...[
                  widget.icon!,
                  SizedBox(width: 8.w),
                ],
                Flexible(
                  child: Text(
                    widget.text,
                    style: _resolveTextStyle(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.animated) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        ),
      );
    }

    return button;
  }
}
