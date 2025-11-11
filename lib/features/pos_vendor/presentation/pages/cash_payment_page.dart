import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton/skeleton_loading.dart';
import '../../../../shared/widgets/toast/toast.dart';
import '../../../network_owner/data/models/cash_payment_request_model.dart';
import '../../../network_owner/data/services/firebase_cash_payment_service.dart';

class PosVendorCashPaymentsPage extends StatefulWidget {
  const PosVendorCashPaymentsPage({
    required this.onBack,
    super.key,
  });

  final VoidCallback onBack;

  @override
  State<PosVendorCashPaymentsPage> createState() => _PosVendorCashPaymentsPageState();
}

class _PosVendorCashPaymentsPageState extends State<PosVendorCashPaymentsPage> {
  late final String _vendorId;

  @override
  void initState() {
    super.initState();
    _vendorId = context.read<AuthProvider>().user?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final vendorId = _vendorId;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F5F8),
        surfaceTintColor: const Color(0xFFF1F5F8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'الدفعات النقدية',
          style: AppTypography.subheadline.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onBack,
        ),
      ),
      body: Container(
        color: const Color(0xFFF1F5F8),
        child: SafeArea(
          child: StreamBuilder<List<CashPaymentRequestModel>>(
            stream: FirebaseCashPaymentService.getVendorPaymentRequests(vendorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingSkeleton();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final requests = snapshot.data ?? [];

              if (requests.isEmpty) {
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
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _PaymentRequestCard(request: request);
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
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: AppCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonBox(width: 44, height: 44, borderRadius: 14),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SkeletonLine(width: 120, height: 14),
                            SizedBox(height: 6.h),
                            const SkeletonLine(width: 80),
                          ],
                        ),
                      ),
                      const SkeletonBox(width: 80, height: 24, borderRadius: 12),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  const SkeletonLine(width: double.infinity),
                  SizedBox(height: 8.h),
                  const SkeletonLine(width: 200),
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
              'خطأ في تحميل الدفعات',
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
            Icon(Icons.payments_outlined, size: 48.w, color: AppColors.gray400),
            SizedBox(height: 16.h),
            Text(
              'لا توجد دفعات حالياً',
              style: AppTypography.body.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'ستظهر هنا طلبات الدفعات النقدية من الشبكات',
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
}

/// بطاقة طلب الدفعة
class _PaymentRequestCard extends StatefulWidget {
  const _PaymentRequestCard({required this.request});

  final CashPaymentRequestModel request;

  @override
  State<_PaymentRequestCard> createState() => _PaymentRequestCardState();
}

class _PaymentRequestCardState extends State<_PaymentRequestCard> {
  bool _processing = false;

  Future<void> _handleApprove() async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text(
          'هل تؤكد على صحة مبلغ ${widget.request.amount.toStringAsFixed(0)} ر.ي المدفوع نقداً الى ${widget.request.networkName}؟\n\nسيتم تسجيل المعاملة تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _processing = true);

      try {
        await FirebaseCashPaymentService.approvePaymentRequest(
          widget.request.id,
          vendorId,
        );

        if (!mounted) return;

        CustomToast.success(
          context,
          'تم تحديث رصيدك مع ${widget.request.networkName}',
          title: 'تمت الموافقة على الدفعة',
        );
      } on Exception catch (e) {
        if (!mounted) return;

        CustomToast.error(
          context,
          ErrorHandler.extractErrorMessage(e.toString()),
          title: 'فشلت العملية',
        );
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final authProvider = context.read<AuthProvider>();
    final vendorId = authProvider.user?.id ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24.w),
            SizedBox(width: 8.w),
            const Text('تأكيد الرفض'),
          ],
        ),
        content: Text(
          'هل تريد رفض دفعة ${widget.request.amount.toStringAsFixed(0)} ر.ي من ${widget.request.networkName}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _processing = true);

      try {
        await FirebaseCashPaymentService.rejectPaymentRequest(
          widget.request.id,
          vendorId,
        );

        if (!mounted) return;

        CustomToast.warning(
          context,
          'تم رفض الدفعة',
          title: 'تم الرفض',
        );
      } on Exception catch (e) {
        if (!mounted) return;

        CustomToast.error(
          context,
          ErrorHandler.extractErrorMessage(e.toString()),
          title: 'فشلت العملية',
        );
      } finally {
        if (mounted) setState(() => _processing = false);
      }
    }
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.gray500;
    }
  }

  static String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'تم الرفض';
      case 'pending':
        return 'بانتظار الموافقة';
      default:
        return status;
    }
  }

  static IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.request.status);
    final statusText = _getStatusText(widget.request.status);
    final statusIcon = _getStatusIcon(widget.request.status);
    final isPending = widget.request.status == 'pending';

    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.payments, color: AppColors.primary, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.networkName,
                      style: AppTypography.body.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      CurrencyFormatter.format(widget.request.amount),
                      style: AppTypography.body.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14.w, color: statusColor),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // الملاحظة
          if (widget.request.note.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16.w,
                    color: AppColors.gray600,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.request.note,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // التاريخ
          Row(
            children: [
              Icon(Icons.access_time, size: 14.w, color: AppColors.gray500),
              SizedBox(width: 6.w),
              Text(
                DateFormat('dd/MM/yyyy - HH:mm', 'ar').format(widget.request.createdAt),
                style: AppTypography.caption.copyWith(
                  fontSize: 11.sp,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),

          // الأزرار (فقط للطلبات المعلقة)
          if (isPending) ...[
            SizedBox(height: 16.h),
            if (_processing)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleReject,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: Icon(Icons.close, size: 18.w),
                      label: Text(
                        'رفض',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.check_circle, size: 18.w),
                      label: Text(
                        'موافقة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
