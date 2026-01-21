import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/notification_point.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 通知點列表頁面
class NotificationPointsScreen extends StatelessWidget {
  const NotificationPointsScreen({super.key});

  Future<void> _handleRemove(
    BuildContext context,
    NotificationPoint point,
  ) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      '移除通知點位',
      '確定要移除「${point.name}」嗎？',
    );

    if (!confirmed || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final success = await mapProvider.removeNotificationPoint(
      pointId: point.id,
      userId: userId,
    );

    if (!context.mounted) return;

    if (success) {
      // 重新載入用戶資料
      await userProvider.loadUserProfile(userId);
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
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppConstants.backgroundColor,
        border: null,
        middle: const Text('通知點位'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final notificationPoints = userProvider.userProfile?.notificationPoints ?? [];

            if (notificationPoints.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      size: 64,
                      color: AppConstants.textColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      '尚未設定任何通知點位',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeLarge,
                        color: AppConstants.textColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      '在地圖上點擊接收點即可新增',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeMedium,
                        color: AppConstants.textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: notificationPoints.length,
              itemBuilder: (context, index) {
                final point = notificationPoints[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppConstants.cardColor,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 圖示
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppConstants.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          CupertinoIcons.bell_fill,
                          color: AppConstants.secondaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      // 資訊
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point.name,
                              style: const TextStyle(
                                fontSize: AppConstants.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (point.gateway != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.location_fill,
                                    size: 14,
                                    color: AppConstants.textColor.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      point.gateway!.name,
                                      style: TextStyle(
                                        fontSize: AppConstants.fontSizeSmall,
                                        color: AppConstants.textColor.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              point.notificationMessage,
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeSmall,
                                color: AppConstants.textColor.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 刪除按鈕
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _handleRemove(context, point),
                        child: const Icon(
                          CupertinoIcons.trash,
                          color: AppConstants.secondaryColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
