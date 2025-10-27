import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ui_tokens.dart';
import 'package_card.dart';

/// Reusable list wrapper for displaying packages with:
/// - Optional loading skeletons
/// - Empty state placeholder
/// - Scrollable list of PackageCard widgets
class PackageListView extends StatelessWidget {
  const PackageListView({
    required this.items,
    super.key,
    this.isLoading = false,
    this.emptyMessage = 'لا توجد باقات متاحة',
    this.onRetry,
    this.onSelect,
    this.showQuantity = true,
    this.shrinkWrap = false,
    this.physics,
    this.selectionEnabled = false,
    this.selectedNames = const {},
    this.onToggleSelect,
  });

  final List<PackageCardData> items;
  final bool isLoading;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final ValueChanged<PackageCardData>? onSelect;
  final bool showQuantity;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool selectionEnabled; // enable visual selection state
  final Set<String> selectedNames; // simple unique key (name) for selection
  final ValueChanged<PackageCardData>? onToggleSelect; // toggles selection

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _SkeletonList(shrinkWrap: shrinkWrap, physics: physics);
    }
    if (items.isEmpty) {
      return _EmptyState(message: emptyMessage, onRetry: onRetry);
    }
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics:
          physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      padding: EdgeInsets.symmetric(vertical: 4.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final data = items[index];
        final selected = selectionEnabled && selectedNames.contains(data.name);
        return PackageCard(
          data: data,
          showQuantity: showQuantity,
          isSelected: selected,
          onTap: () {
            if (selectionEnabled) {
              onToggleSelect?.call(data);
            } else {
              onSelect?.call(data);
            }
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 40.w,
                color: AppColors.gray400,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(UITokens.radiusSm.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16.w, color: Colors.white),
                      SizedBox(width: 6.w),
                      Text(
                        'إعادة المحاولة',
                        style: TextStyle(fontSize: 13.sp, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.shrinkWrap, this.physics});
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics:
          physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      padding: EdgeInsets.symmetric(vertical: 4.h),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, __) => const _PackageSkeleton(),
    );
  }
}

class _PackageSkeleton extends StatefulWidget {
  const _PackageSkeleton();
  @override
  State<_PackageSkeleton> createState() => _PackageSkeletonState();
}

class _PackageSkeletonState extends State<_PackageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: .45, end: .9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _shimmer.value,
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 50.w, height: 50.w, radius: 14.r),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(width: 140.w, height: 14.h, radius: 6.r),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 6.h,
                        children: [
                          _chip(width: 70.w),
                          _chip(width: 60.w),
                          _chip(width: 66.w),
                          _chip(width: 80.w),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _block(width: 70.w, height: 12.h, radius: 4.r),
                    SizedBox(height: 8.h),
                    _block(width: 60.w, height: 20.h, radius: 6.r),
                    SizedBox(height: 16.h),
                    _block(width: 60.w, height: 12.h, radius: 4.r),
                    SizedBox(height: 8.h),
                    _block(width: 60.w, height: 20.h, radius: 6.r),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _block({
    required double width,
    required double height,
    double? radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(radius ?? 8.r),
      ),
    );
  }

  Widget _chip({required double width}) => Container(
        width: width,
        height: 22.h,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(8.r),
        ),
      );
}
