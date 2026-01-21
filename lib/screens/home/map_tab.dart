import 'package:flutter/cupertino.dart';
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

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 載入接收點
    final mapProvider = context.read<MapProvider>();
    await mapProvider.loadGateways();

    // 如果已登入，載入用戶資料和通知點位
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      final userId = authProvider.user?.uid;
      if (userId != null) {
        final userProvider = context.read<UserProvider>();
        await userProvider.loadUserProfile(userId);
        await mapProvider.loadNotificationPoints(userId);
        
        // 如果已綁定設備，載入活動記錄
        if (userProvider.hasDevice) {
          await mapProvider.loadActivities(
            userId: userId,
            limit: 100,
          );
        }
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final mapProvider = context.read<MapProvider>();
    mapProvider.setMapController(controller);
    
    // 請求定位權限
    _requestLocationPermission();
  }

  Set<Marker> _buildMarkers(MapProvider mapProvider, AuthProvider authProvider) {
    final markers = <Marker>{};

    // 接收點標記
    for (final gateway in mapProvider.gateways) {
      final isNotified = mapProvider.isGatewayNotified(gateway.id);
      
      markers.add(
        Marker(
          markerId: MarkerId(gateway.id),
          position: LatLng(gateway.latitude, gateway.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isNotified
                ? BitmapDescriptor.hueOrange // 已設定通知的接收點
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
                  target: LatLng(
                    AppConstants.defaultLatitude,
                    AppConstants.defaultLongitude,
                  ),
                  zoom: AppConstants.defaultZoom,
                ),
                markers: _buildMarkers(mapProvider, authProvider),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                compassEnabled: true,
                buildingsEnabled: true,
              );
            },
          ),

          // 綁定設備按鈕
          const BindDeviceButton(),

          // 重新載入按鈕（右上角）
          Positioned(
            top: 100,
            right: 16,
            child: GestureDetector(
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
          ),

          // 時間軸底部彈窗
          const TimelineBottomSheet(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
