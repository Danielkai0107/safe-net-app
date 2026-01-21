import 'package:flutter/cupertino.dart';
import '../../services/tab_navigation_service.dart';
import '../../utils/constants.dart';
import 'map_tab.dart';
import 'profile_tab.dart';

/// 主畫面 - 包含底部導覽列
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CupertinoTabController _tabController = CupertinoTabController();
  final TabNavigationService _tabNavService = TabNavigationService();

  @override
  void initState() {
    super.initState();
    // 註冊 tab controller 到導航服務
    _tabNavService.registerTabController(_tabController);
  }

  @override
  void dispose() {
    // 取消註冊
    _tabNavService.unregisterTabController();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: AppConstants.cardColor,
        activeColor: AppConstants.primaryColor,
        inactiveColor: AppConstants.textColor.withOpacity(0.5),
        height: 60, // 增加導覽列高度（預設 50）
        border: const Border(
          top: BorderSide(color: AppConstants.borderColor, width: 0.5),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.map_fill),
            ),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(CupertinoIcons.person_fill),
            ),
            label: '個人資料',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const MapTab();
          case 1:
            return const ProfileTab();
          default:
            return const MapTab();
        }
      },
    );
  }
}
