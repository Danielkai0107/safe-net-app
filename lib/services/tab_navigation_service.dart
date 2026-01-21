import 'package:flutter/cupertino.dart';

/// Tab 導航服務
/// 用於在不同頁面間控制主畫面的 tab 切換
class TabNavigationService {
  static final TabNavigationService _instance =
      TabNavigationService._internal();
  factory TabNavigationService() => _instance;
  TabNavigationService._internal();

  CupertinoTabController? _tabController;

  /// 註冊 tab controller
  void registerTabController(CupertinoTabController controller) {
    _tabController = controller;
    debugPrint('TabNavigationService: Tab controller 已註冊');
  }

  /// 取消註冊 tab controller
  void unregisterTabController() {
    _tabController = null;
    debugPrint('TabNavigationService: Tab controller 已取消註冊');
  }

  /// 切換到指定的 tab
  void switchToTab(int index) {
    if (_tabController != null) {
      _tabController!.index = index;
      debugPrint('TabNavigationService: 切換到 tab $index');
    } else {
      debugPrint('TabNavigationService: Tab controller 未註冊');
    }
  }

  /// 切換到地圖 tab
  void switchToMapTab() {
    switchToTab(0);
  }

  /// 切換到個人資料 tab
  void switchToProfileTab() {
    switchToTab(1);
  }
}
