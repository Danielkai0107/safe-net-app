import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/gateway.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 接收點詳情對話框
class GatewayDetailDialog extends StatefulWidget {
  final Gateway gateway;

  const GatewayDetailDialog({
    super.key,
    required this.gateway,
  });

  @override
  State<GatewayDetailDialog> createState() => _GatewayDetailDialogState();
}

class _GatewayDetailDialogState extends State<GatewayDetailDialog> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleAddNotification() async {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || message.isEmpty) {
      Helpers.showErrorDialog(context, '請填寫通知點位名稱和訊息');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final success = await mapProvider.addNotificationPoint(
      userId: userId,
      gatewayId: widget.gateway.id,
      name: name,
      notificationMessage: message,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '通知點位已新增');
    } else {
      Helpers.showErrorDialog(
        context,
        mapProvider.error ?? '新增通知點位失敗',
      );
    }
  }

  Future<void> _handleRemoveNotification() async {
    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final notificationPoint = mapProvider.getNotificationPoint(widget.gateway.id);
    if (notificationPoint == null) return;

    final confirmed = await Helpers.showConfirmDialog(
      context,
      '移除通知點位',
      '確定要移除此通知點位嗎？',
    );

    if (!confirmed || !mounted) return;

    final success = await mapProvider.removeNotificationPoint(
      pointId: notificationPoint.id,
      userId: userId,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '通知點位已移除');
    } else {
      Helpers.showErrorDialog(
        context,
        mapProvider.error ?? '移除通知點位失敗',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mapProvider = context.watch<MapProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final isNotified = mapProvider.isGatewayNotified(widget.gateway.id);

    return CupertinoActionSheet(
      title: Text(
        widget.gateway.name,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      message: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            widget.gateway.location,
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '類型: ${widget.gateway.type == "GENERAL" ? "一般" : "邊界"}',
            style: TextStyle(
              color: AppConstants.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          if (widget.gateway.poolType == "TENANT")
            Text(
              '(社區專用接收點)',
              style: TextStyle(
                color: AppConstants.secondaryColor,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        if (!isAuthenticated)
          CupertinoActionSheetAction(
            child: const Text('登入以設定通知'),
            onPressed: () {
              Navigator.of(context).pop();
              // 導航邏輯會自動返回登入頁面，因為用戶未登入
            },
          ),
        if (isAuthenticated && !isNotified)
          CupertinoActionSheetAction(
            child: const Text('新增通知點位'),
            onPressed: () {
              Navigator.of(context).pop();
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('新增通知點位'),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          controller: _nameController,
                          placeholder: '點位名稱（如：我的家）',
                          padding: const EdgeInsets.all(12),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _messageController,
                          placeholder: '通知訊息（如：已到達家門口）',
                          padding: const EdgeInsets.all(12),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('取消'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('新增'),
                      onPressed: _handleAddNotification,
                    ),
                  ],
                ),
              );
            },
          ),
        if (isAuthenticated && isNotified)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('取消通知點位'),
            onPressed: _handleRemoveNotification,
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: const Text('關閉'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
