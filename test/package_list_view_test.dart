import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_cards_manager/shared/widgets/packages/package_card.dart';
import 'package:mikrotik_cards_manager/shared/widgets/packages/package_list_view.dart';

void main() {
  group('PackageListView', () {
    testWidgets('shows skeleton when loading', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body:
                  PackageListView(items: <PackageCardData>[], isLoading: true),
            ),
          ),
        ),
      );
      // Expect some skeleton containers
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('shows empty state when no items and not loading',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: Scaffold(
              body: PackageListView(items: <PackageCardData>[]),
            ),
          ),
        ),
      );
      expect(find.text('لا توجد باقات متاحة'), findsOneWidget);
    });

    testWidgets('renders items and supports selection toggle', (tester) async {
      final items = <PackageCardData>[
        const PackageCardData(
          name: 'باقة 1',
          sizeInMb: 500,
          validityDays: 7,
          usageWindowHours: 24,
          retailPrice: 100,
          wholesalePrice: 80,
          quantityAvailable: 10,
        ),
        const PackageCardData(
          name: 'باقة 2',
          sizeInMb: 1024,
          validityDays: 30,
          usageWindowHours: 24,
          retailPrice: 200,
          wholesalePrice: 150,
          quantityAvailable: 5,
        ),
      ];
      final selected = <String>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, __) => MaterialApp(
                home: Scaffold(
                  body: PackageListView(
                    items: items,
                    selectionEnabled: true,
                    selectedNames: selected,
                    onToggleSelect: (PackageCardData d) {
                      setState(() {
                        if (selected.contains(d.name)) {
                          selected.remove(d.name);
                        } else {
                          selected.add(d.name);
                        }
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('باقة 1'), findsOneWidget);
      expect(find.text('باقة 2'), findsOneWidget);

      await tester.tap(find.text('باقة 1'));
      await tester.pumpAndSettle();
      // After selection a check icon should appear
      expect(find.byIcon(Icons.check), findsWidgets);

      await tester.tap(find.text('باقة 1'));
      await tester.pumpAndSettle();
    });
  });
}
