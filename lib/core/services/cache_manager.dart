import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// مدير الذاكرة المؤقتة للبيانات
class CacheManager {
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheDuration = Duration(minutes: 15);

  /// حفظ بيانات في الذاكرة المؤقتة
  static Future<void> saveData({
    required String key,
    required Map<String, dynamic> data,
    Duration? cacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresIn': (cacheDuration ?? _defaultCacheDuration).inMilliseconds,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      print('✅ Cache saved: $key');
    } on Exception catch (e) {
      print('❌ Error saving cache: $e');
    }
  }

  /// حفظ قائمة في الذاكرة المؤقتة
  static Future<void> saveList({
    required String key,
    required List<Map<String, dynamic>> dataList,
    Duration? cacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;

      final cacheData = {
        'dataList': dataList,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresIn': (cacheDuration ?? _defaultCacheDuration).inMilliseconds,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      print('✅ Cache list saved: $key (${dataList.length} items)');
    } on Exception catch (e) {
      print('❌ Error saving cache list: $e');
    }
  }

  /// قراءة بيانات من الذاكرة المؤقتة
  static Future<Map<String, dynamic>?> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cachedString = prefs.getString(cacheKey);

      if (cachedString == null) {
        print('ℹ️ No cache found for: $key');
        return null;
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiresIn = cacheData['expiresIn'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = cachedTime.add(Duration(milliseconds: expiresIn));

      // التحقق من انتهاء الصلاحية
      if (DateTime.now().isAfter(expiryTime)) {
        print('⏰ Cache expired for: $key');
        await clearCache(key);
        return null;
      }

      print(
          '✅ Cache hit: $key (${DateTime.now().difference(cachedTime).inMinutes} min old)',);
      return cacheData['data'] as Map<String, dynamic>;
    } on Exception catch (e) {
      print('❌ Error reading cache: $e');
      return null;
    }
  }

  /// قراءة قائمة من الذاكرة المؤقتة
  static Future<List<Map<String, dynamic>>?> getList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cachedString = prefs.getString(cacheKey);

      if (cachedString == null) {
        print('ℹ️ No cache list found for: $key');
        return null;
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final expiresIn = cacheData['expiresIn'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = cachedTime.add(Duration(milliseconds: expiresIn));

      // التحقق من انتهاء الصلاحية
      if (DateTime.now().isAfter(expiryTime)) {
        print('⏰ Cache list expired for: $key');
        await clearCache(key);
        return null;
      }

      final dataList = (cacheData['dataList'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      print(
          '✅ Cache list hit: $key (${dataList.length} items, ${DateTime.now().difference(cachedTime).inMinutes} min old)',);
      return dataList;
    } on Exception catch (e) {
      print('❌ Error reading cache list: $e');
      return null;
    }
  }

  /// حذف بيانات من الذاكرة المؤقتة
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      await prefs.remove(cacheKey);
      print('🗑️ Cache cleared: $key');
    } on Exception catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// حذف جميع البيانات المؤقتة
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix));

      for (final key in cacheKeys) {
        await prefs.remove(key);
      }

      print('🗑️ All cache cleared (${cacheKeys.length} items)');
    } on Exception catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// التحقق من وجود بيانات صالحة في الذاكرة المؤقتة
  static Future<bool> hasValidCache(String key) async {
    final data = await getData(key);
    return data != null;
  }

  /// الحصول على عمر الذاكرة المؤقتة بالدقائق
  static Future<int?> getCacheAge(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cachedString = prefs.getString(cacheKey);

      if (cachedString == null) return null;

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      return DateTime.now().difference(cachedTime).inMinutes;
    } on Exception {
      return null;
    }
  }
}

/// مفاتيح الذاكرة المؤقتة
class CacheKeys {
  // Network Owner
  static String packages(String networkId) => 'packages_$networkId';
  static String vendors(String networkId) => 'vendors_$networkId';
  static String cards(String networkId) => 'cards_$networkId';
  static String cardStats(String networkId) => 'card_stats_$networkId';
  static String networkOrders(String networkId) => 'network_orders_$networkId';
  static String accountSummary(String vendorId, String networkId) =>
      'account_summary_${vendorId}_$networkId';
  static String transactions(String vendorId, String networkId) =>
      'transactions_${vendorId}_$networkId';

  // POS Vendor
  static String connectedNetworks(String vendorId) => 'networks_$vendorId';
  static String vendorOrders(String vendorId) => 'vendor_orders_$vendorId';
  static String vendorInventory(String vendorId) =>
      'vendor_inventory_$vendorId';
  static String recentSales(String vendorId) => 'recent_sales_$vendorId';
  static String networkPackages(String networkId) =>
      'network_packages_$networkId';
}
