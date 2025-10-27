import 'package:flutter/material.dart';
import '../widgets/toast/toast.dart';

/// مساعد لعرض Toast بسهولة في جميع أنحاء التطبيق
class ToastHelper {
  /// نجاح العملية
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
  }) {
    CustomToast.success(context, message, title: title);
  }

  /// فشل العملية
  static void showError(
    BuildContext context,
    String message, {
    String? title,
  }) {
    CustomToast.error(context, message, title: title);
  }

  /// تحذير
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
  }) {
    CustomToast.warning(context, message, title: title);
  }

  /// معلومة
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
  }) {
    CustomToast.info(context, message, title: title);
  }

  // رسائل شائعة جاهزة

  static void savedSuccessfully(BuildContext context, [String? itemName]) {
    showSuccess(
      context,
      itemName != null ? 'تم حفظ $itemName بنجاح' : 'تم الحفظ بنجاح',
      title: 'تم الحفظ',
    );
  }

  static void deletedSuccessfully(BuildContext context, [String? itemName]) {
    showSuccess(
      context,
      itemName != null ? 'تم حذف $itemName بنجاح' : 'تم الحذف بنجاح',
      title: 'تم الحذف',
    );
  }

  static void updatedSuccessfully(BuildContext context, [String? itemName]) {
    showSuccess(
      context,
      itemName != null ? 'تم تحديث $itemName بنجاح' : 'تم التحديث بنجاح',
      title: 'تم التحديث',
    );
  }

  static void operationFailed(BuildContext context, [String? reason]) {
    showError(
      context,
      reason ?? 'حدث خطأ غير متوقع. حاول مرة أخرى',
      title: 'فشلت العملية',
    );
  }

  static void networkError(BuildContext context) {
    showError(
      context,
      'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
      title: 'خطأ في الاتصال',
    );
  }

  static void insufficientStock(BuildContext context, String itemName) {
    showWarning(
      context,
      'الكمية المطلوبة غير متوفرة في المخزون',
      title: 'مخزون غير كافي',
    );
  }

  static void loginRequired(BuildContext context) {
    showWarning(
      context,
      'يرجى تسجيل الدخول للمتابعة',
      title: 'تسجيل الدخول مطلوب',
    );
  }
}
