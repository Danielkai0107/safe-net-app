import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/gateway.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/map/bind_device_button.dart';
import '../../widgets/map/timeline_bottom_sheet.dart';
import '../../widgets/dialogs/gateway_detail_dialog.dart';

/// 地圖頁面
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  /// 用於從外部呼叫重整方法的 GlobalKey
  static final GlobalKey<_MapTabState> globalKey = GlobalKey<_MapTabState>();

  /// 重新整理地圖資料
  static void refresh() {
    globalKey.currentState?._refreshData();
  }

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  bool _isInitialized = false;
  LatLng? _initialPosition;
  bool _isRefreshing = false;

  // 快取自訂標記圖標
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  
  // 快取最新位置標記圖標
  BitmapDescriptor? _latestActivityMarker;
  
  // 追蹤上次的頭像，用於檢測變化
  String? _lastAvatar;

  /// 取得守望點類型的顏色
  Color _getGatewayTypeColor(String type) {
    switch (type) {
      case GatewayType.schoolZone:
        return AppConstants.schoolZoneColor;
      case GatewayType.safeZone:
        return AppConstants.safeZoneColor; // #00CA80
      case GatewayType.observeZone:
        return AppConstants.observeZoneColor;
      case GatewayType.inactive:
        return AppConstants.inactiveZoneColor;
      default:
        return AppConstants.safeZoneColor;
    }
  }

  /// 取得守望點類型的圖標
  IconData _getGatewayTypeIcon(String type) {
    switch (type) {
      case GatewayType.schoolZone:
        return Icons.apartment_rounded;
      default:
        return Icons.wifi_tethering_rounded;
    }
  }

  /// 建立自訂標記圖標
  Future<BitmapDescriptor> _createCustomMarker(String type) async {
    // 先檢查快取
    if (_markerIconCache.containsKey(type)) {
      return _markerIconCache[type]!;
    }

    final color = _getGatewayTypeColor(type);
    final iconData = _getGatewayTypeIcon(type);

    // 目標顯示大小 40px，使用高解析度繪製以保持清晰
    const double displaySize = 40.0;
    const double iconSize = 120.0; // 圖標本體大小
    const double shadowBlur = 6.0; // 陰影模糊半徑
    const double shadowOffset = 3.0; // 陰影偏移
    const double padding = shadowBlur * 3; // 留出陰影空間
    const double canvasSize = iconSize + padding; // 畫布總大小
    const double borderWidth = 10.0; // 白色粗邊框

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    const center = Offset(canvasSize / 2, canvasSize / 2);
    const radius = (iconSize - borderWidth) / 2;

    // 繪製陰影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(center.dx, center.dy + shadowOffset), // 稍微偏下
      radius + borderWidth / 2,
      shadowPaint,
    );

    // 繪製填充顏色的圓形（帶白色粗邊框）
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = Colors
          .white // 白色邊框
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 繪製白色粗體圖標（水平垂直居中）
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 66, // 圖標大小
        fontFamily: iconData.fontFamily,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (canvasSize - textPainter.width) / 2, // 水平居中
        (canvasSize - textPainter.height) / 2, // 垂直居中
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // 使用 BitmapDescriptor.bytes 並指定顯示大小
    final bitmapDescriptor = BitmapDescriptor.bytes(
      bytes,
      width: displaySize,
      height: displaySize,
    );

    // 快取圖標
    _markerIconCache[type] = bitmapDescriptor;

    return bitmapDescriptor;
  }

  /// 預先載入所有類型的標記圖標
  Future<void> _preloadMarkerIcons() async {
    final types = [
      GatewayType.schoolZone,
      GatewayType.safeZone,
      GatewayType.observeZone,
      GatewayType.inactive,
    ];

    for (final type in types) {
      await _createCustomMarker(type);
    }
    debugPrint('MapTab: 標記圖標預載完成');
  }

  /// 建立最新活動記錄的標記（設備頭像 + 黃色邊框，較大尺寸）
  Future<BitmapDescriptor> _createLatestActivityMarker(String avatarPath) async {
    // 目標顯示大小 56px，比普通標記 40px 更大
    const double displaySize = 56.0;
    const double iconSize = 168.0; // 圖標本體大小（比例對應 displaySize）
    const double shadowBlur = 8.0;
    const double shadowOffset = 4.0;
    const double padding = shadowBlur * 3;
    const double canvasSize = iconSize + padding;
    const double borderWidth = 14.0; // 黃色粗邊框

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    const center = Offset(canvasSize / 2, canvasSize / 2);
    const radius = (iconSize - borderWidth) / 2;

    // 繪製陰影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(center.dx, center.dy + shadowOffset),
      radius + borderWidth / 2,
      shadowPaint,
    );

    // 繪製黃色邊框
    final borderPaint = Paint()
      ..color = const Color(0xFFFFBE0A) // 黃色
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, borderPaint);

    // 載入頭像圖片並繪製到圓形區域
    try {
      final ByteData data = await rootBundle.load(avatarPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: iconSize.toInt(),
        targetHeight: iconSize.toInt(),
      );
      final frame = await codec.getNextFrame();
      final avatarImage = frame.image;

      // 建立圓形裁切路徑
      final clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius - 2));
      canvas.save();
      canvas.clipPath(clipPath);

      // 繪製頭像圖片
      final srcRect = Rect.fromLTWH(
        0,
        0,
        avatarImage.width.toDouble(),
        avatarImage.height.toDouble(),
      );
      final dstRect = Rect.fromCircle(center: center, radius: radius - 2);
      canvas.drawImageRect(avatarImage, srcRect, dstRect, Paint());

      canvas.restore();
    } catch (e) {
      debugPrint('載入頭像失敗: $e，使用預設圖標');
      // 如果載入失敗，繪製預設的填充色
      final fillPaint = Paint()
        ..color = AppConstants.primaryColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(center, radius - 2, fillPaint);
      
      // 繪製預設圖標
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.text = TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontSize: 80,
          fontFamily: Icons.person.fontFamily,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (canvasSize - textPainter.width) / 2,
          (canvasSize - textPainter.height) / 2,
        ),
      );
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(
      bytes,
      width: displaySize,
      height: displaySize,
    );
  }

  /// 更新最新活動標記圖標
  Future<void> _updateLatestActivityMarker() async {
    final userProvider = context.read<UserProvider>();
    final userProfile = userProvider.userProfile;
    
    if (userProfile != null && userProfile.hasDevice) {
      // 優先使用 userProfile.avatar（用戶頭像），若無則使用預設
      final avatarPath = 'assets/avatar/${userProfile.avatar ?? "01.png"}';
      _latestActivityMarker = await _createLatestActivityMarker(avatarPath);
      debugPrint('MapTab: 最新活動標記圖標已更新');
      if (mounted) {
        setState(() {}); // 觸發重建以顯示標記
      }
    }
  }

  /// 確保活動記錄監聽已啟動
  void _ensureActivityListenerStarted() {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final mapProvider = context.read<MapProvider>();
    
    if (authProvider.isAuthenticated && userProvider.hasDevice) {
      final userId = authProvider.user?.uid;
      final deviceId = userProvider.boundDevice?.id;
      
      if (userId != null && deviceId != null) {
        debugPrint('MapTab: 確保活動記錄監聽已啟動 userId=$userId, deviceId=$deviceId');
        mapProvider.startListeningToActivities(
          userId: userId,
          deviceId: deviceId,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadMarkerIcons();
    _initializeData();
    _setInitialPosition();
    // 延遲載入最新活動標記並確保監聽已啟動（確保 context 可用）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureActivityListenerStarted();
      _updateLatestActivityMarker();
    });
  }

  /// 重新整理地圖資料（供外部呼叫）
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    debugPrint('MapTab: 重新整理地圖資料');

    await _initializeData(forceReload: true);
    _ensureActivityListenerStarted();
    await _updateLatestActivityMarker();

    _isRefreshing = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('MapTab: APP 生命週期變更 - $state');

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final mapProvider = context.read<MapProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        // APP 恢復前景 - 重新整理地圖資料
        debugPrint('MapTab: APP 恢復前景，重新整理地圖資料');
        _refreshData();

        // 如果已登入且已綁定設備，開始即時監聽
        if (authProvider.isAuthenticated && userProvider.hasDevice) {
          final userId = authProvider.user?.uid;
          if (userId != null) {
            mapProvider.startListeningToActivities(
              userId: userId,
              deviceId: userProvider.boundDevice?.id,
            );
          }
        }
        break;

      case AppLifecycleState.paused:
        // APP 進入背景 - 停止監聽（依賴 FCM 推播）
        debugPrint('MapTab: APP 進入背景，停止監聽活動記錄');
        mapProvider.stopListeningToActivities();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 不處理
        break;
    }
  }

  /// 設定初始位置為用戶當前位置
  Future<void> _setInitialPosition() async {
    try {
      // 檢查並請求定位權限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('定位權限被拒絕，使用預設位置');
        return;
      }

      // 取得當前位置
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });

      // 如果地圖已經創建，移動到當前位置
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _initialPosition!,
              zoom: AppConstants.defaultZoom,
              tilt: 0, // 鎖定平面視角
            ),
          ),
        );
      }

      debugPrint('已設定初始位置: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('無法取得當前位置，使用預設位置: $e');
    }
  }

  /// 初始化資料
  /// [forceReload] 為 true 時強制重新載入所有資料
  Future<void> _initializeData({bool forceReload = false}) async {
    debugPrint('MapTab: 開始初始化資料 (forceReload=$forceReload)');

    final mapProvider = context.read<MapProvider>();
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    // 只在資料不存在或強制重新載入時才載入接收點
    if (forceReload || !mapProvider.hasGatewaysLoaded) {
      debugPrint('MapTab: 載入接收點');
      await mapProvider.loadGateways();
      debugPrint('MapTab: 接收點載入完成，共 ${mapProvider.gateways.length} 個');
    } else {
      debugPrint('MapTab: 接收點已存在 (${mapProvider.gateways.length} 個)，跳過載入');
    }

    // 如果已登入
    debugPrint('MapTab: 是否已登入 = ${authProvider.isAuthenticated}');
    if (authProvider.isAuthenticated) {
      final userId = authProvider.user?.uid;
      debugPrint('MapTab: userId = $userId');

      if (userId != null) {
        // 只在需要時載入通知點位
        if (forceReload || !mapProvider.hasNotificationPointsLoaded) {
          debugPrint('MapTab: 載入通知點位');
          await mapProvider.loadNotificationPoints(userId);
          debugPrint(
            'MapTab: 通知點位載入完成，共 ${mapProvider.notificationPoints.length} 個',
          );
        } else {
          debugPrint(
            'MapTab: 通知點位已存在 (${mapProvider.notificationPoints.length} 個)，跳過載入',
          );
        }

        // 如果已綁定設備，確保監聽器已啟動
        if (userProvider.hasDevice) {
          debugPrint('MapTab: 已綁定設備，確保監聽活動記錄');
          mapProvider.startListeningToActivities(
            userId: userId,
            deviceId: userProvider.boundDevice?.id,
          );
        } else {
          debugPrint('MapTab: 未綁定設備');
        }
      }
    }

    setState(() {
      _isInitialized = true;
    });
    debugPrint('MapTab: 初始化完成');
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  /// 移動到最新記錄位置（沒有記錄時移動到用戶當前位置）
  Future<void> _moveToMyLocation() async {
    final mapProvider = context.read<MapProvider>();
    
    // 優先定位到最新的活動記錄
    if (mapProvider.activities.isNotEmpty) {
      final latestActivity = mapProvider.activities.first; // 已按時間降序排列
      if (latestActivity.latitude != 0 && latestActivity.longitude != 0) {
        debugPrint('定位到最新記錄: ${latestActivity.gatewayName}');
        mapProvider.updateCenter(
          LatLng(latestActivity.latitude, latestActivity.longitude),
          newZoom: 17.0,
        );
        return;
      }
    }
    
    // 沒有活動記錄時，定位到用戶當前位置
    try {
      // 檢查權限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('需要定位權限'),
                content: const Text('請在設定中開啟定位權限以使用此功能'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('確定'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      // 取得當前位置
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 移動地圖到當前位置
      mapProvider.updateCenter(
        LatLng(position.latitude, position.longitude),
        newZoom: 17.0,
      );
    } catch (e) {
      debugPrint('取得位置失敗: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('無法取得位置'),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('確定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final mapProvider = context.read<MapProvider>();
    mapProvider.setMapController(controller);

    // 設置地圖樣式 - 隱藏地標
    const String mapStyle = '''
    [
      {
        "featureType": "poi",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "poi.business",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';

    try {
      await controller.setMapStyle(mapStyle);
    } catch (e) {
      debugPrint('設置地圖樣式失敗: $e');
    }

    // 請求定位權限
    _requestLocationPermission();
  }

  Set<Marker> _buildMarkers(
    MapProvider mapProvider,
    AuthProvider authProvider,
  ) {
    final markers = <Marker>{};

    debugPrint('建立標記: 共 ${mapProvider.gateways.length} 個守望點');

    // 守望點標記
    for (final gateway in mapProvider.gateways) {
      // 從快取取得對應類型的圖標
      final icon =
          _markerIconCache[gateway.type] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

      debugPrint(
        '新增標記: ${gateway.name} (${gateway.type}) at (${gateway.latitude}, ${gateway.longitude})',
      );

      markers.add(
        Marker(
          markerId: MarkerId(gateway.id),
          position: LatLng(gateway.latitude, gateway.longitude),
          icon: icon,
          onTap: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => GatewayDetailDialog(gateway: gateway),
            );
          },
        ),
      );
    }

    // 最新活動記錄標記（設備頭像 + 黃色邊框）
    if (mapProvider.activities.isNotEmpty) {
      final latestActivity = mapProvider.activities.first;
      if (latestActivity.latitude != 0 && latestActivity.longitude != 0) {
        // 如果標記還沒建立，嘗試建立
        if (_latestActivityMarker == null) {
          debugPrint('MapTab: 活動記錄存在但標記尚未建立，嘗試建立...');
          _updateLatestActivityMarker();
        }
        
        if (_latestActivityMarker != null) {
          debugPrint('新增最新活動標記: ${latestActivity.gatewayName} at (${latestActivity.latitude}, ${latestActivity.longitude})');
          markers.add(
            Marker(
              markerId: const MarkerId('latest_activity'),
              position: LatLng(latestActivity.latitude, latestActivity.longitude),
              icon: _latestActivityMarker!,
              zIndex: 999, // 確保顯示在最上層
              anchor: const Offset(0.5, 1.5), // 顯示在守望點圖標上方
            ),
          );
        }
      }
    }

    debugPrint('標記建立完成: ${markers.length} 個');
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Google Map
          Consumer3<MapProvider, AuthProvider, UserProvider>(
            builder: (context, mapProvider, authProvider, userProvider, child) {
              if (!_isInitialized) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20),
                );
              }

              // 檢測頭像變化，如果變化則更新標記
              final currentAvatar = userProvider.userProfile?.avatar;
              if (currentAvatar != _lastAvatar && userProvider.hasDevice) {
                _lastAvatar = currentAvatar;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateLatestActivityMarker();
                });
              }

              // 當有設備但還沒啟動監聽時，確保監聽已啟動
              if (userProvider.hasDevice && mapProvider.activities.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _ensureActivityListenerStarted();
                });
              }

              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target:
                      _initialPosition ??
                      LatLng(
                        AppConstants.defaultLatitude,
                        AppConstants.defaultLongitude,
                      ),
                  zoom: AppConstants.defaultZoom,
                  tilt: 0, // 鎖定為平面視角
                ),
                markers: _buildMarkers(mapProvider, authProvider),
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // 關閉預設的定位按鈕，使用自訂按鈕
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: true,
                buildingsEnabled: false, // 關閉立體建築
                tiltGesturesEnabled: false, // 禁用傾斜手勢
                rotateGesturesEnabled: false, // 禁用旋轉手勢
              );
            },
          ),

          // 綁定設備按鈕
          const BindDeviceButton(),

          // 右側按鈕組
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                // 回到我的位置按鈕
                GestureDetector(
                  onTap: _moveToMyLocation,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 28,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 重新載入按鈕
                GestureDetector(
                  onTap: () async {
                    // 強制重新載入所有資料
                    await _initializeData(forceReload: true);
                    if (mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('更新完成'),
                          content: const Text('地圖資料已更新'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('確定'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 28,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 時間軸底部彈窗
          const TimelineBottomSheet(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }
}
