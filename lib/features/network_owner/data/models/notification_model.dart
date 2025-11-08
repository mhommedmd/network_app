import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات الإشعارات
class NotificationModel {
  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String userId; // معرف المستخدم المستلم
  final String type; // نوع الإشعار: order, payment, etc
  final String title; // عنوان الإشعار
  final String body; // محتوى الإشعار
  final bool isRead; // هل تم قراءة الإشعار
  final DateTime createdAt;
  final Map<String, dynamic>? data; // بيانات إضافية للتنقل

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (data != null) 'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

/// أنواع الإشعارات
class NotificationType {
  static const String orderNew = 'order_new'; // طلب جديد
  static const String orderApproved = 'order_approved'; // تمت الموافقة
  static const String orderRejected = 'order_rejected'; // تم الرفض
  static const String paymentNew = 'payment_new'; // دفعة نقدية جديدة
  static const String paymentApproved = 'payment_approved'; // تمت الموافقة على الدفعة
  static const String paymentRejected = 'payment_rejected'; // تم رفض الدفعة
}
