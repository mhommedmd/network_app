import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ui_tokens.dart';

/// Reusable segmented selector for choosing the user login/registration role.
class UserTypeSelector extends StatelessWidget {
  const UserTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
    this.padding,
  });

  final UserType value;
  final ValueChanged<UserType> onChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final items = <UserType, String>{
      UserType.networkOwner: 'مالك شبكة',
      UserType.posVendor: 'نقطة بيع',
    };
    return Container(
      padding: padding ?? EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(UITokens.radiusMd.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: items.entries.map((entry) {
          final selected = value == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(UITokens.radiusSm.r),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: AppTypography.body.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.gray600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
