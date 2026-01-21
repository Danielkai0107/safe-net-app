import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/map_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/constants.dart';

/// 背景訊息處理器
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('處理背景訊息: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
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
      debugPrint('收到前景訊息: ${message.messageId}');
      
      if (message.notification != null) {
        _showForegroundNotification(message);
      }
    });

    // 處理通知點擊（app 在背景或關閉狀態）
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('用戶點擊通知: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // 檢查是否從通知啟動 app
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('從通知啟動 app: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(message.notification?.title ?? '通知'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          CupertinoDialogAction(
            child: const Text('關閉'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (message.data.isNotEmpty)
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('查看'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotificationTap(message);
              },
            ),
        ],
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    if (data['type'] == 'LOCATION_ALERT') {
      // 跳轉到地圖並定位到通知點位
      final latitude = double.tryParse(data['latitude'] ?? '');
      final longitude = double.tryParse(data['longitude'] ?? '');
      
      if (latitude != null && longitude != null) {
        final mapProvider = context.read<MapProvider>();
        mapProvider.updateCenter(
          LatLng(latitude, longitude),
          newZoom: 17.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 檢查登入狀態
        if (authProvider.user == null) {
          // 未登入，顯示登入頁面
          return const LoginScreen();
        } else {
          // 已登入，顯示主畫面
          return const HomeScreen();
        }
      },
    );
  }
}
