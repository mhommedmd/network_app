import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../network_owner/data/models/notification_model.dart';
import '../../../network_owner/data/services/firebase_notification_service.dart';

class PosVendorNotificationsPage extends StatefulWidget {
  const PosVendorNotificationsPage({super.key});

  @override
  State<PosVendorNotificationsPage> createState() =>
      _PosVendorNotificationsPageState();
}

class _PosVendorNotificationsPageState
    extends State<PosVendorNotificationsPage> {
  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: const Center(child: Text('يرجى تسجيل الدخول')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () => _markAllAsRead(userId),
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: StreamBuilder<List<NotificationModel>>(
            stream: FirebaseNotificationService.getUserNotifications(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSkeleton();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // سيتم التحديث تلقائياً من Stream
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                },
                color: AppColors.primary,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _NotificationCard(
                        notification: notification,
                        timeAgo: _getTimeAgo(notification.createdAt),
                        onTap: () => _handleNotificationTap(notification),
                        onDismiss: () =>
                            _deleteNotification(notification.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, borderRadius: 10),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 150, height: 14),
                          SizedBox(height: 6),
                          SkeletonLine(width: 100, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: AppCard(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.w, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              'خطأ في تحميل الإشعارات',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48.w,
              color: AppColors.gray400,
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد إشعارات',
              style: AppTypography.body.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'ستظهر هنا الإشعارات عند وصولها',
              style: AppTypography.caption.copyWith(
                fontSize: 12.sp,
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      await FirebaseNotificationService.markAllAsRead(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد جميع الإشعارات كمقروءة'),
          duration: Duration(seconds: 2),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التحديث: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseNotificationService.deleteNotification(notificationId);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحذف: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // تحديد الإشعار كمقروء
    if (!notification.isRead) {
      FirebaseNotificationService.markAsRead(notification.id);
    }

    // التنقل حسب نوع الإشعار
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.orderApproved:
      case NotificationType.orderRejected:
        // الانتقال إلى صفحة الشبكات أو الطلبات
        if (context.mounted) {
          context.go('/networks');
        }
      case NotificationType.paymentNew:
        // الانتقال إلى صفحة الدفعات النقدية
        if (context.mounted) {
          context.go('/cash-payments');
        }
      default:
    }
  }
}

/// بطاقة الإشعار
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationModel notification;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  static IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationType.orderApproved:
        return Icons.check_circle_outline;
      case NotificationType.orderRejected:
        return Icons.cancel_outlined;
      case NotificationType.paymentNew:
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationType.orderApproved:
        return AppColors.success;
      case NotificationType.orderRejected:
        return AppColors.error;
      case NotificationType.paymentNew:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24.w),
            SizedBox(width: 8.w),
            Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? color.withValues(alpha: 0.05) : null,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AppCard(
          onTap: onTap,
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: color,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isUnread)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          margin: EdgeInsets.only(left: 6.w),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

