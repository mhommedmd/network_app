import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

enum AppTab { home, network, networks, accounts, chat, profile }

class TabItem {
  const TabItem({
    required this.id,
    required this.label,
    required this.icon,
  });
  final AppTab id;
  final String label;
  final IconData icon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.activeTab,
    required this.onTabChange,
    super.key,
  });
  final AppTab activeTab;
  final ValueChanged<AppTab> onTabChange;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    List<TabItem> tabs;
    if (authProvider.user?.type == UserType.networkOwner) {
      tabs = const [
        TabItem(id: AppTab.home, label: 'الرئيسية', icon: Icons.home),
        TabItem(id: AppTab.network, label: 'الشبكة', icon: Icons.wifi),
        TabItem(id: AppTab.accounts, label: 'المتاجر', icon: Icons.people),
        TabItem(id: AppTab.chat, label: 'المحادثات', icon: Icons.chat),
        TabItem(id: AppTab.profile, label: 'الملف الشخصي', icon: Icons.person),
      ];
    } else {
      tabs = const [
        TabItem(id: AppTab.home, label: 'الرئيسية', icon: Icons.home),
        TabItem(
          id: AppTab.networks,
          label: 'الشبكات',
          icon: Icons.network_cell,
        ),
        TabItem(id: AppTab.chat, label: 'المحادثات', icon: Icons.chat),
        TabItem(id: AppTab.profile, label: 'الملف الشخصي', icon: Icons.person),
      ];
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(
            color: AppColors.gray200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          // Removed fixed height (was 64.h) to avoid overflow when text scale or
          // screen dimension causes content > fixed height. Now intrinsic.
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isActive = activeTab == tab.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabChange(tab.id),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          // Slightly smaller to reduce vertical footprint
                          width: 32.w,
                          height: 32.w,
                          child: Transform.scale(
                            scale: isActive ? 1.05 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Icon(
                                tab.icon,
                                size: 18.w,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.gray500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.gray500,
                          ),
                          child: Text(
                            tab.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
