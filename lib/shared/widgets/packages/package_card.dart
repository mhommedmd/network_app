import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ui_tokens.dart';
import '../../utils/currency_formatter.dart';
import '../app_card.dart';

/// Enum representing visual category of a package (for color/icon differentiation)
enum PackageType { basic, plus, premium, enterprise, seasonal, custom }

class PackageCardData {
  const PackageCardData({
    required this.name,
    required this.sizeInMb, // store everything in MB internally
    required this.validityDays,
    required this.usageWindowHours,
    required this.retailPrice, // سعر البيع للمستخدم النهائي
    required this.wholesalePrice, // سعر الشراء لنقطة البيع
    required this.quantityAvailable,
    this.type = PackageType.basic,
    this.icon,
    this.accentColor,
    this.isActive = true, // حالة الباقة (مفعلة/موقوفة)
  });
  final String name;
  final int sizeInMb;
  final int validityDays;
  final int usageWindowHours;
  final double retailPrice;
  final double wholesalePrice;
  final int quantityAvailable;
  final PackageType type;
  final IconData? icon;
  final Color?
      accentColor; // optional custom accent color (used for custom type)
  final bool isActive; // حالة الباقة

  String get formattedSize {
    if (sizeInMb >= 1024) {
      final gb = sizeInMb / 1024;
      if (gb % 1 == 0) return '${gb.toInt()} جيجا';
      return '${gb.toStringAsFixed(1)} جيجا';
    }
    return '$sizeInMb ميجا';
  }
}

class PackageCard extends StatelessWidget {
  const PackageCard({
    required this.data,
    super.key,
    this.onTap,
    this.onEdit,
    this.dense = false,
    this.showQuantity = true,
    this.showRetailPrice = true,
    this.showWholesalePrice = true,
    this.isSelected = false,
    this.selectionAccentColor,
  });
  final PackageCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onEdit; // now triggered by tapping the whole card
  final bool dense; // compact version
  final bool showQuantity; // hide qty if not relevant
  final bool showRetailPrice; // toggle retail price visibility
  final bool showWholesalePrice; // toggle wholesale price visibility
  final bool isSelected; // selection state
  final Color? selectionAccentColor; // override accent color when selected

  (Color bg, Color fg, Gradient? grad) _resolvePalette() {
    // Solid color palette, no gradients
    if (data.accentColor != null) {
      final c = data.accentColor!;
      return (c, c, null);
    }
    switch (data.type) {
      case PackageType.basic:
        return (AppColors.primary, AppColors.primary, null);
      case PackageType.plus:
        return (AppColors.secondary, AppColors.secondary, null);
      case PackageType.premium:
        return (AppColors.warning, AppColors.warning, null);
      case PackageType.enterprise:
        return (AppColors.info, AppColors.info, null);
      case PackageType.seasonal:
        return (AppColors.success, AppColors.success, null);
      case PackageType.custom:
        return (AppColors.gray600, AppColors.gray600, null);
    }
  }

  IconData _fallbackIcon() {
    switch (data.type) {
      case PackageType.basic:
        return Icons.layers_outlined;
      case PackageType.plus:
        return Icons.auto_awesome_outlined;
      case PackageType.premium:
        return Icons.workspace_premium_outlined;
      case PackageType.enterprise:
        return Icons.apartment_rounded;
      case PackageType.seasonal:
        return Icons.wb_sunny_outlined;
      case PackageType.custom:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, grad) = _resolvePalette();
    final iconData = data.icon ?? _fallbackIcon();

    final accent = selectionAccentColor ?? fg;
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          foregroundDecoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: accent,
                    width: 2,
                  ),
                )
              : null,
          child: AppCard(
            onTap: onEdit ?? onTap,
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                // علامة الإيقاف (تظهر فقط للباقات الموقوفة)
                if (!data.isActive)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause_circle,
                          color: AppColors.warning,
                          size: 16.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'الباقة متوقفة',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leading Icon
                    Container(
                      width: dense ? 42.r : 50.r,
                      height: dense ? 42.r : 50.r,
                      decoration: BoxDecoration(
                        color: data.isActive
                            ? bg
                            : AppColors.gray400, // رمادي للباقات الموقوفة
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(iconData, color: Colors.white, size: 26.r),
                    ),
                    SizedBox(width: 14.w),
                // Middle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: AppTypography.body.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 6.h,
                        children: [
                          _MetaChip(
                            label: data.formattedSize,
                            icon: Icons.data_usage_outlined,
                          ),
                          _MetaChip(
                            label: '${data.validityDays} يوم',
                            icon: Icons.calendar_month_outlined,
                          ),
                          _MetaChip(
                            label: data.usageWindowHours > 0
                                ? '${data.usageWindowHours} ساعة'
                                : 'مفتوح',
                            icon: Icons.access_time_outlined,
                          ),
                          if (showQuantity)
                            _MetaChip(
                              label: '${data.quantityAvailable} متوفر',
                              icon: Icons.inventory_2_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                    if (showRetailPrice || showWholesalePrice)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showRetailPrice)
                            _PriceTag(
                              label: 'سعر البيع',
                              value: CurrencyFormatter.format(data.retailPrice),
                              color: AppColors.success,
                            ),
                          if (showRetailPrice && showWholesalePrice)
                            SizedBox(height: 10.h),
                          if (showWholesalePrice)
                            _PriceTag(
                              label: 'سعر الشراء',
                              value: CurrencyFormatter.format(data.wholesalePrice),
                              color: AppColors.error,
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: 8.r,
            left: 8.r,
            child: Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 16.r, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTypography.micro.copyWith(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.85),
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTypography.body.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: AppColors.gray600),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }
}
