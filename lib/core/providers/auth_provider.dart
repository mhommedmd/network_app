import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cache_service.dart';
import '../utils/phone_utils.dart';
// ===========================
// Enums & Constants
// ===========================

enum UserType { networkOwner, posVendor }

class _Constants {
  static const String usersCollection = 'users';
  static const String userKey = 'user';
  static const String emailDomain = '@networkapp.app';
  static const int minPasswordLength = 6;
}

// ===========================
// User Model
// ===========================

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    required this.createdAt,
    this.avatar,
    this.ownerName,
    this.networkName,
    this.secondPhone,
    this.governorate,
    this.district,
    this.city,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      type: _UserTypeParser.parse(json['type']),
      avatar: json['avatar'] as String?,
      ownerName: json['ownerName'] as String?,
      networkName: json['networkName'] as String?,
      secondPhone: json['secondPhone'] as String?,
      governorate: json['governorate'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType type;
  final String? avatar;
  final String? ownerName;
  final String? networkName;
  final String? secondPhone;
  final String? governorate;
  final String? district;
  final String? city;
  final String? address;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'type': type.name,
        'avatar': avatar,
        'ownerName': ownerName,
        'networkName': networkName,
        'secondPhone': secondPhone,
        'governorate': governorate,
        'district': district,
        'city': city,
        'address': address,
        'createdAt': createdAt.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserType? type,
    String? avatar,
    String? ownerName,
    String? networkName,
    String? secondPhone,
    String? governorate,
    String? district,
    String? city,
    String? address,
    DateTime? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        type: type ?? this.type,
        avatar: avatar ?? this.avatar,
        ownerName: ownerName ?? this.ownerName,
        networkName: networkName ?? this.networkName,
        secondPhone: secondPhone ?? this.secondPhone,
        governorate: governorate ?? this.governorate,
        district: district ?? this.district,
        city: city ?? this.city,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ===========================
// Helper Classes
// ===========================

class _UserTypeParser {
  static UserType parse(dynamic raw) {
    if (raw is UserType) return raw;

    if (raw is int && raw >= 0 && raw < UserType.values.length) {
      return UserType.values[raw];
    }

    final normalized = raw?.toString().trim().toLowerCase().replaceAll(RegExp('[^a-z]'), '') ?? '';

    return switch (normalized) {
      'networkowner' || 'network' || 'owner' => UserType.networkOwner,
      'posvendor' || 'vendor' || 'pos' || 'seller' => UserType.posVendor,
      _ => UserType.values.firstWhere(
          (t) => t.name.toLowerCase() == normalized,
          orElse: () => UserType.posVendor,
        ),
    };
  }
}

DateTime _parseDateTime(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
  if (raw is Timestamp) return raw.toDate();
  if (raw is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

// ===========================
// Auth Provider
// ===========================

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _loadUserFromStorage();
  }

  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // State
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  set isLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  // ===========================
  // Public Methods
  // ===========================

  Future<bool> login({
    required String phone,
    required String password,
    UserType? userType,
  }) async {
    return _handleAuthOperation(() async {
      _validatePhone(phone);
      _validatePassword(password);

      final email = _emailFromPhone(phone);
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('تعذر تسجيل الدخول');

      _user = await _fetchOrCreateUser(firebaseUser, phone, userType);
      await _saveUserToStorage(_user!);

      return true;
    });
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String confirmPassword,
    required UserType userType,
  }) async {
    return _handleAuthOperation(() async {
      _validateName(name);
      _validatePhone(phone);
      _validatePassword(password);
      _validatePasswordMatch(password, confirmPassword);

      final email = _emailFromPhone(phone);

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('تعذر إنشاء الحساب');

      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await firebaseUser.updateDisplayName(trimmedName);
      }

      _user = User(
        id: firebaseUser.uid,
        name: trimmedName,
        email: firebaseUser.email ?? email,
        phone: phone,
        type: userType,
        avatar: firebaseUser.photoURL ?? _getAvatarInitial(trimmedName),
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );

      await _saveUserToFirestore(_user!);
      await _saveUserToStorage(_user!);
      return true;
    });
  }

  Future<bool> startPasswordRecovery(String phone) async {
    return _handleAuthOperation(() async {
      throw Exception('استعادة كلمة المرور غير متاحة حالياً. يرجى التواصل مع الدعم الفني.');
    });
  }

  bool verifyPasswordResetOtp(String phone, String otp) {
    _error = 'ميزة التحقق من رمز الاستعادة غير متاحة حالياً.';
    notifyListeners();
    return false;
  }

  Future<bool> completePasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    return _handleAuthOperation(() async {
      throw Exception('استعادة كلمة المرور عبر التطبيق غير متاحة حالياً.');
    });
  }

  Future<void> logout() async {
    try {
      isLoading = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_Constants.userKey);

      if (_user != null) {
        await CacheService.clearUserCache(_user!.id);
      }
      await CacheService.clearAllCache();

      await _firebaseAuth.signOut();

      _user = null;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      isLoading = false;
      _error = 'فشل في تسجيل الخروج';
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    String? ownerName,
    String? networkName,
    String? email,
    String? secondPhone,
    String? governorate,
    String? district,
    String? city,
    String? address,
    File? profileImage,
  }) async {
    if (_user == null) {
      _error = 'لا يوجد مستخدم مسجل الدخول';
      notifyListeners();
      return false;
    }

    return _handleAuthOperation(() async {
      var avatarUrl = _user!.avatar;

      if (profileImage != null) {
        avatarUrl = await _uploadProfileImage(profileImage);
      }

      final updatedUser = User(
        id: _user!.id,
        name: name ?? _user!.name,
        email: email ?? _user!.email,
        phone: _user!.phone,
        type: _user!.type,
        avatar: avatarUrl,
        ownerName: ownerName ?? _user!.ownerName,
        networkName: networkName ?? _user!.networkName,
        secondPhone: secondPhone ?? _user!.secondPhone,
        governorate: governorate ?? _user!.governorate,
        district: district ?? _user!.district,
        city: city ?? _user!.city,
        address: address ?? _user!.address,
        createdAt: _user!.createdAt,
      );

      await _saveUserToFirestore(updatedUser);

      _user = updatedUser;
      await _saveUserToStorage(updatedUser);

      return true;
    });
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) {
      _error = 'لا يوجد مستخدم مسجل الدخول';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      _clearError();

      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser?.email == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم');
      }

      final credential = fb_auth.EmailAuthProvider.credential(
        email: firebaseUser!.email!,
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);

      isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      isLoading = false;
      _error = switch (e.code) {
        'wrong-password' => 'كلمة المرور الحالية غير صحيحة',
        'weak-password' => 'كلمة المرور الجديدة ضعيفة',
        _ => e.message ?? 'فشل تغيير كلمة المرور',
      };
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      _error = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ===========================
  // Private Methods - Storage
  // ===========================

  Future<void> _loadUserFromStorage() async {
    try {
      final cachedData = await CacheService.getUserData();
      if (cachedData != null) {
        _user = User.fromJson(cachedData);
        notifyListeners();
        debugPrint('✅ User loaded from cache');
        unawaited(_syncUserWithFirestore(_user!.id));
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_Constants.userKey);

      if (userJson != null) {
        final decoded = json.decode(userJson) as Map<String, dynamic>;
        _user = User.fromJson(decoded);
        notifyListeners();
        await _syncUserWithFirestore(_user!.id);
        return;
      }

      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        final remote = await _fetchUserFromFirestoreById(currentFirebaseUser.uid);
        if (remote != null) {
          _user = remote;
          await _saveUserToStorage(remote);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
      _error = 'فشل في تحميل بيانات المستخدم';
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_Constants.userKey, json.encode(user.toJson()));
      await CacheService.saveUserData(user.toJson());
      debugPrint('✅ User data saved');
    } catch (e) {
      debugPrint('❌ Failed to save user: $e');
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      await _firestore.collection(_Constants.usersCollection).doc(user.id).set(user.toJson(), SetOptions(merge: true));
      debugPrint('✅ User saved to Firestore');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firestore save failed: ${e.message}');
      throw Exception('فشل حفظ البيانات: ${e.message}');
    }
  }

  // ===========================
  // Private Methods - Firestore
  // ===========================

  Future<User?> _fetchUserFromFirestoreById(String id) async {
    try {
      final doc = await _firestore.collection(_Constants.usersCollection).doc(id).get();
      if (!doc.exists || doc.data() == null) return null;

      return User.fromJson({...doc.data()!, 'id': doc.id});
    } on FirebaseException catch (e) {
      debugPrint('❌ Fetch user failed: ${e.message}');
      return null;
    }
  }

  Future<void> _syncUserWithFirestore(String id) async {
    final remoteUser = await _fetchUserFromFirestoreById(id);
    if (remoteUser == null) return;

    _user = remoteUser;
    await _saveUserToStorage(remoteUser);
    notifyListeners();
  }

  Future<User> _fetchOrCreateUser(
    fb_auth.User firebaseUser,
    String phone,
    UserType? userType,
  ) async {
    var user = await _fetchUserFromFirestoreById(firebaseUser.uid);

    if (user == null) {
      user = User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? _getNameByPhone(phone),
        email: firebaseUser.email ?? _emailFromPhone(phone),
        phone: phone,
        type: userType ?? _getUserTypeByPhone(phone),
        avatar: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
      await _saveUserToFirestore(user);
    }

    return user;
  }

  // ===========================
  // Private Methods - Password Reset
  // ===========================

  // ===========================
  // Private Methods - File Upload
  // ===========================

  Future<String> _uploadProfileImage(File profileImage) async {
    try {
      debugPrint('🔄 Uploading image...');

      final fileName = 'profile_${_user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('profile_images/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': _user!.id,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putFile(profileImage, metadata);

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('📊 Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Upload failed: ${e.message}');
      throw Exception('فشل رفع الصورة: ${e.message}');
    }
  }

  // ===========================
  // Private Methods - Validation
  // ===========================

  void _validateName(String name) {
    if (name.trim().isEmpty) throw Exception('الاسم مطلوب');
  }

  void _validatePhone(String phone) {
    if (!_isValidYemeniPhone(phone)) throw Exception('رقم الهاتف غير صحيح');
  }

  void _validatePassword(String password) {
    if (password.length < _Constants.minPasswordLength) {
      throw Exception('كلمة المرور يجب أن تكون ${_Constants.minPasswordLength} أحرف على الأقل');
    }
  }

  void _validatePasswordMatch(String password, String confirmPassword) {
    if (password != confirmPassword) throw Exception('كلمة المرور غير متطابقة');
  }

  bool _isValidYemeniPhone(String phone) {
    return PhoneUtils.isValidYemeniPhone(phone);
  }

  // ===========================
  // Private Methods - Utilities
  // ===========================

  Future<bool> _handleAuthOperation(Future<bool> Function() operation) async {
    try {
      isLoading = true;
      _clearError();
      return await operation();
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message ?? 'تعذر إكمال العملية';
      return false;
    } catch (e) {
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _clearError() {
    _error = null;
  }

  String _emailFromPhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp('[^0-9]'), '');
    return '$digitsOnly${_Constants.emailDomain}';
  }

  String? _getAvatarInitial(String name) {
    return name.isEmpty ? null : name.substring(0, 1).toUpperCase();
  }

  String _getNameByPhone(String phone) {
    if (phone.startsWith('777')) return 'أحمد محمد';
    if (phone.startsWith('733')) return 'فاطمة علي';
    return 'مستخدم جديد';
  }

  UserType _getUserTypeByPhone(String phone) {
    if (phone.startsWith('777') || phone.startsWith('733')) {
      return UserType.networkOwner;
    }
    return UserType.posVendor;
  }
}
