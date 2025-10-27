import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

/// Widget لإضافة Pull-to-Refresh بسهولة
class PullToRefreshWrapper extends StatelessWidget {
  const PullToRefreshWrapper({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? Colors.white,
      strokeWidth: 3.0,
      displacement: 60.h,
      child: child,
    );
  }
}

/// Widget لإضافة Pull-to-Refresh مع رسالة مخصصة
class PullToRefreshWithMessage extends StatefulWidget {
  const PullToRefreshWithMessage({
    super.key,
    required this.onRefresh,
    required this.child,
    this.refreshMessage = 'جاري التحديث...',
    this.color,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final String refreshMessage;
  final Color? color;

  @override
  State<PullToRefreshWithMessage> createState() =>
      _PullToRefreshWithMessageState();
}

class _PullToRefreshWithMessageState extends State<PullToRefreshWithMessage> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: widget.color ?? AppColors.primary,
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          displacement: 60.h,
          child: widget.child,
        ),
        if (_isRefreshing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.color ?? AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      widget.refreshMessage,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
