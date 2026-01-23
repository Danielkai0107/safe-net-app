import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 時間軸底部彈窗
class TimelineBottomSheet extends StatefulWidget {
  const TimelineBottomSheet({super.key});

  @override
  State<TimelineBottomSheet> createState() => _TimelineBottomSheetState();
}

class _TimelineBottomSheetState extends State<TimelineBottomSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();
  ScrollController? _scrollController; // 列表滾動控制器
  String? _lastActivityId; // 追蹤最新活動 ID

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 滾動到頂部
  void _scrollToTop() {
    if (_scrollController != null && _scrollController!.hasClients) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// 檢查是否有新活動並自動收合
  void _checkAndCollapseOnNewActivity(List<Activity> activities) {
    if (activities.isEmpty) return;

    final latestActivity = activities.first;

    // 如果有新活動且是通知點位
    if (_lastActivityId != latestActivity.id) {
      _lastActivityId = latestActivity.id;

      // 檢查是否為通知點位
      final userProvider = context.read<UserProvider>();
      try {
        final notificationPoint = userProvider.userProfile?.notificationPoints
            .firstWhere((point) => point.gatewayId == latestActivity.gatewayId);

        if (notificationPoint != null) {
          // 是通知點位，自動收合彈窗
          debugPrint('收到新通知，自動收合時間軸');
          if (_controller.isAttached && _controller.size > 0.5) {
            _scrollToTop();
            _controller.animateTo(
              0.12,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      } catch (e) {
        // 不是通知點位，不處理
      }
    }
  }

  /// 按日期分組活動記錄
  Map<String, List<Activity>> _groupActivitiesByDate(
    List<Activity> activities,
  ) {
    final grouped = <String, List<Activity>>{};

    for (final activity in activities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(activity.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(activity);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, MapProvider>(
      builder: (context, userProvider, mapProvider, child) {
        final boundDevice = userProvider.boundDevice;
        final activities = mapProvider.activities;

        // 如果沒有綁定設備，不顯示彈窗
        if (boundDevice == null) {
          return const SizedBox.shrink();
        }

        // 檢查是否有新活動並自動收合
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndCollapseOnNewActivity(activities);
        });

        return DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: 0.12, // 預覽模式高度（12%）
          minChildSize: 0.12,
          maxChildSize: 0.85, // 完整模式高度（85%）
          snap: true,
          snapSizes: const [0.12, 0.85],
          builder: (context, scrollController) {
            // 保存 scrollController 供收合時使用
            _scrollController = scrollController;
            return Container(
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.borderRadiusLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // Header 區域（固定）
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // 拖曳指示器
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppConstants.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // 頂部資訊
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 左側：設備頭像 + 名稱
                              Row(
                                children: [
                                  // 設備頭像
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppConstants.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/avatar/${userProvider.userProfile?.avatar ?? "01.png"}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.2),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: AppConstants.primaryColor,
                                              size: 28,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: AppConstants.paddingMedium,
                                  ),
                                  // 設備名稱（放大字體）
                                  Text(
                                    boundDevice.displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textColor,
                                    ),
                                  ),
                                ],
                              ),
                              // 右側：日期顯示
                              if (activities.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Helpers.formatTime(
                                        activities.first.timestamp,
                                      ),
                                      style: const TextStyle(
                                        fontSize: AppConstants.fontSizeLarge,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      '最新更新',
                                      style: TextStyle(
                                        fontSize: AppConstants.fontSizeSmall,
                                        color: AppConstants.textColor
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  '向上滑動查看足跡',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeSmall,
                                    color: AppConstants.textColor.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 內容區域
                  if (activities.isEmpty)
                    _buildEmptyStateSliver()
                  else
                    _buildActivityListSliver(activities),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyStateSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.location_on_outlined,
              size: 64,
              color: AppConstants.textColor.withOpacity(0.3),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              '尚無活動記錄',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              '當設備經過任何接收點時，\n這裡會顯示活動足跡記錄',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textColor.withOpacity(0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        size: 20,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '提示',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 確保設備已開機並隨身攜帶\n• 經過地圖上的接收點會自動記錄\n• 設定通知點位可收到即時提醒',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeSmall,
                      color: AppConstants.textColor.withOpacity(0.7),
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityListSliver(List<Activity> activities) {
    final groupedActivities = _groupActivitiesByDate(activities);
    final dates = groupedActivities.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final date = dates[index];
          final dateActivities = groupedActivities[date]!;
          final dateTime = DateTime.parse(date);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期標題（置中對齊）
              Padding(
                padding: const EdgeInsets.only(
                  left: AppConstants.paddingMedium,
                  right: AppConstants.paddingMedium,
                  top: AppConstants.paddingSmall,
                  bottom: AppConstants.paddingMedium,
                ),
                child: Center(
                  child: Text(
                    Helpers.formatDateWithWeekday(dateTime),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                ),
              ),
              // 活動列表
              ...dateActivities.map((activity) => _buildActivityItem(activity)),
            ],
          );
        }, childCount: dates.length),
      ),
    );
  }

  Widget _buildActivityItem(Activity activity, {bool isPreview = false}) {
    // 判斷是否為最新活動
    final isLatest =
        !isPreview &&
        context.read<MapProvider>().activities.firstOrNull?.id == activity.id;

    // 前端判斷：通過 gatewayId 查找通知點詳情
    String displayTitle = activity.gatewayName;
    String notificationMessage = '暫無通知';
    bool hasNotificationPoint = false;

    final userProvider = context.read<UserProvider>();
    try {
      // 透過 gatewayId 找到對應的通知點位
      final notificationPoint = userProvider.userProfile?.notificationPoints
          .firstWhere((point) => point.gatewayId == activity.gatewayId);
      if (notificationPoint != null) {
        displayTitle = notificationPoint.name;
        notificationMessage = notificationPoint.notificationMessage;
        hasNotificationPoint = true;
        debugPrint(
          '找到通知點 (gatewayId: ${activity.gatewayId}): $displayTitle -> $notificationMessage',
        );
      }
    } catch (e) {
      // 找不到通知點位，使用預設的 gateway 資訊
      debugPrint('此 gateway 未設定為通知點 (gatewayId: ${activity.gatewayId})');
    }

    return GestureDetector(
      onTap: () async {
        debugPrint('點擊活動項目: ${activity.gatewayName}');

        // 先收起彈窗（使用 jumpTo 立即停止滾動，然後 animateTo 收合）
        if (_controller.isAttached) {
          try {
            debugPrint('收合時間軸彈窗 (當前大小: ${_controller.size})');
            // 滾動到頂部
            _scrollToTop();
            // 先跳轉到當前大小（停止任何滾動動畫）
            _controller.jumpTo(_controller.size);
            // 然後平滑收合到預覽模式
            await _controller.animateTo(
              0.12,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            debugPrint('收合完成');
          } catch (e) {
            debugPrint('收合時發生錯誤: $e');
          }
        } else {
          debugPrint('警告: DraggableScrollableController 未附加');
        }

        // 延遲跳轉到地圖位置，確保收合動畫完成
        Future.delayed(const Duration(milliseconds: 350), () {
          final mapProvider = context.read<MapProvider>();
          mapProvider.updateCenter(
            LatLng(activity.latitude, activity.longitude),
            newZoom: 17.0,
          );
          debugPrint('地圖已更新至: (${activity.latitude}, ${activity.longitude})');
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppConstants.paddingLarge,
          right: AppConstants.paddingLarge,
          bottom: AppConstants.paddingMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左側時間軸（圓點 + 線）
            SizedBox(
              height: 90,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 34), // 對齊卡片中心
                  // 圓點（最新的要放大）
                  _buildTimelineDot(
                    isLatest: isLatest,
                    hasNotification: hasNotificationPoint,
                  ),
                  const SizedBox(height: 8),
                  // 連接線
                  Expanded(
                    child: Container(width: 1, color: AppConstants.borderColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // 右側內容卡片
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: isLatest
                      ? AppConstants.primaryColor
                      : AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題和時間
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 已通過：通知點名稱或地址名稱
                        Expanded(
                          child: Text(
                            '已通過：$displayTitle',
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: isLatest
                                  ? CupertinoColors.white
                                  : AppConstants.textColor,
                            ),
                          ),
                        ),
                        // 時間
                        Text(
                          Helpers.formatTime(activity.timestamp),
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: isLatest
                                ? CupertinoColors.white.withOpacity(0.9)
                                : AppConstants.textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 通知訊息
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificationMessage,
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeSmall,
                              color: isLatest
                                  ? CupertinoColors.white.withOpacity(0.8)
                                  : AppConstants.textColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                        // 通知標記
                        if (hasNotificationPoint)
                          Icon(
                            Icons.notifications_rounded,
                            size: 14,
                            color: isLatest
                                ? CupertinoColors.white
                                : const Color(0xFFFFC107), // 黃色
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立時間軸圓點（支援呼吸燈效果）
  Widget _buildTimelineDot({
    required bool isLatest,
    required bool hasNotification,
  }) {
    final dotColor = hasNotification
        ? const Color(0xFFFFC107) // 黃色
        : AppConstants.primaryColor;

    if (isLatest) {
      // 最新活動：放大 + 呼吸燈效果
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.2),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.cardColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
        onEnd: () {
          // 動畫結束後反向播放
          if (mounted) {
            setState(() {});
          }
        },
      );
    } else {
      // 一般活動：普通圓點
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppConstants.cardColor, width: 2),
        ),
      );
    }
  }
}
