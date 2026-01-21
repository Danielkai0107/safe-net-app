import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// 輔助工具類別
class Helpers {
  /// 格式化日期時間
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  /// 格式化日期
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd').format(dateTime);
  }

  /// 格式化時間
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// 格式化日期（含星期）
  static String formatDateWithWeekday(DateTime dateTime) {
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    final weekday = weekdays[dateTime.weekday % 7];
    return '${DateFormat('M/d').format(dateTime)}($weekday)';
  }

  /// 顯示錯誤對話框
  static void showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('確定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 顯示成功對話框
  static void showSuccessDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('確定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 顯示確認對話框
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('確定'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 顯示載入指示器
  static void showLoadingDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 20),
      ),
    );
  }
}
