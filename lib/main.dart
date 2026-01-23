import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/map_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/tab_navigation_service.dart';
import 'utils/constants.dart';

/// 背景訊息處理器
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('處理背景訊息: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 設定背景訊息處理器
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const CupertinoApp(
        title: '安全網地圖',
        theme: CupertinoThemeData(
          primaryColor: AppConstants.primaryColor,
          scaffoldBackgroundColor: AppConstants.backgroundColor,
        ),
        home: AuthenticationWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// 認證包裝器 - 根據登入狀態導航到對應畫面
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _isCheckingAuth = true;
  String? _lastCheckedUserId;
  int _notificationDialogCount = 0; // 追蹤顯示的通知對話框數量
  String _loadingStatus = '正在載入...'; // 載入進度狀態

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 更新載入狀態顯示
  void _updateLoadingStatus(String status) {
    if (mounted) {
      setState(() {
        _loadingStatus = status;
      });
    }
  }

  /// 初始化 App - 統一載入所有必要資料
  Future<void> _initializeApp() async {
    try {
      // 步驟 1：檢查用戶狀態
      _updateLoadingStatus('檢查用戶狀態...');
      final hasUser = await _checkUserData();

      // 步驟 2：載入地圖接收點（訪客和登入用戶都需要）
      _updateLoadingStatus('載入接收點...');
      final mapProvider = context.read<MapProvider>();
      await mapProvider.loadGateways();

      // 步驟 3：如果已登入，載入通知點位
      final authProvider = context.read<AuthProvider>();
      if (hasUser && authProvider.user != null) {
        final userId = authProvider.user!.uid;

        _updateLoadingStatus('載入通知點位...');
        await mapProvider.loadNotificationPoints(userId);

        // 步驟 4：如果已綁定設備，啟動活動記錄監聽
        final userProvider = context.read<UserProvider>();
        if (userProvider.hasDevice) {
          _updateLoadingStatus('啟動活動記錄監聽...');
          mapProvider.startListeningToActivities(
            userId: userId,
            deviceId: userProvider.boundDevice?.id,
          );
        }
      }

      // 步驟 5：設置 Firebase Messaging
      _updateLoadingStatus('設置通知服務...');
      await _setupFirebaseMessaging();

    } catch (e) {
      debugPrint('初始化失敗: $e');
    } finally {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  /// 檢查並載入用戶資料
  Future<bool> _checkUserData() async {
    final authProvider = context.read<AuthProvider>();

    // 如果 Firebase Auth 有登入用戶
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final userId = authProvider.user!.uid;

      // 如果已經檢查過這個用戶，直接返回
      if (_lastCheckedUserId == userId) {
        final userProvider = context.read<UserProvider>();
        return userProvider.userProfile != null;
      }

      try {
        debugPrint('AuthWrapper: 檢查用戶資料 userId=$userId');

        // 嘗試載入後端用戶資料
        final userProvider = context.read<UserProvider>();
        await userProvider.loadUserProfile(userId);

        // 檢查是否成功載入
        if (userProvider.userProfile != null) {
          debugPrint('AuthWrapper: 用戶資料存在');
          _lastCheckedUserId = userId;
          return true;
        } else {
          debugPrint('AuthWrapper: 後端無用戶資料,登出 Firebase Auth');
          // 後端沒有用戶資料，登出 Firebase Auth
          await authProvider.signOut();
          _lastCheckedUserId = null;
          return false;
        }
      } catch (e) {
        debugPrint('AuthWrapper: 載入用戶資料失敗 - $e');
        // 載入失敗，登出
        await authProvider.signOut();
        _lastCheckedUserId = null;
        return false;
      }
    }

    _lastCheckedUserId = null;
    return false;
  }

  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // 請求通知權限
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('用戶已授權通知權限');

      // 取得 FCM Token
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');

        // 如果已登入，更新 FCM Token
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated) {
          final userProvider = context.read<UserProvider>();
          await userProvider.updateFcmToken(
            userId: authProvider.user!.uid,
            fcmToken: token,
          );
        }
      }

      // 監聽 Token 更新
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token 已更新: $newToken');
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated) {
          final userProvider = context.read<UserProvider>();
          userProvider.updateFcmToken(
            userId: authProvider.user!.uid,
            fcmToken: newToken,
          );
        }
      });
    }

    // 處理前景通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('========== 收到前景 FCM 訊息 ==========');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Notification: ${message.notification?.toMap()}');
      debugPrint('Data: ${message.data}');
      debugPrint('=====================================');

      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });

    // 處理通知點擊（app 在背景或關閉狀態）
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('========== 用戶點擊通知 (背景) ==========');
      debugPrint('Message ID: ${message.messageId}');
      debugPrint('Data: ${message.data}');
      debugPrint('=====================================');
      _handleNotificationTap(message);
    });

    // 檢查是否從通知啟動 app
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('========== 從通知啟動 app ==========');
      debugPrint('Message ID: ${initialMessage.messageId}');
      debugPrint('Data: ${initialMessage.data}');
      debugPrint('=====================================');
      _handleNotificationTap(initialMessage);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    debugPrint('收到新的前景通知');

    // 關閉所有現有的通知對話框
    if (_notificationDialogCount > 0) {
      debugPrint('關閉 $_notificationDialogCount 個舊通知對話框');
      for (int i = 0; i < _notificationDialogCount; i++) {
        Navigator.of(context).pop();
      }
      _notificationDialogCount = 0;
    }

    debugPrint('顯示前景通知對話框');
    debugPrint('標題: ${message.notification?.title}');
    debugPrint('內容: ${message.notification?.body}');

    // 增加計數
    _notificationDialogCount++;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(message.notification?.title ?? '位置通知'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.notification?.body ?? ''),
            if (message.data['gatewayName'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '接收點: ${message.data['gatewayName']}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('關閉'),
            onPressed: () {
              Navigator.of(context).pop();
              _notificationDialogCount--;
            },
          ),
          if (message.data.isNotEmpty)
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('查看位置'),
              onPressed: () {
                Navigator.of(context).pop();
                _notificationDialogCount--;
                // 延遲執行，確保對話框完全關閉後再處理導航
                Future.delayed(const Duration(milliseconds: 300), () {
                  _handleNotificationTap(message);
                });
              },
            ),
        ],
      ),
    ).then((_) {
      // 對話框關閉時減少計數（處理用戶點擊外部區域關閉的情況）
      if (mounted && _notificationDialogCount > 0) {
        _notificationDialogCount--;
        debugPrint('通知對話框已關閉，剩餘: $_notificationDialogCount');
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    debugPrint('處理通知點擊');
    debugPrint('通知類型: ${data['type']}');

    if (data['type'] == 'LOCATION_ALERT') {
      // 跳轉到地圖並定位到通知點位
      final latitude = double.tryParse(data['latitude'] ?? '');
      final longitude = double.tryParse(data['longitude'] ?? '');

      debugPrint('跳轉到地圖位置: ($latitude, $longitude)');

      if (latitude != null && longitude != null) {
        // 使用 TabNavigationService 切換到地圖 tab
        final tabNavService = TabNavigationService();
        tabNavService.switchToMapTab();

        // 延遲更新地圖位置，確保已切換到地圖 tab
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            final mapProvider = context.read<MapProvider>();
            mapProvider.updateCenter(
              LatLng(latitude, longitude),
              newZoom: 17.0,
            );
            debugPrint('地圖已更新至通知位置');
          }
        });
      } else {
        debugPrint('無效的座標資料');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 正在檢查認證狀態，顯示 Loading 和進度
    if (_isCheckingAuth) {
      return CupertinoPageScaffold(
        backgroundColor: AppConstants.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_rounded,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                '安全網地圖',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 32),
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 16),
              Text(
                _loadingStatus,
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final isAuthenticated = authProvider.user != null;

        // 當用戶狀態改變時，重新檢查用戶資料
        if (isAuthenticated && authProvider.user!.uid != _lastCheckedUserId) {
          // 在下一幀檢查用戶資料，避免在 build 過程中調用 setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkUserData();
          });
        }

        // 訪客模式：未登入也能直接看地圖
        return const HomeScreen();
      },
    );
  }
}
