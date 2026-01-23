import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 啟動畫面
/// 顯示 app logo 和載入指示器
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.primaryColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.map_rounded,
                size: 60,
                color: AppConstants.primaryColor,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // App 名稱
            const Text(
              '安全網地圖',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // 載入指示器
            const CupertinoActivityIndicator(
              radius: 16,
              color: CupertinoColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
