import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cache_service.dart';

enum UserType { networkOwner, posVendor }

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    required this.createdAt,
    this.avatar,
    this.networkName,
    this.secondPhone,
    this.governorate,
    this.district,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    final parsedType = _parseUserType(rawType);

    final createdRaw = json['createdAt'];
    DateTime created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else if (createdRaw is Timestamp) {
      created = createdRaw.toDate();
    } else if (createdRaw is int) {
      // Support legacy millis timestamps
      try {
        created = DateTime.fromMillisecondsSinceEpoch(createdRaw);
      } on Exception {
        created = DateTime.now();
      }
    } else {
      created = DateTime.now();
    }

    return User(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      type: parsedType,
      avatar: json['avatar'] as String?,
      networkName: json['networkName'] as String?,
      secondPhone: json['secondPhone'] as String?,
      governorate: json['governorate'] as String?,
      district: json['district'] as String?,
      address: json['address'] as String?,
      createdAt: created,
    );
  }
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserType type;
  final String? avatar;
  final String? networkName;
  final String? secondPhone;
  final String? governorate;
  final String? district;
  final String? address;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'type': type.name,
      'avatar': avatar,
      'networkName': networkName,
      'secondPhone': secondPhone,
      'governorate': governorate,
      'district': district,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserType? type,
    String? avatar,
    String? networkName,
    String? secondPhone,
    String? governorate,
    String? district,
    String? address,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      avatar: avatar ?? this.avatar,
      networkName: networkName ?? this.networkName,
      secondPhone: secondPhone ?? this.secondPhone,
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Safely parse user type saved in storage (supports multiple formats)
UserType _parseUserType(dynamic raw) {
  if (raw is UserType) return raw;

  // Handle numeric enum index
  if (raw is int) {
    final i = raw;
    if (i >= 0 && i < UserType.values.length) return UserType.values[i];
  }

  final s = raw?.toString().trim().toLowerCase() ?? '';
  if (s.isEmpty) return UserType.posVendor;

  // Normalize separators: "network_owner" -> "networkowner"
  final normalized = s.replaceAll(RegExp('[^a-z]'), '');

  switch (normalized) {
    case 'networkowner':
    case 'network':
    case 'owner':
      return UserType.networkOwner;
    case 'posvendor':
    case 'vendor':
    case 'pos':
    case 'seller':
      return UserType.posVendor;
    default:
      // Final attempt: exact match on enum names ignoring case
      for (final t in UserType.values) {
        if (t.name.toLowerCase() == s) return t;
      }
      return UserType.posVendor;
  }
}

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _loadUserFromStorage();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _pendingResetPhone;
  String? _pendingResetOtp;
  DateTime? _pendingResetExpiry;
  bool _pendingResetOtpVerified = false;
  String? _pendingRegistrationPhone;
  String? _registrationVerificationId;
  int? _registrationResendToken;
  bool _registrationOtpVerified = false;
  fb_auth.PhoneAuthCredential? _registrationPhoneCredential;
  bool _isSendingRegistrationOtp = false;
  bool _isVerifyingRegistrationOtp = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isSendingRegistrationOtp => _isSendingRegistrationOtp;
  bool get isVerifyingRegistrationOtp => _isVerifyingRegistrationOtp;
  bool get isRegistrationOtpVerified => _registrationOtpVerified;

  // Update loading state only when it actually changes to prevent unnecessary rebuilds.
  set isLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      // محاولة جلب من الـ cache أولاً
      final cachedData = await CacheService.getUserData();

      if (cachedData != null) {
        final cachedUser = User.fromJson(cachedData);
        _user = cachedUser;
        notifyListeners();
        print('✅ User loaded from cache: ${cachedUser.name}');

        // تحديث من Firebase في الخلفية
        _syncUserWithFirestore(cachedUser.id);
        return;
      }

      // إذا لم يوجد cache، استخدم الطريقة القديمة
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final decoded = json.decode(userJson);
        if (decoded is Map<String, dynamic>) {
          final cachedUser = User.fromJson(decoded);
          _user = cachedUser;
          notifyListeners();
          await _syncUserWithFirestore(cachedUser.id);
        }
      }
    } on Exception catch (e) {
      print('❌ Error loading user from storage: $e');
      _error = 'فشل في تحميل بيانات المستخدم';
      notifyListeners();
    }

    if (_user == null) {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        final remote =
            await _fetchUserFromFirestoreById(currentFirebaseUser.uid);
        if (remote != null) {
          _user = remote;
          await _saveUserToStorage(remote);
          notifyListeners();
        }
      }
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      // حفظ في الطريقة القديمة (للتوافق)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(user.toJson()));

      // حفظ في CacheService (جديد)
      await CacheService.saveUserData(user.toJson());
      print('✅ User data saved to cache: ${user.name}');
    } on Exception catch (e) {
      debugPrint('فشل في حفظ بيانات المستخدم: $e');
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      debugPrint('💾 محاولة حفظ المستخدم في Firestore: ${user.id}');
      debugPrint('📄 البيانات: ${user.toJson()}');

      await _firestore.collection('users').doc(user.id).set(
            user.toJson(),
            SetOptions(merge: true),
          );

      debugPrint('✅ تم حفظ المستخدم في Firestore بنجاح');
    } on FirebaseException catch (e) {
      debugPrint('❌ فشل في حفظ المستخدم في Firestore: ${e.message}');
      debugPrint('   الكود: ${e.code}');
      throw Exception('فشل حفظ البيانات في قاعدة البيانات: ${e.message}');
    }
  }

  Future<User?> _fetchUserFromFirestoreById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      final data = <String, dynamic>{...doc.data()!, 'id': doc.id};
      return User.fromJson(data);
    } on FirebaseException catch (e) {
      debugPrint('فشل في جلب المستخدم حسب المعرّف: ${e.message}');
      return null;
    }
  }

  Future<User?> _fetchUserByPhone(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      final data = <String, dynamic>{...doc.data(), 'id': doc.id};
      return User.fromJson(data);
    } on FirebaseException catch (e) {
      debugPrint('فشل في جلب المستخدم حسب رقم الهاتف: ${e.message}');
      return null;
    }
  }

  Future<void> _syncUserWithFirestore(String id) async {
    final remoteUser = await _fetchUserFromFirestoreById(id);
    if (remoteUser == null) {
      return;
    }
    _user = remoteUser;
    await _saveUserToStorage(remoteUser);
    notifyListeners();
  }

  Future<bool> login({
    required String phone,
    required String password,
    UserType? userType,
  }) async {
    try {
      isLoading = true;
      _clearError();
      if (!_isValidYemeniPhone(phone)) {
        throw Exception('رقم الهاتف غير صحيح');
      }

      if (password.length < 6) {
        throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      }

      final email = _emailFromPhone(phone);
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('تعذر تسجيل الدخول، يرجى المحاولة مجددًا');
      }

      _user = await _fetchUserFromFirestoreById(firebaseUser.uid);
      if (_user == null) {
        final creationTime =
            firebaseUser.metadata.creationTime ?? DateTime.now();
        _user = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? _getNameByPhone(phone),
          email: firebaseUser.email ?? email,
          phone: phone,
          type: userType ?? _getUserTypeByPhone(phone),
          avatar: firebaseUser.photoURL,
          createdAt: creationTime,
        );
        await _saveUserToFirestore(_user!);
      }

      await _saveUserToStorage(_user!);

      // تطبيق كلمة المرور الجديدة إذا كانت موجودة من عملية استعادة سابقة
      await _applyPendingPasswordReset(firebaseUser.uid);

      isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      isLoading = false;
      _error = e.message ?? 'تعذر تسجيل الدخول، يرجى المحاولة لاحقًا';
      notifyListeners();
      return false;
    } on Exception catch (e) {
      isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String confirmPassword,
    required UserType userType,
  }) async {
    try {
      isLoading = true;
      _clearError();

      // التحقق من صحة المدخلات
      if (name.trim().isEmpty) {
        throw Exception('الاسم مطلوب');
      }

      if (!_isValidYemeniPhone(phone)) {
        throw Exception('رقم الهاتف غير صحيح');
      }

      if (password.length < 6) {
        throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      }

      if (password != confirmPassword) {
        throw Exception('كلمة المرور غير متطابقة');
      }

      _pendingRegistrationPhone = phone;

      final email = _emailFromPhone(phone);
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('تعذر إنشاء الحساب، يرجى المحاولة لاحقًا');
      }

      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await firebaseUser.updateDisplayName(trimmedName);
      }

      final creationTime = firebaseUser.metadata.creationTime ?? DateTime.now();
      final fallbackAvatar = trimmedName.isEmpty
          ? null
          : trimmedName.substring(0, 1).toUpperCase();

      _user = User(
        id: firebaseUser.uid,
        name: trimmedName,
        email: firebaseUser.email ?? email,
        phone: phone,
        type: userType,
        avatar: firebaseUser.photoURL ?? fallbackAvatar,
        createdAt: creationTime,
      );

      await _saveUserToFirestore(_user!);
      await _saveUserToStorage(_user!);

      resetRegistrationOtpState();

      isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      isLoading = false;
      _error = e.message ?? 'تعذر إنشاء الحساب، يرجى المحاولة لاحقًا';
      notifyListeners();
      return false;
    } on Exception catch (e) {
      isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendRegistrationOtp(
    String phone, {
    bool forceResend = false,
  }) async {
    if (_isSendingRegistrationOtp) {
      return false;
    }

    if (kDebugMode) {
      return bypassRegistrationOtpForTesting(phone);
    }

    try {
      if (!_isValidYemeniPhone(phone)) {
        throw Exception('رقم الهاتف غير صحيح');
      }

      if (!forceResend &&
          _pendingRegistrationPhone != null &&
          _pendingRegistrationPhone != phone) {
        resetRegistrationOtpState();
      }

      _clearError();
      _isSendingRegistrationOtp = true;
      notifyListeners();

      final completer = Completer<bool>();
      final formattedPhone = _formatPhoneToE164(phone);

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResend ? _registrationResendToken : null,
        verificationCompleted: (credential) {
          _registrationPhoneCredential = credential;
          _registrationOtpVerified = true;
          _pendingRegistrationPhone = phone;
          _error = null;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
          notifyListeners();
        },
        verificationFailed: (fb_auth.FirebaseAuthException error) {
          _registrationVerificationId = null;
          _registrationResendToken = null;
          _registrationPhoneCredential = null;
          _registrationOtpVerified = false;
          _error = _mapFirebaseOtpError(error);
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          notifyListeners();
        },
        codeSent: (verificationId, resendToken) {
          _registrationVerificationId = verificationId;
          _registrationResendToken = resendToken;
          _registrationPhoneCredential = null;
          _registrationOtpVerified = false;
          _pendingRegistrationPhone = phone;
          _error = null;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _registrationVerificationId = verificationId;
        },
      );

      final result = await completer.future;
      return result;
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _mapFirebaseOtpError(e);
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      if (_isSendingRegistrationOtp) {
        _isSendingRegistrationOtp = false;
        notifyListeners();
      }
    }
  }

  Future<bool> bypassRegistrationOtpForTesting(String phone) async {
    if (!kDebugMode) {
      return false;
    }

    _pendingRegistrationPhone = phone;
    _registrationVerificationId = null;
    _registrationResendToken = null;
    _registrationPhoneCredential = null;
    _registrationOtpVerified = true;
    _error = null;
    _isSendingRegistrationOtp = false;
    _isVerifyingRegistrationOtp = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyRegistrationOtp(String phone, String smsCode) async {
    if (_registrationOtpVerified &&
        _pendingRegistrationPhone == phone &&
        _registrationPhoneCredential != null) {
      return true;
    }

    if (_registrationVerificationId == null) {
      _error = 'الرجاء طلب كود التحقق أولاً';
      notifyListeners();
      return false;
    }

    if (_pendingRegistrationPhone != phone) {
      _error = 'رقم الهاتف لا يطابق الطلب الحالي';
      notifyListeners();
      return false;
    }

    try {
      _clearError();
      _isVerifyingRegistrationOtp = true;
      notifyListeners();

      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _registrationVerificationId!,
        smsCode: smsCode.trim(),
      );

      _registrationPhoneCredential = credential;
      _registrationOtpVerified = true;
      _error = null;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _registrationOtpVerified = false;
      _error = _mapFirebaseOtpError(e);
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _registrationOtpVerified = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      if (_isVerifyingRegistrationOtp) {
        _isVerifyingRegistrationOtp = false;
        notifyListeners();
      }
    }
  }

  void resetRegistrationOtpState() {
    final hadState = _pendingRegistrationPhone != null ||
        _registrationVerificationId != null ||
        _registrationResendToken != null ||
        _registrationPhoneCredential != null ||
        _registrationOtpVerified;

    _pendingRegistrationPhone = null;
    _registrationVerificationId = null;
    _registrationResendToken = null;
    _registrationPhoneCredential = null;
    _registrationOtpVerified = false;
    _isSendingRegistrationOtp = false;
    _isVerifyingRegistrationOtp = false;

    if (hadState) {
      notifyListeners();
    }
  }

  Future<bool> startPasswordRecovery(String phone) async {
    try {
      isLoading = true;
      _clearError();

      if (!_isValidYemeniPhone(phone)) {
        throw Exception('رقم الهاتف غير صحيح');
      }

      final user = await _fetchUserByPhone(phone);
      if (user == null) {
        throw Exception('لم يتم العثور على حساب مرتبط بهذا الرقم');
      }

      final otp = (Random().nextInt(900000) + 100000).toString();
      _pendingResetPhone = phone;
      _pendingResetOtp = otp;
      _pendingResetExpiry = DateTime.now().add(const Duration(minutes: 5));
      _pendingResetOtpVerified = false;

      await _firestore.collection('password_reset_requests').doc(user.id).set(
        {
          'phone': phone,
          'requestedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('OTP لاستعادة الحساب ($phone): $otp');

      isLoading = false;
      return true;
    } on Exception catch (e) {
      isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  bool verifyPasswordResetOtp(String phone, String otp) {
    if (_pendingResetPhone == null || _pendingResetOtp == null) {
      _error = 'الرجاء إرسال طلب استعادة جديد';
      notifyListeners();
      return false;
    }

    if (_pendingResetPhone != phone) {
      _error = 'رقم الهاتف لا يطابق الطلب الحالي';
      notifyListeners();
      return false;
    }

    if (_pendingResetExpiry == null ||
        DateTime.now().isAfter(_pendingResetExpiry!)) {
      _error = 'انتهت صلاحية كود التحقق، الرجاء إعادة الإرسال';
      notifyListeners();
      return false;
    }

    if (_pendingResetOtp != otp.trim()) {
      _error = 'كود التحقق غير صحيح';
      notifyListeners();
      return false;
    }

    _pendingResetOtpVerified = true;
    _error = null;
    notifyListeners();
    return true;
  }

  Future<bool> completePasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      isLoading = true;
      _clearError();

      if (_pendingResetPhone == null ||
          _pendingResetOtp == null ||
          _pendingResetExpiry == null) {
        throw Exception('لا يوجد طلب استعادة فعال');
      }

      if (_pendingResetPhone != phone) {
        throw Exception('رقم الهاتف لا يطابق الطلب الحالي');
      }

      if (!_pendingResetOtpVerified || _pendingResetOtp != otp.trim()) {
        throw Exception('الرجاء التحقق من كود الاستعادة أولاً');
      }

      if (_pendingResetExpiry != null &&
          DateTime.now().isAfter(_pendingResetExpiry!)) {
        throw Exception('انتهت صلاحية كود التحقق');
      }

      if (newPassword.length < 6) {
        throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      }

      final user = await _fetchUserByPhone(phone);
      if (user == null) {
        throw Exception('لم يتم العثور على حساب مرتبط بهذا الرقم');
      }

      // حفظ كلمة المرور الجديدة في Firestore مؤقتاً
      await _firestore.collection('password_reset_requests').doc(user.id).set(
        {
          'phone': phone,
          'newPassword': newPassword,
          'verified': true,
          'requestedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('✅ تم حفظ كلمة المرور الجديدة مؤقتاً لـ: $phone');
      debugPrint('⚠️ ملاحظة: يجب تطبيق كلمة المرور عند تسجيل الدخول التالي');

      // تنظيف البيانات المؤقتة
      _pendingResetPhone = null;
      _pendingResetOtp = null;
      _pendingResetExpiry = null;
      _pendingResetOtpVerified = false;

      isLoading = false;
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      isLoading = false;
      _error = e.message ?? 'تعذر تحديث كلمة المرور، يرجى المحاولة لاحقًا';
      notifyListeners();
      return false;
    } on Exception catch (e) {
      isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// تطبيق كلمة المرور الجديدة عند تسجيل الدخول (إذا كانت موجودة)
  Future<void> _applyPendingPasswordReset(String userId) async {
    try {
      final resetDoc = await _firestore
          .collection('password_reset_requests')
          .doc(userId)
          .get();

      if (!resetDoc.exists) return;

      final data = resetDoc.data();
      if (data == null) return;

      final verified = data['verified'] as bool? ?? false;
      final newPassword = data['newPassword'] as String?;

      if (verified && newPassword != null && newPassword.isNotEmpty) {
        debugPrint('🔄 تطبيق كلمة المرور الجديدة...');

        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.updatePassword(newPassword);
          debugPrint('✅ تم تحديث كلمة المرور بنجاح');

          // حذف طلب إعادة التعيين
          await _firestore
              .collection('password_reset_requests')
              .doc(userId)
              .delete();
        }
      }
    } catch (e) {
      debugPrint('⚠️ فشل تطبيق كلمة المرور الجديدة: $e');
      // لا نرمي استثناء لأن هذا لا يجب أن يمنع تسجيل الدخول
    }
  }

  Future<void> logout() async {
    try {
      isLoading = true;

      // حذف البيانات من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');

      // حذف جميع بيانات الـ cache
      if (_user != null) {
        await CacheService.clearUserCache(_user!.id);
      }
      await CacheService.clearAllCache();
      print('🗑️ All cache cleared on logout');

      await _firebaseAuth.signOut();

      _user = null;
      resetRegistrationOtpState();
      isLoading = false;
      notifyListeners();
    } on Exception catch (e) {
      print('❌ Logout error: $e');
      isLoading = false;
      _error = 'فشل في تسجيل الخروج';
      notifyListeners();
    }
  }

  /// تحديث معلومات المستخدم في Firestore والتخزين المحلي
  Future<bool> updateUserProfile({
    String? name,
    String? networkName,
    String? email,
    String? secondPhone,
    File? profileImage,
  }) async {
    if (_user == null) {
      _error = 'لا يوجد مستخدم مسجل الدخول';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      _clearError();

      String? avatarUrl = _user!.avatar;

      // رفع صورة البروفايل إلى Firebase Storage إذا تم تحديدها
      if (profileImage != null) {
        try {
          final fileName =
              'profile_${_user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = _storage.ref().child('profile_images/$fileName');

          final uploadTask = storageRef.putFile(profileImage);
          final snapshot = await uploadTask;
          avatarUrl = await snapshot.ref.getDownloadURL();

          debugPrint('تم رفع الصورة بنجاح: $avatarUrl');
        } on FirebaseException catch (e) {
          debugPrint('فشل رفع الصورة: ${e.message}');
          throw Exception('فشل رفع الصورة: ${e.message}');
        }
      }

      // إنشاء نسخة محدثة من المستخدم - استخدام القيم الجديدة إذا تم تمريرها
      final updatedUser = User(
        id: _user!.id,
        name: name ?? _user!.name,
        email: email ?? _user!.email,
        phone: _user!.phone,
        type: _user!.type,
        avatar: avatarUrl,
        networkName: networkName ?? _user!.networkName,
        secondPhone: secondPhone ?? _user!.secondPhone,
        createdAt: _user!.createdAt,
      );

      debugPrint('تحديث بيانات المستخدم: ${updatedUser.toJson()}');

      // حفظ في Firestore
      await _saveUserToFirestore(updatedUser);

      // تحديث البيانات المحلية
      _user = updatedUser;
      await _saveUserToStorage(updatedUser);

      debugPrint('تم حفظ البيانات بنجاح');

      isLoading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('خطأ في تحديث البروفايل: $_error');
      notifyListeners();
      return false;
    }
  }

  /// تغيير كلمة المرور
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
      if (firebaseUser == null || firebaseUser.email == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم');
      }

      // إعادة المصادقة بكلمة المرور الحالية
      final credential = fb_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      // تحديث كلمة المرور
      await firebaseUser.updatePassword(newPassword);

      isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      isLoading = false;
      if (e.code == 'wrong-password') {
        _error = 'كلمة المرور الحالية غير صحيحة';
      } else if (e.code == 'weak-password') {
        _error = 'كلمة المرور الجديدة ضعيفة';
      } else {
        _error = e.message ?? 'فشل تغيير كلمة المرور';
      }
      notifyListeners();
      return false;
    } on Exception catch (e) {
      isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Removed old simple setter (moved above with change notification & guard)

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _formatPhoneToE164(String phone) {
    var digits = phone.replaceAll(RegExp('[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+967$digits';
  }

  String _mapFirebaseOtpError(fb_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صالح';
      case 'too-many-requests':
        return 'تم تجاوز الحد المسموح به لمحاولات التحقق. حاول لاحقًا.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالشبكة، يرجى المحاولة لاحقًا.';
      case 'session-expired':
      case 'code-expired':
        return 'انتهت صلاحية كود التحقق. الرجاء طلب كود جديد.';
      case 'invalid-verification-code':
        return 'كود التحقق غير صحيح.';
      default:
        return error.message ?? 'تعذر إكمال عملية التحقق.';
    }
  }

  // التحقق من صحة رقم الهاتف اليمني
  bool _isValidYemeniPhone(String phone) {
    final phoneDigits = phone.replaceAll(RegExp(r'[\s-]'), '');
    final validPrefixes = [
      '777',
      '773',
      '770',
      '771',
      '772',
      '774',
      '775',
      '776',
      '778',
      '779',
      '733',
      '734',
      '735',
      '736',
      '737',
      '738',
      '739',
      '730',
      '731',
      '732',
      '780',
      '781',
      '782',
      '783',
      '784',
      '785',
      '786',
      '787',
      '788',
      '789',
    ];

    return phoneDigits.length == 9 && validPrefixes.any(phoneDigits.startsWith);
  }

  // محاكاة الحصول على الاسم بناءً على رقم الهاتف
  String _getNameByPhone(String phone) {
    if (phone.startsWith('777')) return 'أحمد محمد';
    if (phone.startsWith('733')) return 'فاطمة علي';
    return 'مستخدم جديد';
  }

  String _emailFromPhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp('[^0-9]'), '');
    return '$digitsOnly@networkapp.app';
  }

  // محاكاة تحديد نوع المستخدم بناءً على رقم الهاتف
  UserType _getUserTypeByPhone(String phone) {
    if (phone.startsWith('777') || phone.startsWith('733')) {
      return UserType.networkOwner;
    }
    return UserType.posVendor;
  }
}
