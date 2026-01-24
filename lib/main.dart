import 'dart:async';
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
import 'services/account_deleted_handler.dart';
import 'services/tab_navigation_service.dart';
import 'utils/constants.dart';

/// 背景訊息處理器
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('========== 處理背景訊息 ==========');
  debugPrint('Message ID: ${message.messageId}');
  debugPrint('Data: ${message.data}');

  // 檢查是否為帳號刪除通知
  if (message.data['type'] == 'ACCOUNT_DELETED') {
    debugPrint('收到帳號刪除通知（背景）');
    debugPrint('用戶點擊通知後會在 app 中處理登出流程');
  }

  debugPrint('==================================');
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
  OverlayEntry? _notificationOverlay; // 當前通知彈窗的 OverlayEntry
  String _loadingStatus = '正在載入...'; // 載入進度狀態
  StreamSubscription<String>? _accountDeletedSubscription; // 帳號刪除事件監聽

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupAccountDeletedListener();
  }

  @override
  void dispose() {
    _dismissNotificationOverlay();
    _accountDeletedSubscription?.cancel();
    super.dispose();
  }

  /// 設置帳號刪除事件監聽
  ///
  /// 當 API 回傳用戶不存在時，會自動觸發登出並顯示提示
  void _setupAccountDeletedListener() {
    final handler = AccountDeletedHandler();
    _accountDeletedSubscription = handler.onAccountDeleted.listen((reason) {
      debugPrint('========== 收到帳號刪除事件 ==========');
      debugPrint('原因: $reason');
      debugPrint('====================================');

      if (mounted) {
        _handleAccountDeletedFromApi(reason);
      }
    });
  }

  /// 處理 API 檢測到的帳號刪除
  Future<void> _handleAccountDeletedFromApi(String reason) async {
    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();

      // 如果用戶已經登出，不需要再處理
      if (!authProvider.isAuthenticated) {
        debugPrint('用戶已登出，跳過帳號刪除處理');
        return;
      }

      final mapProvider = context.read<MapProvider>();
      final userProvider = context.read<UserProvider>();

      // 清除所有狀態並登出
      await authProvider.signOut();
      mapProvider.reset();
      userProvider.reset();
      _lastCheckedUserId = null;

      debugPrint('已清除所有本地資料並登出（API 檢測）');

      // 顯示提示訊息
      if (mounted) {
        _dismissNotificationOverlay();

        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('帳號已被刪除'),
            content: const Text('您的帳號已被管理員刪除，請重新登入或聯繫客服。'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('確定'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('處理帳號刪除事件時發生錯誤: $e');
    }
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
  /// 
  /// 簡化後的邏輯：根據 AuthState 判斷是否需要載入用戶資料
  Future<bool> _checkUserData() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    // 如果正在認證中，等待認證完成
    if (authProvider.authState == AuthState.authenticating) {
      debugPrint('AuthWrapper: 認證進行中，等待完成');
      return true;
    }

    // 如果未認證，清除狀態
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      _lastCheckedUserId = null;
      return false;
    }

    final userId = authProvider.user!.uid;

    // 如果正在載入用戶資料，等待載入完成
    if (userProvider.isLoading) {
      debugPrint('AuthWrapper: 用戶資料載入中，等待完成');
      return true;
    }

    // 如果已經檢查過這個用戶且有資料，直接返回成功
    if (_lastCheckedUserId == userId && userProvider.userProfile != null) {
      return true;
    }

    // 如果用戶資料已經存在（但可能是不同用戶），直接使用
    if (userProvider.userProfile?.id == userId) {
      debugPrint('AuthWrapper: 用戶資料已存在');
      _lastCheckedUserId = userId;
      return true;
    }

    // 載入後端用戶資料
    try {
      debugPrint('AuthWrapper: 載入用戶資料 userId=$userId');

      final didLoad = await userProvider.loadUserProfile(userId);

      // 如果載入被跳過（正在載入中），等待完成
      if (!didLoad) {
        debugPrint('AuthWrapper: 載入被跳過，等待完成');
        return true;
      }

      // 檢查載入結果
      if (userProvider.userProfile != null) {
        debugPrint('AuthWrapper: 用戶資料載入成功');
        _lastCheckedUserId = userId;
        return true;
      } else {
        // 後端無用戶資料，登出 Firebase Auth
        debugPrint('AuthWrapper: 後端無用戶資料，登出 Firebase Auth');
        await authProvider.signOut();
        _lastCheckedUserId = null;
        return false;
      }
    } catch (e) {
      debugPrint('AuthWrapper: 載入用戶資料失敗 - $e');
      await authProvider.signOut();
      _lastCheckedUserId = null;
      return false;
    }
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

      // 檢查是否為帳號刪除通知
      if (message.data['type'] == 'ACCOUNT_DELETED') {
        debugPrint('收到帳號刪除通知，開始處理登出流程');
        _handleAccountDeleted(message);
        return;
      }

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

  /// 關閉當前通知彈窗
  void _dismissNotificationOverlay() {
    if (_notificationOverlay != null) {
      debugPrint('移除舊通知彈窗');
      _notificationOverlay!.remove();
      _notificationOverlay = null;
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    debugPrint('收到新的前景通知');

    // 如果已有通知對話框正在顯示，先移除它
    _dismissNotificationOverlay();

    debugPrint('顯示前景通知對話框');
    debugPrint('標題: ${message.notification?.title}');
    debugPrint('內容: ${message.notification?.body}');

    // 創建新的 OverlayEntry
    _notificationOverlay = OverlayEntry(
      builder: (overlayContext) => Material(
        color: Colors.black54,
        child: Center(
          child: CupertinoAlertDialog(
            title: Text(message.notification?.title ?? '新守望通知'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification?.body ?? ''),
                if (message.data['gatewayName'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '通過守望點: ${message.data['gatewayName']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('關閉'),
                onPressed: () {
                  _dismissNotificationOverlay();
                },
              ),
              if (message.data.isNotEmpty)
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('查看位置'),
                  onPressed: () {
                    _dismissNotificationOverlay();
                    // 延遲執行，確保彈窗完全關閉後再處理導航
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _handleNotificationTap(message);
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );

    // 插入到 Overlay
    Overlay.of(context).insert(_notificationOverlay!);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    debugPrint('處理通知點擊');
    debugPrint('通知類型: ${data['type']}');

    // 檢查是否為帳號刪除通知
    if (data['type'] == 'ACCOUNT_DELETED') {
      debugPrint('點擊帳號刪除通知，開始處理登出流程');
      _handleAccountDeleted(message);
      return;
    }

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

  /// 處理帳號被刪除的通知
  ///
  /// 當收到管理員刪除帳號的通知時：
  /// 1. 清除所有本地資料（Provider 狀態）
  /// 2. 登出 Firebase Auth
  /// 3. 顯示提示訊息
  /// 4. 自動返回登入畫面
  Future<void> _handleAccountDeleted(RemoteMessage message) async {
    debugPrint('========== 處理帳號刪除通知 ==========');
    debugPrint('Message: ${message.data}');
    debugPrint('Timestamp: ${message.data['timestamp']}');
    debugPrint('====================================');

    if (!mounted) return;

    try {
      // 步驟 1 & 2: 登出並清除資料
      final authProvider = context.read<AuthProvider>();
      final mapProvider = context.read<MapProvider>();
      final userProvider = context.read<UserProvider>();

      // 清除所有狀態
      await authProvider.signOut();
      mapProvider.reset();
      userProvider.reset();

      debugPrint('已清除所有本地資料並登出');

      // 步驟 3: 顯示提示訊息
      if (mounted) {
        // 關閉可能存在的通知彈窗
        _dismissNotificationOverlay();

        // 顯示帳號被刪除的提示
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('帳號已被刪除'),
            content: Text(
              message.notification?.body ?? '您的帳號已被管理員刪除，請重新登入或聯繫客服。',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('確定'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }

      // 步驟 4: 自動返回登入畫面
      // AuthenticationWrapper 會自動檢測到未登入狀態並顯示登入畫面
      debugPrint('帳號刪除處理完成，將自動返回登入畫面');
    } catch (e) {
      debugPrint('處理帳號刪除通知時發生錯誤: $e');

      // 即使發生錯誤，也要確保登出
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.signOut();
      } catch (signOutError) {
        debugPrint('登出失敗: $signOutError');
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
              // const Icon(
              //   Icons.map_rounded,
              //   size: 80,
              //   color: AppConstants.primaryColor,
              // ),
              const SizedBox(height: 16),
              const Text(
                'SafeNet Map',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
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
