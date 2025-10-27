import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تنظيف الكروت القديمة
class FirebaseCardCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// حذف الكروت المباعة التي مر عليها أكثر من 30 يوم
  static Future<int> deleteSoldCardsOlderThan30Days() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      print('🗑️ Starting cleanup of sold cards older than ${thirtyDaysAgo}');

      // البحث عن الكروت المباعة القديمة في vendor_cards
      final vendorCardsSnapshot = await _firestore
          .collection('vendor_cards')
          .where('status', isEqualTo: 'sold')
          .where('soldAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      print(
          '📊 Found ${vendorCardsSnapshot.docs.length} sold vendor cards to delete');

      int deletedCount = 0;

      // حذف الكروت
      for (final doc in vendorCardsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      print('✅ Deleted $deletedCount sold vendor cards');

      // أيضاً حذف من مجموعة cards الرئيسية إذا كانت مباعة
      final cardsSnapshot = await _firestore
          .collection('cards')
          .where('status', isEqualTo: 'sold')
          .where('soldAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      print(
          '📊 Found ${cardsSnapshot.docs.length} sold network cards to delete');

      for (final doc in cardsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      print('✅ Total deleted: $deletedCount cards');

      return deletedCount;
    } catch (e) {
      print('❌ Error during cleanup: $e');
      return 0;
    }
  }

  /// حذف الكروت المباعة لشبكة معينة (أكثر من 30 يوم)
  static Future<int> deleteNetworkSoldCardsOlderThan30Days(
      String networkId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      print('🗑️ Cleaning sold cards for network: $networkId');

      // الكروت المباعة من البائعين (vendor_cards)
      final vendorCardsSnapshot = await _firestore
          .collection('vendor_cards')
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'sold')
          .where('soldAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      int deletedCount = 0;

      for (final doc in vendorCardsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      // الكروت في مخزون الشبكة
      final cardsSnapshot = await _firestore
          .collection('cards')
          .where('networkId', isEqualTo: networkId)
          .where('status', isEqualTo: 'sold')
          .where('soldAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      for (final doc in cardsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      print('✅ Deleted $deletedCount old sold cards for network $networkId');

      return deletedCount;
    } catch (e) {
      print('❌ Error: $e');
      return 0;
    }
  }

  /// جدولة عملية التنظيف التلقائي (يُستدعى عند فتح التطبيق)
  static Future<void> scheduleAutomaticCleanup() async {
    try {
      // التحقق من آخر تنظيف
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt('last_cleanup_timestamp');

      if (lastCleanup != null) {
        final lastCleanupDate =
            DateTime.fromMillisecondsSinceEpoch(lastCleanup);
        final daysSinceLastCleanup =
            DateTime.now().difference(lastCleanupDate).inDays;

        // إذا تم التنظيف خلال آخر 7 أيام، لا داعي للتنظيف مرة أخرى
        if (daysSinceLastCleanup < 7) {
          print('ℹ️ Last cleanup was $daysSinceLastCleanup days ago, skipping');
          return;
        }
      }

      print('🧹 Running automatic cleanup...');

      // تنفيذ التنظيف
      final deletedCount = await deleteSoldCardsOlderThan30Days();

      print('🎯 Cleanup complete: $deletedCount cards deleted');

      // حفظ وقت التنظيف
      await prefs.setInt(
          'last_cleanup_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }
}
