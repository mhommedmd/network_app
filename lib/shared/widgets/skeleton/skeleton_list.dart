import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// قائمة skeleton عامة
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
    this.spacing = 10,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? EdgeInsets.all(16.w),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing.h),
      itemBuilder: itemBuilder,
    );
  }
}

/// قائمة skeleton مع scroll
class SkeletonScrollList extends StatelessWidget {
  const SkeletonScrollList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
    this.spacing = 10,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? EdgeInsets.all(16.w),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding:
                EdgeInsets.only(bottom: index < itemCount - 1 ? spacing.h : 0),
            child: itemBuilder(context, index),
          ),
        ),
      ),
    );
  }
}
