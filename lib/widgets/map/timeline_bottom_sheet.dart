import 'package:flutter/cupertino.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

        return DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: 0.15, // 預覽模式高度（15%）
          minChildSize: 0.15,
          maxChildSize: 0.85, // 完整模式高度（85%）
          snap: true,
          snapSizes: const [0.15, 0.85],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppConstants.cardColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.borderRadiusLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
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
                      children: [
                        // 設備頭像
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            color: AppConstants.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        // 設備資訊
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                boundDevice.displayName,
                                style: const TextStyle(
                                  fontSize: AppConstants.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textColor,
                                ),
                              ),
                              if (activities.isNotEmpty)
                                Text(
                                  '最後更新: ${Helpers.formatTime(activities.first.timestamp)}',
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
                        // 上箭頭提示
                        Icon(
                          CupertinoIcons.chevron_up,
                          color: AppConstants.textColor.withOpacity(0.5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  // 最新活動（預覽模式）
                  if (activities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                      ),
                      child: _buildActivityItem(
                        activities.first,
                        isPreview: true,
                      ),
                    ),

                  Container(height: 1, color: AppConstants.borderColor),

                  // 活動列表（完整模式）
                  Expanded(
                    child: activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.location,
                                  size: 48,
                                  color: AppConstants.textColor.withOpacity(
                                    0.3,
                                  ),
                                ),
                                const SizedBox(
                                  height: AppConstants.paddingMedium,
                                ),
                                Text(
                                  '尚無活動記錄',
                                  style: TextStyle(
                                    color: AppConstants.textColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildActivityList(scrollController, activities),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityList(
    ScrollController scrollController,
    List<Activity> activities,
  ) {
    final groupedActivities = _groupActivitiesByDate(activities);
    final dates = groupedActivities.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final dateActivities = groupedActivities[date]!;
        final dateTime = DateTime.parse(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期標題
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: AppConstants.paddingSmall,
              ),
              child: Text(
                Helpers.formatDateWithWeekday(dateTime),
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
            ),
            // 活動列表
            ...dateActivities.map((activity) => _buildActivityItem(activity)),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem(Activity activity, {bool isPreview = false}) {
    return GestureDetector(
      onTap: () {
        // 點擊跳轉到地圖對應位置
        final mapProvider = context.read<MapProvider>();
        mapProvider.updateCenter(
          LatLng(activity.latitude, activity.longitude),
          newZoom: 17.0,
        );

        // 收起彈窗
        if (_controller.isAttached) {
          _controller.animateTo(
            0.15,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall / 2,
        ),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: activity.triggeredNotification
              ? AppConstants.secondaryColor.withOpacity(0.1)
              : AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          border: Border.all(
            color: activity.triggeredNotification
                ? AppConstants.secondaryColor.withOpacity(0.3)
                : AppConstants.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 時間標記（綠色長條）
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            // 時間
            SizedBox(
              width: 50,
              child: Text(
                Helpers.formatTime(activity.timestamp),
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            // 位置圖示
            Icon(
              CupertinoIcons.location_fill,
              size: 20,
              color: AppConstants.textColor.withOpacity(0.6),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            // 地點資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.gatewayName,
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textColor,
                    ),
                  ),
                  if (!isPreview)
                    Text(
                      activity.gatewayLocation,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeSmall,
                        color: AppConstants.textColor.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            // 通知標記
            if (activity.triggeredNotification)
              const Icon(
                CupertinoIcons.bell_fill,
                size: 16,
                color: AppConstants.secondaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
