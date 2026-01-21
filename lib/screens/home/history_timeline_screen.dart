import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/tab_navigation_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 歷史時間軸頁面
class HistoryTimelineScreen extends StatefulWidget {
  const HistoryTimelineScreen({super.key});

  @override
  State<HistoryTimelineScreen> createState() => _HistoryTimelineScreenState();
}

class _HistoryTimelineScreenState extends State<HistoryTimelineScreen> {
  late PageController _pageController;
  late List<DateTime> _dates;
  int _currentPageIndex = 0;
  final Map<String, List<Activity>> _activitiesCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 生成過去 30 天的日期列表
    _dates = List.generate(30, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });
    _currentPageIndex = 0;
    _pageController = PageController(initialPage: 0);

    // 載入今天的活動記錄
    _loadActivitiesForDate(_dates[0]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 載入指定日期的活動記錄
  Future<void> _loadActivitiesForDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    // 如果已經載入過，直接返回
    if (_activitiesCache.containsKey(dateKey)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.uid;

      if (userId != null) {
        final mapProvider = context.read<MapProvider>();

        // 計算當天的開始和結束時間（毫秒）
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        debugPrint('載入日期: $dateKey');
        debugPrint('開始時間: ${startOfDay.millisecondsSinceEpoch}');
        debugPrint('結束時間: ${endOfDay.millisecondsSinceEpoch}');

        await mapProvider.loadActivities(
          userId: userId,
          startTime: startOfDay.millisecondsSinceEpoch,
          endTime: endOfDay.millisecondsSinceEpoch,
          limit: 100,
        );

        if (mounted) {
          setState(() {
            _activitiesCache[dateKey] = List.from(mapProvider.activities);
            debugPrint('載入完成: ${_activitiesCache[dateKey]!.length} 筆記錄');
          });
        }
      }
    } catch (e) {
      debugPrint('載入活動記錄失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });

    // 載入新頁面的數據
    _loadActivitiesForDate(_dates[index]);

    // 預載入前後頁面的數據
    if (index > 0) {
      _loadActivitiesForDate(_dates[index - 1]);
    }
    if (index < _dates.length - 1) {
      _loadActivitiesForDate(_dates[index + 1]);
    }
  }

  void _handleActivityTap(Activity activity) {
    debugPrint('點擊歷史活動: ${activity.gatewayName}');

    // 切換到地圖 tab
    final tabNavService = TabNavigationService();
    tabNavService.switchToMapTab();

    // 延遲更新地圖位置
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final mapProvider = context.read<MapProvider>();
        mapProvider.updateCenter(
          LatLng(activity.latitude, activity.longitude),
          newZoom: 17.0,
        );
        debugPrint('地圖已更新至歷史位置');
      }
    });

    // 返回上一頁
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppConstants.backgroundColor,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('過去守護'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 日期 Tab 指示器
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingMedium,
              ),
              decoration: const BoxDecoration(
                color: AppConstants.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: AppConstants.borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // 日期顯示
                  Text(
                    Helpers.formatDateWithWeekday(_dates[_currentPageIndex]),
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  // 滑動提示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 16,
                        color: _currentPageIndex < _dates.length - 1
                            ? AppConstants.primaryColor
                            : AppConstants.textColor.withOpacity(0.3),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Text(
                        '第 ${_currentPageIndex + 1} / ${_dates.length} 天',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          color: AppConstants.textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: _currentPageIndex > 0
                            ? AppConstants.primaryColor
                            : AppConstants.textColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PageView 顯示不同日期的活動記錄
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                reverse: false, // 向右滑動是往前（更早的日期）
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);
                  final activities = _activitiesCache[dateKey] ?? [];

                  return _buildDayView(date, activities);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView(DateTime date, List<Activity> activities) {
    if (_isLoading && activities.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 20));
    }

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.moon_stars,
              size: 64,
              color: AppConstants.textColor.withOpacity(0.3),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              '這天沒有活動記錄',
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                color: AppConstants.textColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              '向左滑動查看更早的日期',
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
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Activity activity) {
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
      }
    } catch (e) {
      // 找不到通知點位，使用預設值
    }

    return GestureDetector(
      onTap: () => _handleActivityTap(activity),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppConstants.paddingMedium,
          right: AppConstants.paddingMedium,
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
                  // 圓點
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: hasNotificationPoint
                          ? const Color(0xFFFFC107) // 黃色
                          : AppConstants.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.cardColor,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 連接線
                  Expanded(
                    child: Container(width: 1, color: AppConstants.borderColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            // 右側內容卡片
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
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
                            style: const TextStyle(
                              fontSize: AppConstants.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                            ),
                          ),
                        ),
                        // 時間
                        Text(
                          Helpers.formatTime(activity.timestamp),
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textColor.withOpacity(0.6),
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
                              color: AppConstants.textColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                        // 通知標記
                        if (hasNotificationPoint)
                          const Icon(
                            CupertinoIcons.bell_fill,
                            size: 14,
                            color: Color(0xFFFFC107), // 黃色
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
}
