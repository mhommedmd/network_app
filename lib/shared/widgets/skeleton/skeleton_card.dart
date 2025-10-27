import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_card.dart';
import 'skeleton_loading.dart';

/// بطاقة skeleton قياسية
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 150, height: 16),
          SizedBox(height: 8.h),
          const SkeletonLine(width: 100, height: 12),
        ],
      ),
    );
  }
}

/// بطاقة skeleton مع أيقونة
class SkeletonCardWithIcon extends StatelessWidget {
  const SkeletonCardWithIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const SkeletonCircle(size: 50),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(width: 120, height: 14),
                SizedBox(height: 6.h),
                const SkeletonLine(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة skeleton للمعاملات
class SkeletonTransactionCard extends StatelessWidget {
  const SkeletonTransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          SkeletonBox(
            width: 40.w,
            height: 40,
            borderRadius: 10,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(width: 150, height: 13),
                SizedBox(height: 4.h),
                const SkeletonLine(width: 100, height: 11),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SkeletonLine(width: 60, height: 15),
              SizedBox(height: 4.h),
              const SkeletonLine(width: 30, height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة skeleton للباقة
class SkeletonPackageCard extends StatelessWidget {
  const SkeletonPackageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLine(width: 100, height: 16),
              SkeletonBox(
                width: 60.w,
                height: 24,
                borderRadius: 12,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const SkeletonLine(width: double.infinity, height: 12),
          SizedBox(height: 6.h),
          const SkeletonLine(width: 150, height: 12),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Expanded(child: SkeletonLine(height: 12)),
              SizedBox(width: 12.w),
              const Expanded(child: SkeletonLine(height: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة skeleton للطلب
class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SkeletonCircle(size: 40),
                  SizedBox(width: 12.w),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 100, height: 14),
                      SizedBox(height: 6),
                      SkeletonLine(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
              SkeletonBox(
                width: 70.w,
                height: 24,
                borderRadius: 12,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(),
          SizedBox(height: 8.h),
          const SkeletonLine(width: 120, height: 12),
          SizedBox(height: 6.h),
          const SkeletonLine(width: 90, height: 12),
        ],
      ),
    );
  }
}
