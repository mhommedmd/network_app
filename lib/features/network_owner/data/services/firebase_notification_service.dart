import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// خدمة Firebase لإدارة الإشعارات
class FirebaseNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _notificationsCollection = 'notifications';

  /// إنشاء إشعار جديد
  static Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore.collection(_notificationsCollection).add(notification.toJson());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('فشل في إنشاء الإشعار: $e');
    }
  }

  /// الحصول على إشعارات المستخدم
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map(NotificationModel.fromFirestore).toList();
      // ترتيب حسب التاريخ (الأحدث أولاً)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// الحصول على عدد الإشعارات غير المقروءة
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// تحديد الإشعار كمقروء
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_notificationsCollection).doc(notificationId).update({
        'isRead': true,
      });
    } on Exception catch (e) {
      throw Exception('فشل في تحديث الإشعار: $e');
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } on Exception catch (e) {
      throw Exception('فشل في تحديث الإشعارات: $e');
    }
  }

  /// حذف إشعار
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_notificationsCollection).doc(notificationId).delete();
    } on Exception catch (e) {
      throw Exception('فشل في حذف الإشعار: $e');
    }
  }

  /// حذف جميع الإشعارات المقروءة
  static Future<void> deleteReadNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on Exception catch (e) {
      throw Exception('فشل في حذف الإشعارات: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Helper Methods - إنشاء إشعارات محددة
  // ══════════════════════════════════════════════════════════════

  /// إشعار طلب جديد (للشبكة)
  static Future<void> notifyNewOrder({
    required String networkId,
    required String vendorName,
    required String orderId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: networkId,
      type: NotificationType.orderNew,
      title: 'طلب جديد',
      body: 'استلمت طلب كروت جديد من $vendorName',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'action': 'view_order',
      },
    );

    await createNotification(notification);
  }

  /// إشعار موافقة على طلب (للمتجر)
  static Future<void> notifyOrderApproved({
    required String vendorId,
    required String networkName,
    required String orderId,
    required int cardsCount,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: vendorId,
      type: NotificationType.orderApproved,
      title: 'تمت الموافقة على الطلب',
      body: 'وافق $networkName على طلبك وتم إضافة $cardsCount كرت إلى مخزونك',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'action': 'view_inventory',
      },
    );

    await createNotification(notification);
  }

  /// إشعار رفض طلب (للمتجر)
  static Future<void> notifyOrderRejected({
    required String vendorId,
    required String networkName,
    required String orderId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: vendorId,
      type: NotificationType.orderRejected,
      title: 'تم رفض الطلب',
      body: 'رفض $networkName طلبك. يمكنك التواصل معهم لمعرفة السبب',
      createdAt: DateTime.now(),
      data: {
        'orderId': orderId,
        'action': 'view_order',
      },
    );

    await createNotification(notification);
  }

  /// إشعار دفعة نقدية جديدة (للمتجر)
  static Future<void> notifyNewPayment({
    required String vendorId,
    required String networkName,
    required double amount,
    required String paymentId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: vendorId,
      type: NotificationType.paymentNew,
      title: 'دفعة نقدية جديدة',
      body: 'قام $networkName بإضافة دفعة نقدية بمبلغ ${amount.toStringAsFixed(0)} ر.ي الى حسابك',
      createdAt: DateTime.now(),
      data: {
        'paymentId': paymentId,
        'action': 'view_payments',
      },
    );

    await createNotification(notification);
  }

  /// إشعار موافقة على دفعة نقدية (للشبكة)
  static Future<void> notifyPaymentApproved({
    required String networkId,
    required String vendorName,
    required double amount,
    required String paymentId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: networkId,
      type: NotificationType.paymentApproved,
      title: 'تم تأكيد الدفعة النقدية',
      body: 'أكد $vendorName صحة الدفعة النقدية بمبلغ ${amount.toStringAsFixed(0)} ر.ي سيتم اضافتها الى حسابه',
      createdAt: DateTime.now(),
      data: {
        'paymentId': paymentId,
        'vendorName': vendorName,
        'action': 'view_transactions',
      },
    );

    await createNotification(notification);
  }

  /// إشعار رفض دفعة نقدية (للشبكة)
  static Future<void> notifyPaymentRejected({
    required String networkId,
    required String vendorName,
    required double amount,
    required String paymentId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: networkId,
      type: NotificationType.paymentRejected,
      title: 'تم رفض الدفعة النقدية',
      body: 'رفض $vendorName دفعة ${amount.toStringAsFixed(0)} ر.ي',
      createdAt: DateTime.now(),
      data: {
        'paymentId': paymentId,
        'vendorName': vendorName,
        'action': 'view_payments',
      },
    );

    await createNotification(notification);
  }
}
