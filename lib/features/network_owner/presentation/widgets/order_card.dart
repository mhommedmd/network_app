import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/order_model.dart';

/// بطاقة عرض الطلب
class OrderCard extends StatelessWidget {
  const OrderCard({
    required this.order,
    this.onApprove,
    this.onReject,
    super.key,
  });

  final OrderModel order;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color get _statusColor {
    switch (order.status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  String get _statusText {
    switch (order.status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'مرفوض';
      default:
        return order.status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('dd/MM/yyyy', 'ar').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف العلوي: اسم المتجر + الحالة
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.vendorName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border:
                      Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),
          Divider(color: AppColors.gray200, height: 1),
          SizedBox(height: 16.h),

          // تفاصيل الطلب - قائمة الباقات
          ...order.items.map((item) {
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 18.w, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.packageName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${item.quantity} كرت × ${CurrencyFormatter.format(item.pricePerCard)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.totalAmount),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 12.h),

          // إجمالي الكروت
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined,
                  size: 18.w, color: AppColors.gray500),
              SizedBox(width: 8.w),
              Text(
                'إجمالي الكروت: ${order.totalCards}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // المجموع
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المجموع الكلي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(order.totalAmount),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // أزرار الإجراءات
          SizedBox(height: 16.h),
          Row(
            children: [
              if (onReject != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: order.status == 'pending' ? onReject : null,
                    icon: Icon(
                      Icons.close,
                      color: order.status == 'pending'
                          ? AppColors.error
                          : AppColors.gray400,
                      size: 18.w,
                    ),
                    label: Text(
                      'رفض',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: order.status == 'pending'
                          ? AppColors.error
                          : AppColors.gray400,
                      side: BorderSide(
                        color: order.status == 'pending'
                            ? AppColors.error
                            : AppColors.gray300,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              if (onReject != null && onApprove != null) SizedBox(width: 12.w),
              if (onApprove != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: order.status == 'pending' ? onApprove : null,
                    icon: Icon(
                      Icons.check,
                      color: order.status == 'pending'
                          ? Colors.white
                          : AppColors.gray400,
                      size: 18.w,
                    ),
                    label: Text(
                      'موافقة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: order.status == 'pending'
                          ? AppColors.success
                          : AppColors.gray300,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// رقاقة الفلتر
class FilterChip extends StatelessWidget {
  const FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : bgColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? bgColor : bgColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : bgColor,
          ),
        ),
      ),
    );
  }
}
