import 'package:flutter/cupertino.dart';
import '../../utils/constants.dart';
import 'map_tab.dart';
import 'profile_tab.dart';

/// 主畫面 - 包含底部導覽列
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppConstants.cardColor,
        activeColor: AppConstants.primaryColor,
        inactiveColor: AppConstants.textColor.withOpacity(0.5),
        border: const Border(
          top: BorderSide(
            color: AppConstants.borderColor,
            width: 0.5,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map_fill),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill),
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
