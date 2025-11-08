/// مساعد لاستخراج رسائل الخطأ الحقيقية
class ErrorHandler {
  /// استخراج رسالة الخطأ من Exception
  static String extractErrorMessage(dynamic error) {
    if (error == null) return 'حدث خطأ غير متوقع';

    var errorMessage = error.toString();

    // إزالة "Exception: " من البداية والمتكررة
    errorMessage = errorMessage
        .replaceAll('Exception: فشل في الموافقة على الطلب: Exception: ', '')
        .replaceAll('Exception: فشل في الموافقة على الطلب: ', '')
        .replaceAll('Exception: فشل في رفض الطلب: Exception: ', '')
        .replaceAll('Exception: فشل في رفض الطلب: ', '')
        .replaceAll('Exception: فشل في حفظ البيانات: Exception: ', '')
        .replaceAll('Exception: فشل في حفظ البيانات: ', '')
        .replaceAll('Exception: فشل في الحذف: Exception: ', '')
        .replaceAll('Exception: فشل في الحذف: ', '')
        .replaceAll('Exception: ', '');

    // إزالة "Exception: " المتبقية من أي مكان
    while (errorMessage.contains('Exception: ')) {
      errorMessage = errorMessage.replaceFirst('Exception: ', '');
    }

    // التعامل مع أخطاء Firebase الشائعة
    if (errorMessage.contains('permission-denied')) {
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'فشل الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى';
    } else if (errorMessage.contains('unavailable')) {
      return 'الخدمة غير متاحة حالياً. حاول مرة أخرى';
    } else if (errorMessage.contains('not-found')) {
      return 'البيانات المطلوبة غير موجودة';
    } else if (errorMessage.isEmpty) {
      return 'حدث خطأ غير متوقع';
    }

    return errorMessage;
  }

  /// استخراج رسالة مختصرة للخطأ
  static String getShortErrorMessage(dynamic error) {
    final fullMessage = extractErrorMessage(error);

    // إذا كانت الرسالة طويلة جداً، اختصرها
    if (fullMessage.length > 150) {
      return '${fullMessage.substring(0, 147)}...';
    }

    return fullMessage;
  }

  /// التحقق من نوع الخطأ
  static bool isStockError(dynamic error) {
    final message = extractErrorMessage(error);
    return message.contains('المخزون غير كافٍ') ||
        message.contains('متوفر:') ||
        message.contains('مطلوب:');
  }

  static bool isPermissionError(dynamic error) {
    final message = extractErrorMessage(error);
    return message.contains('صلاحية') || message.contains('permission-denied');
  }

  static bool isNetworkError(dynamic error) {
    final message = extractErrorMessage(error);
    return message.contains('network-request-failed') ||
        message.contains('الاتصال') ||
        message.contains('الإنترنت');
  }
}
