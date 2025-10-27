import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/packages/package_card.dart';

class SellablePackage {
  SellablePackage(this.data, {this.quantity = 0});
  final PackageCardData data;
  int quantity;
}

typedef QuantityChanged = void Function(SellablePackage pkg, int newQty);

class SellablePackageRow extends StatelessWidget {
  const SellablePackageRow({
    required this.pkg,
    required this.onQuantityChanged,
    super.key,
  });

  final SellablePackage pkg;
  final QuantityChanged onQuantityChanged;

  bool get _selected => pkg.quantity > 0;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => onQuantityChanged(pkg, _selected ? 0 : 1),
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      backgroundColor:
          _selected ? AppColors.primary.withValues(alpha: 0.04) : null,
      child: Row(
        children: [
          Expanded(child: _info()),
          _qtyStepper(context),
        ],
      ),
    );
  }

  Widget _info() {
    final d = pkg.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          d.name,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        SizedBox(height: 4.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 4.h,
          children: [
            _metaChip(_formatSize(d.sizeInMb)),
            if (d.validityDays > 0) _metaChip('${d.validityDays} يوم'),
            if (d.usageWindowHours > 0) _metaChip('${d.usageWindowHours} ساعة'),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          CurrencyFormatter.format(d.retailPrice),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _qtyStepper(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundIconButton(
          icon: Icons.add,
          enabled: pkg.quantity < pkg.data.quantityAvailable,
          onTap: () => onQuantityChanged(pkg, pkg.quantity + 1),
        ),
        SizedBox(width: 8.w),
        Text(
          pkg.quantity.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.gray800,
          ),
        ),
        SizedBox(width: 8.w),
        _roundIconButton(
          icon: Icons.remove,
          enabled: pkg.quantity > 0,
          onTap: () => onQuantityChanged(pkg, pkg.quantity - 1),
        ),
      ],
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.gray200,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          size: 18.w,
          color: enabled ? AppColors.primary : AppColors.gray400,
        ),
      ),
    );
  }

  Widget _metaChip(String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.gray700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  String _formatSize(int sizeInMb) {
    if (sizeInMb >= 1024) {
      final gb = sizeInMb / 1024;
      return '${gb.toStringAsFixed(gb.truncateToDouble() == gb ? 0 : 1)} جيجا';
    }
    return '$sizeInMb ميجا';
  }
}
