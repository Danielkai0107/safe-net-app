import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  bool _isInitialized = false;
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _setInitialPosition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('MapTab: APP 生命週期變更 - $state');

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final mapProvider = context.read<MapProvider>();

    if (!authProvider.isAuthenticated || !userProvider.hasDevice) {
      return;
    }

    final userId = authProvider.user?.uid;
    if (userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // APP 恢復前景 - 開始即時監聽
        debugPrint('MapTab: APP 恢復前景，開始監聽活動記錄');
        mapProvider.startListeningToActivities(
          userId: userId,
          deviceId: userProvider.boundDevice?.id,
        );
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

  Future<void> _initializeData() async {
    debugPrint('MapTab: 開始初始化資料');

    // 載入接收點
    final mapProvider = context.read<MapProvider>();
    debugPrint('MapTab: 開始載入接收點');
    await mapProvider.loadGateways();
    debugPrint('MapTab: 接收點載入完成，共 ${mapProvider.gateways.length} 個');

    // 如果已登入，載入用戶資料和通知點位
    final authProvider = context.read<AuthProvider>();
    debugPrint('MapTab: 是否已登入 = ${authProvider.isAuthenticated}');

    if (authProvider.isAuthenticated) {
      final userId = authProvider.user?.uid;
      debugPrint('MapTab: userId = $userId');

      if (userId != null) {
        final userProvider = context.read<UserProvider>();
        await userProvider.loadUserProfile(userId);
        await mapProvider.loadNotificationPoints(userId);
        debugPrint(
          'MapTab: 通知點位載入完成，共 ${mapProvider.notificationPoints.length} 個',
        );

        // 如果已綁定設備，開始即時監聽活動記錄
        if (userProvider.hasDevice) {
          debugPrint('MapTab: 已綁定設備，開始即時監聽活動記錄');
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

    debugPrint('建立標記: 共 ${mapProvider.gateways.length} 個接收點');

    // 接收點標記
    for (final gateway in mapProvider.gateways) {
      final isNotified = mapProvider.isGatewayNotified(gateway.id);

      debugPrint(
        '新增標記: ${gateway.name} at (${gateway.latitude}, ${gateway.longitude})',
      );

      markers.add(
        Marker(
          markerId: MarkerId(gateway.id),
          position: LatLng(gateway.latitude, gateway.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNotified
                ? BitmapDescriptor
                      .hueOrange // 已設定通知的接收點
                : BitmapDescriptor.hueAzure, // 一般接收點
          ),
          infoWindow: InfoWindow(
            title: gateway.name,
            snippet: gateway.location,
          ),
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
                      CupertinoIcons.location_fill,
                      size: 24,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 重新載入按鈕
                GestureDetector(
                  onTap: () async {
                    await _initializeData();
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
                      CupertinoIcons.refresh,
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
