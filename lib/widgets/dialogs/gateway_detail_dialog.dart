import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/gateway.dart';
import '../../models/notification_point.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 接收點詳情對話框
class GatewayDetailDialog extends StatefulWidget {
  final Gateway gateway;

  const GatewayDetailDialog({super.key, required this.gateway});

  @override
  State<GatewayDetailDialog> createState() => _GatewayDetailDialogState();
}

class _GatewayDetailDialogState extends State<GatewayDetailDialog> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _showAddForm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _showFormAndFocus() {
    setState(() {
      _showAddForm = true;
    });
    // 延遲聚焦，等待表單渲染完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  Future<void> _handleAddNotification() async {
    if (_isLoading) return; // 防止重複提交

    final name = _nameController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || message.isEmpty) {
      Helpers.showErrorDialog(context, '請填寫通知點位名稱和訊息');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await mapProvider.addNotificationPoint(
      userId: userId,
      gatewayId: widget.gateway.id,
      name: name,
      notificationMessage: message,
    );

    if (!mounted) return;

    // 重新載入 UserProvider 的資料以同步通知點位清單
    if (success) {
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserProfile(userId);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '通知點位已新增');
    } else {
      Helpers.showErrorDialog(context, mapProvider.error ?? '新增通知點位失敗');
    }
  }

  Future<void> _handleRemoveNotification() async {
    if (_isLoading) return; // 防止重複提交

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    // 從 UserProvider 取得通知點位
    final allNotificationPoints =
        userProvider.userProfile?.notificationPoints ?? [];
    NotificationPoint? notificationPoint;
    try {
      notificationPoint = allNotificationPoints.firstWhere(
        (point) => point.gatewayId == widget.gateway.id && point.isActive,
      );
    } catch (e) {
      notificationPoint = null;
    }

    if (notificationPoint == null) return;

    final confirmed = await Helpers.showConfirmDialog(
      context,
      '移除通知點位',
      '確定要移除此通知點位嗎？',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    final success = await mapProvider.removeNotificationPoint(
      pointId: notificationPoint.id,
      userId: userId,
    );

    if (!mounted) return;

    // 重新載入 UserProvider 的資料以同步通知點位清單
    if (success) {
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserProfile(userId);
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '通知點位已移除');
    } else {
      Helpers.showErrorDialog(context, mapProvider.error ?? '移除通知點位失敗');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mapProvider = context.watch<MapProvider>();
    final userProvider = context.watch<UserProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    // 使用 UserProvider 的通知點位資料（更可靠）
    final allNotificationPoints =
        userProvider.userProfile?.notificationPoints ?? [];

    // 檢查是否已設定通知
    final isNotified = allNotificationPoints.any(
      (point) => point.gatewayId == widget.gateway.id && point.isActive,
    );

    // 取得通知點位
    NotificationPoint? notificationPoint;
    try {
      notificationPoint = allNotificationPoints.firstWhere(
        (point) => point.gatewayId == widget.gateway.id && point.isActive,
      );
    } catch (e) {
      // 找不到就是 null
      notificationPoint = null;
    }

    // Debug: 印出當前狀態
    debugPrint('GatewayDetailDialog: gateway=${widget.gateway.id}');
    debugPrint('GatewayDetailDialog: isNotified=$isNotified');
    debugPrint(
      'GatewayDetailDialog: UserProvider 通知點位數=${allNotificationPoints.length}',
    );
    debugPrint(
      'GatewayDetailDialog: MapProvider 通知點位數=${mapProvider.notificationPoints.length}',
    );
    for (var point in allNotificationPoints) {
      debugPrint(
        '  - ${point.name} (gatewayId=${point.gatewayId}, isActive=${point.isActive})',
      );
    }

    // 獲取鍵盤高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: keyboardHeight > 0 ? keyboardHeight : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖動指示器
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 標題和位置資訊
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.gateway.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 16,
                            color: AppConstants.textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.gateway.location,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppConstants.textColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.gateway.type == "GENERAL"
                                  ? "一般接收點"
                                  : widget.gateway.type == "BOUNDARY"
                                  ? "邊界接收點"
                                  : "移動接收點",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (widget.gateway.tenantId != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.secondaryColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '社區專用',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.secondaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 通知狀態顯示
                if (isAuthenticated && isNotified && notificationPoint != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.bell_fill,
                              size: 18,
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '已設定通知點位',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('名稱', notificationPoint.name),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          '通知訊息',
                          notificationPoint.notificationMessage,
                        ),
                      ],
                    ),
                  ),

                // 新增通知點位表單
                if (isAuthenticated && !isNotified && _showAddForm)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '新增通知點位',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          placeholder: '點位名稱（如：我的家）',
                          padding: const EdgeInsets.all(14),
                          textInputAction: TextInputAction.next,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _messageController,
                          placeholder: '通知訊息（如：已到達家門口）',
                          padding: const EdgeInsets.all(14),
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // 操作按鈕
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (!isAuthenticated)
                        _buildActionButton(
                          label: '登入以設定通知',
                          icon: CupertinoIcons.person_circle,
                          color: AppConstants.primaryColor,
                          onPressed: () => Navigator.of(context).pop(),
                        ),

                      if (isAuthenticated && !isNotified && !_showAddForm)
                        _buildActionButton(
                          label: '新增通知點位',
                          icon: CupertinoIcons.bell_fill,
                          color: AppConstants.primaryColor,
                          onPressed: _showFormAndFocus,
                        ),

                      if (isAuthenticated && !isNotified && _showAddForm) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: '取消',
                                icon: CupertinoIcons.xmark,
                                color: CupertinoColors.systemGrey,
                                onPressed: () {
                                  if (!_isLoading) {
                                    setState(() {
                                      _showAddForm = false;
                                      _nameController.clear();
                                      _messageController.clear();
                                    });
                                  }
                                },
                                showLoading: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                label: '確認新增',
                                icon: CupertinoIcons.checkmark_alt,
                                color: AppConstants.primaryColor,
                                onPressed: _handleAddNotification,
                                showLoading: _isLoading,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (isAuthenticated && isNotified)
                        _buildActionButton(
                          label: '移除通知點位',
                          icon: CupertinoIcons.bell_slash_fill,
                          color: CupertinoColors.systemRed,
                          onPressed: _handleRemoveNotification,
                          showLoading: _isLoading,
                        ),

                      const SizedBox(height: 12),

                      _buildActionButton(
                        label: '關閉',
                        icon: CupertinoIcons.xmark_circle,
                        color: CupertinoColors.systemGrey2,
                        onPressed: () => Navigator.of(context).pop(),
                        outlined: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textColor.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
    bool showLoading = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: showLoading ? null : onPressed,
      child: Opacity(
        opacity: showLoading ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: outlined ? CupertinoColors.white : color,
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: showLoading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: outlined ? color : CupertinoColors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: outlined ? color : CupertinoColors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: outlined ? color : CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
