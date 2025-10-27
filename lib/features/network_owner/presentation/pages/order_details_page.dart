import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/types/callbacks.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../data/mock_orders.dart';
import '../models/order_models.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({
    required this.orderId,
    required this.onBack,
    required this.onApprove,
    required this.onReject,
    required this.onOpenChat,
    super.key,
  });

  final int orderId;
  final VoidCallback onBack;
  final IntCallback onApprove;
  final IntCallback onReject;
  final StringCallback onOpenChat;

  OrderDetails get _mockOrderDetails {
    return findMockOrderById(orderId) ?? mockOrders.first;
  }

  void _handleApprove() {
    onApprove(orderId);
    onBack();
  }

  void _handleApprovePartial() {
    onApprove(orderId);
    onBack();
  }

  void _handleReject() {
    onReject(orderId);
    onBack();
  }

  void _handleOpenChat() {
    final order = findMockOrderById(orderId) ?? mockOrders.first;
    onOpenChat(order.vendor.id);
  }

  @override
  Widget build(BuildContext context) {
    final orderDetails = _mockOrderDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل الطلب #${orderDetails.id}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Vendor card
              AppCard(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          orderDetails.vendor.avatar,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderDetails.vendor.name,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: AppColors.gray500,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  orderDetails.vendor.owner,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: AppColors.gray500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                orderDetails.vendor.phone,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.gray600,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              const Icon(
                                Icons.place,
                                size: 14,
                                color: AppColors.gray500,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  orderDetails.vendor.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'مراسلة',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.small,
                      onPressed: _handleOpenChat,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Items card (table only, no external title)
              AppCard(
                padding: EdgeInsets.all(12.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.h,
                            horizontal: 10.w,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  'الباقة',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    'الكمية',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'السعر',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'الإجمالي',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    'المتاح',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.gray200,
                        ),

                        // Rows
                        ...List.generate(orderDetails.items.length, (index) {
                          final item = orderDetails.items[index];
                          final isLast = index == orderDetails.items.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8.h,
                                  horizontal: 10.w,
                                ),
                                child: Row(
                                  children: [
                                    // Package column
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (!item.isAvailable)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 4.w,
                                                  ),
                                                  child: const Icon(
                                                    Icons.warning,
                                                    size: 14,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  item.packageName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.gray900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            '${item.dataSize} • ${item.validity}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.gray600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Quantity
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          '${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray800,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Price (unit)
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          CurrencyFormatter.format(
                                            item.unitPrice,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray800,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Total (quantity * price)
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          CurrencyFormatter.format(
                                            item.totalPrice,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Available (moved to last)
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          '${item.availableStock}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: item.isAvailable
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.gray100,
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              // Summary card
              AppCard(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'إجمالي الكروت',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${orderDetails.totalItems}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'أنواع الباقات',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${orderDetails.items.length}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'القيمة الإجمالية',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.gray600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          CurrencyFormatter.format(orderDetails.totalAmount),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (orderDetails.hasInsufficientStock) ...[
                SizedBox(height: 12.h),
                AppCard(
                  padding: EdgeInsets.all(12.w),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'تنبيه: بعض البنود لا تتوفر بالكمية المطلوبة في المخزون',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.errorDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 12.h),

              // Actions (centered, slightly larger, matches Orders style)
              AppCard(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      text: 'رفض',
                      variant: AppButtonVariant.error,
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تأكيد الرفض'),
                            content:
                                const Text('هل أنت متأكد من رفض هذا الطلب؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('تأكيد'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed ?? false) {
                          _handleReject();
                        }
                      },
                    ),
                    SizedBox(width: 12.w),
                    AppButton(
                      text: 'موافقة',
                      variant: AppButtonVariant.success,
                      onPressed: () async {
                        final allAvailable = orderDetails.allItemsAvailable;
                        if (allAvailable) {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الموافقة'),
                              content:
                                  const Text('هل تريد الموافقة على هذا الطلب؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('تأكيد'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed ?? false) {
                            _handleApprove();
                          }
                        } else {
                          final confirmedPartial = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('نقص في المخزون'),
                              content: const Text(
                                'الكمية المطلوبة غير متوفرة في المخزون.\nهل تريد إرسال الكمية المتاحة فقط؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('تأكيد'),
                                ),
                              ],
                            ),
                          );
                          if (confirmedPartial ?? false) {
                            _handleApprovePartial();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
