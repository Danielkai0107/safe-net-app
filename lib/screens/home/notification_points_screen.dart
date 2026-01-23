import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/notification_point.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/tab_navigation_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 通知點列表頁面
class NotificationPointsScreen extends StatefulWidget {
  const NotificationPointsScreen({super.key});

  @override
  State<NotificationPointsScreen> createState() =>
      _NotificationPointsScreenState();
}

class _NotificationPointsScreenState extends State<NotificationPointsScreen> {
  String? _removingPointId; // 記錄正在移除的點位 ID

  Future<void> _handleRemove(NotificationPoint point) async {
    if (_removingPointId != null) return; // 防止重複提交

    final confirmed = await Helpers.showConfirmDialog(
      context,
      '移除通知點位',
      '確定要移除「${point.name}」嗎？',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _removingPointId = point.id;
    });

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _removingPointId = null;
      });
      return;
    }

    final success = await mapProvider.removeNotificationPoint(
      pointId: point.id,
      userId: userId,
    );

    if (!mounted) return;

    setState(() {
      _removingPointId = null;
    });

    if (success) {
      // 重新載入用戶資料
      await userProvider.loadUserProfile(userId);
      Helpers.showSuccessDialog(context, '通知點位已移除');
    } else {
      Helpers.showErrorDialog(context, mapProvider.error ?? '移除通知點位失敗');
    }
  }

  void _handleViewLocation(NotificationPoint point) {
    if (point.gateway == null) return;

    debugPrint('查看通知點位位置: ${point.name}');
    debugPrint('位置: (${point.gateway!.latitude}, ${point.gateway!.longitude})');

    // 切換到地圖 tab
    final tabNavService = TabNavigationService();
    tabNavService.switchToMapTab();

    // 延遲更新地圖位置，確保已切換到地圖 tab
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final mapProvider = context.read<MapProvider>();
        mapProvider.updateCenter(
          LatLng(point.gateway!.latitude, point.gateway!.longitude),
          newZoom: 17.0,
        );
        debugPrint('地圖已更新至通知點位');
      }
    });

    // 返回上一頁
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // 自定義 AppBar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppConstants.backgroundColor,
              child: Row(
                children: [
                  // 返回按鈕（靠左）
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                  // 標題（置中）
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -6),
                      child: const Text(
                        '通知點位',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColor,
                        ),
                      ),
                    ),
                  ),
                  // 佔位（保持標題置中）
                  const SizedBox(width: 44),
                ],
              ),
            ),
            // 內容區域
            Expanded(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final notificationPoints =
                      userProvider.userProfile?.notificationPoints ?? [];

                  if (notificationPoints.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
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
                        margin: const EdgeInsets.only(
                          bottom: AppConstants.paddingMedium,
                        ),
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.cardColor,
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(
                                0.1,
                              ),
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
                                color: AppConstants.secondaryColor.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
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
                                        Expanded(
                                          child: Text(
                                            point.gateway!.name,
                                            style: TextStyle(
                                              fontSize:
                                                  AppConstants.fontSizeSmall,
                                              color: AppConstants.textColor
                                                  .withOpacity(0.6),
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
                                      color: AppConstants.textColor.withOpacity(
                                        0.8,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 查看位置按鈕
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _removingPointId != null
                                  ? null
                                  : () => _handleViewLocation(point),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: _removingPointId != null
                                    ? AppConstants.primaryColor.withOpacity(0.3)
                                    : AppConstants.primaryColor,
                                size: 24,
                              ),
                            ),
                            // 刪除按鈕
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _removingPointId != null
                                  ? null
                                  : () => _handleRemove(point),
                              child: _removingPointId == point.id
                                  ? const CupertinoActivityIndicator(
                                      color: AppConstants.secondaryColor,
                                    )
                                  : Icon(
                                      Icons.delete_rounded,
                                      color: _removingPointId != null
                                          ? AppConstants.secondaryColor
                                                .withOpacity(0.3)
                                          : AppConstants.secondaryColor,
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
          ],
        ),
      ),
    );
  }
}
