import 'package:flutter/cupertino.dart';

/// 應用程式常數
class AppConstants {
  // 色彩方案
  static const Color primaryColor = Color(0xFF4ECDC4); // 藍綠色
  static const Color secondaryColor = Color(0xFFFFC107); // 黃色
  static const Color backgroundColor = Color(0xFFF7F7F7); // 淺灰
  static const Color textColor = Color(0xFF2C3E50); // 深灰
  static const Color cardColor = Color(0xFFFFFFFF); // 白色
  static const Color borderColor = Color(0xFFE0E0E0); // 邊框灰

  // 守望點類型顏色
  static const Color schoolZoneColor = Color(0xFFFF6A95); // 學校守望點 - 粉紅
  static const Color safeZoneColor = Color(0xFF4ECDC4); // 可通知守望點 - 主色綠 #4ECDC4
  static const Color observeZoneColor = Color(0xFF00CCEA); // 僅紀錄守望點 - 藍色
  static const Color inactiveZoneColor = Color(0xFFC4C4C4); // 準備中 - 灰色
  
  // 地圖預設位置（台北 101）
  static const double defaultLatitude = 25.0330;
  static const double defaultLongitude = 121.5654;
  static const double defaultZoom = 15.0;
  
  // API 設定
  static const String apiBaseUrl = 'https://us-central1-safe-net-tw.cloudfunctions.net';
  
  // 圓角
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // 間距
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // 字體大小
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
}
