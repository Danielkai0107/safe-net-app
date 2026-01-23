import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /// 取得守望點類型的顏色
  Color _getGatewayTypeColor(String type) {
    switch (type) {
      case GatewayType.schoolZone:
        return AppConstants.schoolZoneColor;
      case GatewayType.safeZone:
        return AppConstants.primaryColor; // 使用 App 主色綠
      case GatewayType.observeZone:
        return AppConstants.observeZoneColor;
      case GatewayType.inactive:
        return AppConstants.inactiveZoneColor;
      default:
        return AppConstants.primaryColor;
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
      ..color = Colors.black.withOpacity(0.5)
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadMarkerIcons();
    _initializeData();
    _setInitialPosition();
  }

  /// 重新整理地圖資料（供外部呼叫）
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    debugPrint('MapTab: 重新整理地圖資料');

    await _initializeData(forceReload: true);

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

  /// 移動到用戶當前位置
  Future<void> _moveToMyLocation() async {
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
      final mapProvider = context.read<MapProvider>();
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final mapProvider = context.read<MapProvider>();
    mapProvider.setMapController(controller);

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

    debugPrint('標記建立完成: ${markers.length} 個');
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Google Map
          Consumer2<MapProvider, AuthProvider>(
            builder: (context, mapProvider, authProvider, child) {
              if (!_isInitialized) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20),
                );
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(24),
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
                      size: 24,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(24),
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
                      size: 24,
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
