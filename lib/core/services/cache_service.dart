import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التخزين المؤقت للبيانات
class CacheService {
  static const String _userDataKey = 'cached_user_data';
  static const String _networksKey = 'cached_networks';
  static const String _packagesKey = 'cached_packages';
  static const String _inventoryKey = 'cached_inventory';
  static const String _timestampKey = 'cache_timestamp_';

  // مدة صلاحية الـ cache (30 دقيقة)
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// حفظ بيانات المستخدم
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    await _setTimestamp(_userDataKey);
  }

  /// جلب بيانات المستخدم
  static Future<Map<String, dynamic>?> getUserData() async {
    if (!await _isCacheValid(_userDataKey)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userDataKey);
    if (data == null) return null;

    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// حفظ قائمة الشبكات للمتجر
  static Future<void> saveNetworks(
      String vendorId, List<Map<String, dynamic>> networks) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_networksKey}_$vendorId';
    await prefs.setString(key, jsonEncode(networks));
    await _setTimestamp(key);
  }

  /// جلب قائمة الشبكات للمتجر
  static Future<List<Map<String, dynamic>>?> getNetworks(
      String vendorId) async {
    final key = '${_networksKey}_$vendorId';
    if (!await _isCacheValid(key)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// حفظ قائمة الباقات للشبكة
  static Future<void> savePackages(
      String networkId, List<Map<String, dynamic>> packages) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_packagesKey}_$networkId';
    await prefs.setString(key, jsonEncode(packages));
    await _setTimestamp(key);
  }

  /// جلب قائمة الباقات للشبكة
  static Future<List<Map<String, dynamic>>?> getPackages(
      String networkId) async {
    final key = '${_packagesKey}_$networkId';
    if (!await _isCacheValid(key)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// حفظ المخزون للمتجر
  static Future<void> saveInventory(
      String vendorId, Map<String, dynamic> inventory) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_inventoryKey}_$vendorId';
    await prefs.setString(key, jsonEncode(inventory));
    await _setTimestamp(key);
  }

  /// جلب المخزون للمتجر
  static Future<Map<String, dynamic>?> getInventory(String vendorId) async {
    final key = '${_inventoryKey}_$vendorId';
    if (!await _isCacheValid(key)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return null;

    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// حذف بيانات مستخدم معين
  static Future<void> clearUserCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove('${_networksKey}_$userId');
    await prefs.remove('${_packagesKey}_$userId');
    await prefs.remove('${_inventoryKey}_$userId');
    await prefs.remove('${_timestampKey}${_userDataKey}');
    await prefs.remove('${_timestampKey}${_networksKey}_$userId');
    await prefs.remove('${_timestampKey}${_packagesKey}_$userId');
    await prefs.remove('${_timestampKey}${_inventoryKey}_$userId');
  }

  /// حذف جميع البيانات المخزنة
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cached_') || key.startsWith('cache_timestamp_')) {
        await prefs.remove(key);
      }
    }
  }

  /// تعيين وقت التخزين
  static Future<void> _setTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_timestampKey$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// التحقق من صلاحية الـ cache
  static Future<bool> _isCacheValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_timestampKey$key');

    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheTime) < _cacheDuration;
  }

  /// إبطال الـ cache (جعله غير صالح)
  static Future<void> invalidateCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('$_timestampKey$key');
  }
}
