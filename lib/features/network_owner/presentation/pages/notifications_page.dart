import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/widgets/app_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = <_NotificationData>[
      const _NotificationData(
        title: 'طلب جديد من متجر بيع',
        subtitle: 'تم استلام طلب جديد من أحد المتاجر التابعة للشبكة',
        icon: Icons.shopping_bag_outlined,
        timestamp: 'منذ 5 دقائق',
      ),
      const _NotificationData(
        title: 'تمت المصادقة على الدفعة النقدية',
        subtitle: 'تمت الموافقة على الدفعة النقدية الأخيرة من المتجر',
        icon: Icons.verified_outlined,
        timestamp: 'قبل ساعة',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: AppTypography.subheadline.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, index) {
                final notification = notifications[index];
                return AppCard(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          notification.icon,
                          color: AppColors.primary,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTypography.body.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              notification.subtitle,
                              style: AppTypography.caption.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        notification.timestamp,
                        style: AppTypography.micro.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationData {
  const _NotificationData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.timestamp,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String timestamp;
}
