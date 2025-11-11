import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firebase_notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    this.onNavigate,
    super.key,
  });

  final void Function(String action, Map<String, dynamic> data)? onNavigate;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الإشعارات',
          style: AppTypography.subheadline.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C2B33),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1C2B33)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF1C2B33)),
            onPressed: () => _markAllAsRead(userId),
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
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
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      timeAgo: _getTimeAgo(notification.createdAt),
                      onTap: () => _handleNotificationTap(notification),
                      onDismiss: () => _deleteNotification(notification.id),
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
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: AppCard(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  const SkeletonBox(width: 44, height: 44, borderRadius: 14),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLine(width: 150, height: 14),
                        SizedBox(height: 6.h),
                        const SkeletonLine(width: double.infinity),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const SkeletonLine(width: 60),
                ],
              ),
            ),
          ),
        ),
      ),
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
    if (widget.onNavigate != null && notification.data != null) {
      // استخراج action من data أو تحديده بناءً على نوع الإشعار
      String action;
      
      switch (notification.type) {
        case NotificationType.orderNew:
        case NotificationType.orderApproved:
        case NotificationType.orderRejected:
          action = 'view_order';
        case NotificationType.paymentNew:
        case NotificationType.paymentApproved:
        case NotificationType.paymentRejected:
          action = 'view_payments';
        default:
          action = notification.data!['action'] as String? ?? '';
      }
      
      if (action.isNotEmpty) {
        widget.onNavigate!(action, notification.data!);
      }
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
      case NotificationType.orderNew:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderApproved:
        return Icons.check_circle_outline;
      case NotificationType.orderRejected:
        return Icons.cancel_outlined;
      case NotificationType.paymentNew:
        return Icons.payments_outlined;
      case NotificationType.paymentApproved:
        return Icons.verified_outlined;
      case NotificationType.paymentRejected:
        return Icons.highlight_off_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationType.orderNew:
      case NotificationType.paymentNew:
        return AppColors.primary;
      case NotificationType.orderApproved:
      case NotificationType.paymentApproved:
        return AppColors.success;
      case NotificationType.orderRejected:
      case NotificationType.paymentRejected:
        return AppColors.error;
      default:
        return AppColors.gray600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 24.w),
      ),
      confirmDismiss: (direction) async {
        onDismiss();
        return false;
      },
      child: AppCard(
        padding: EdgeInsets.all(14.w),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                icon,
                color: color,
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
                      fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                      color: notification.isRead ? AppColors.gray700 : AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: AppTypography.micro.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.gray500,
                  ),
                ),
                if (!notification.isRead) ...[
                  SizedBox(height: 6.h),
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
