import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/ui_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/toast/toast.dart';

typedef CashPaymentDecisionCallback = void Function(
  String requestId, {
  required bool accepted,
});

class PosVendorCashPaymentsPage extends StatefulWidget {
  const PosVendorCashPaymentsPage({
    required this.onBack,
    this.onDecision,
    super.key,
  });

  final VoidCallback onBack;
  final CashPaymentDecisionCallback? onDecision;

  @override
  State<PosVendorCashPaymentsPage> createState() =>
      _PosVendorCashPaymentsPageState();
}

class _PosVendorCashPaymentsPageState extends State<PosVendorCashPaymentsPage> {
  final List<_PaymentRequest> _requests = [
    const _PaymentRequest(
      id: 'REQ-001',
      merchantName: 'نقطة بيع النخبة',
      networkName: 'شبكة العاصمة',
      amount: 15000,
      note: 'دفعة نقدية مقابل مبيعات الأسبوع الماضي',
      createdAt: 'منذ 10 دقائق',
    ),
    const _PaymentRequest(
      id: 'REQ-002',
      merchantName: 'متجر الأفق',
      networkName: 'شبكة الجنوب',
      amount: 8200,
      note: 'دفعة نقدية لعمليات اليوم',
      createdAt: 'قبل ساعتين',
    ),
  ];

  final Map<String, _RequestStatus> _statuses = {};

  void _updateStatus(String id, _RequestStatus status) {
    setState(() {
      _statuses[id] = status;
    });

    widget.onDecision?.call(
      id,
      accepted: status == _RequestStatus.approved,
    );

    if (status == _RequestStatus.approved) {
      CustomToast.success(
        context,
        'تم تحديث الرصيد',
        title: 'تمت الموافقة على الدفعة',
      );
    } else {
      CustomToast.warning(
        context,
        'تم رفض الدفعة',
        title: 'تم الرفض',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الدفعات النقدية',
          style: AppTypography.subheadline.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: _requests.isEmpty
                ? _emptyState()
                : ListView.separated(
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (_, index) {
                      final request = _requests[index];
                      final status =
                          _statuses[request.id] ?? _RequestStatus.pending;
                      return _PaymentRequestCard(
                        request: request,
                        status: status,
                        onApprove: status == _RequestStatus.pending
                            ? () => _updateStatus(
                                  request.id,
                                  _RequestStatus.approved,
                                )
                            : null,
                        onReject: status == _RequestStatus.pending
                            ? () => _updateStatus(
                                  request.id,
                                  _RequestStatus.rejected,
                                )
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, size: 40.w, color: AppColors.gray400),
            SizedBox(height: 16.h),
            Text(
              'لا توجد دفعات معلقة',
              style: AppTypography.body.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'سيظهر هنا أي دفعة نقدية تحتاج إلى موافقتك',
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

class _PaymentRequestCard extends StatelessWidget {
  const _PaymentRequestCard({
    required this.request,
    required this.status,
    this.onApprove,
    this.onReject,
  });

  final _PaymentRequest request;
  final _RequestStatus status;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  Color _statusColor() {
    switch (status) {
      case _RequestStatus.approved:
        return AppColors.success;
      case _RequestStatus.rejected:
        return AppColors.error;
      case _RequestStatus.pending:
        return AppColors.warningDark;
    }
  }

  String _statusLabel() {
    switch (status) {
      case _RequestStatus.approved:
        return 'تمت الموافقة';
      case _RequestStatus.rejected:
        return 'تم الرفض';
      case _RequestStatus.pending:
        return 'بانتظار الموافقة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child:
                    Icon(Icons.payments, color: AppColors.primary, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.networkName,
                      style: AppTypography.body.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${request.amount.toStringAsFixed(0)} ر.ي',
                      style: AppTypography.body.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _statusLabel(),
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.sp,
                    color: _statusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 16.w,
                color: AppColors.gray500,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'المتجر المستلم: ${request.merchantName}',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.gray600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            request.note,
            style: AppTypography.caption.copyWith(
              fontSize: 12.sp,
              color: AppColors.gray700,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 14.w, color: AppColors.gray400),
              SizedBox(width: 6.w),
              Text(
                request.createdAt,
                style: AppTypography.caption.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (status == _RequestStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(
                      'رفض',
                      style: AppTypography.body.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'موافقة',
                      style: AppTypography.body.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _PaymentRequest {
  const _PaymentRequest({
    required this.id,
    required this.merchantName,
    required this.networkName,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String merchantName;
  final String networkName;
  final double amount;
  final String note;
  final String createdAt;
}

enum _RequestStatus { pending, approved, rejected }
