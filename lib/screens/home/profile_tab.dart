import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'notification_points_screen.dart';
import 'history_timeline_screen.dart';

/// 個人資料頁面
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUnbindingDevice = false;

  @override
  void initState() {
    super.initState();
    // 延遲載入，確保 Provider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    final authProvider = context.read<AuthProvider>();
    debugPrint('ProfileTab: 開始載入用戶資料');
    debugPrint('ProfileTab: 是否已登入 = ${authProvider.isAuthenticated}');
    
    if (authProvider.isAuthenticated) {
      final userId = authProvider.user?.uid;
      debugPrint('ProfileTab: userId = $userId');
      
      if (userId != null) {
        final userProvider = context.read<UserProvider>();
        await userProvider.loadUserProfile(userId);
        
        if (userProvider.error != null) {
          debugPrint('ProfileTab: 載入錯誤 = ${userProvider.error}');
          if (mounted) {
            Helpers.showErrorDialog(
              context,
              '載入用戶資料失敗: ${userProvider.error}',
            );
          }
        } else {
          debugPrint('ProfileTab: 載入成功');
        }
      }
    }
  }

  Future<void> _handleUnbindDevice() async {
    if (_isUnbindingDevice) return; // 防止重複提交
    
    final confirmed = await Helpers.showConfirmDialog(
      context,
      '移除設備',
      '確定要解除設備綁定嗎？',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isUnbindingDevice = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final mapProvider = context.read<MapProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _isUnbindingDevice = false;
      });
      return;
    }

    final success = await userProvider.unbindDevice(userId: userId);

    if (!mounted) return;

    setState(() {
      _isUnbindingDevice = false;
    });

    if (success) {
      // 清空活動記錄
      mapProvider.clearActivities();
      Helpers.showSuccessDialog(context, '設備已移除');
    } else {
      Helpers.showErrorDialog(
        context,
        userProvider.error ?? '移除設備失敗',
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      '登出',
      '確定要登出嗎？',
    );

    if (!confirmed || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userProvider = context.read<UserProvider>();

    await authProvider.signOut();
    mapProvider.reset();
    userProvider.reset();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('個人資料'),
        border: null,
        backgroundColor: AppConstants.backgroundColor,
      ),
      child: SafeArea(
        child: Consumer2<UserProvider, AuthProvider>(
          builder: (context, userProvider, authProvider, child) {
            final userProfile = userProvider.userProfile;
            final isLoading = userProvider.isLoading;

            if (isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(radius: 20),
              );
            }

            if (userProfile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 64,
                      color: AppConstants.secondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    const Text(
                      '無法載入用戶資料',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    if (userProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                        ),
                        child: Text(
                          userProvider.error!,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeSmall,
                            color: AppConstants.textColor.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    CupertinoButton.filled(
                      onPressed: _loadUserProfile,
                      child: const Text('重新載入'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  // 用戶資訊卡片
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 頭像
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            size: 40,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        // 姓名
                        Text(
                          userProfile.name,
                          style: const TextStyle(
                            fontSize: AppConstants.fontSizeXLarge,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textColor,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        // Email
                        Text(
                          userProfile.email,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMedium,
                            color: AppConstants.textColor.withOpacity(0.6),
                          ),
                        ),
                        // 電話（如果有）
                        if (userProfile.phone != null) ...[
                          const SizedBox(height: AppConstants.paddingSmall),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.phone,
                                size: 16,
                                color: AppConstants.textColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                userProfile.phone!,
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeMedium,
                                  color: AppConstants.textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 已綁定設備卡片
                  if (userProfile.hasDevice)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  CupertinoIcons.device_phone_portrait,
                                  color: AppConstants.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppConstants.paddingMedium),
                              const Expanded(
                                child: Text(
                                  '已綁定設備',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textColor,
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _isUnbindingDevice ? null : _handleUnbindDevice,
                                child: _isUnbindingDevice
                                    ? const CupertinoActivityIndicator(
                                        color: AppConstants.secondaryColor,
                                      )
                                    : const Text(
                                        '移除',
                                        style: TextStyle(
                                          color: AppConstants.secondaryColor,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          _buildInfoRow(
                            '暱稱',
                            userProfile.boundDevice!.displayName,
                          ),
                          if (userProfile.boundDevice!.age != null)
                            _buildInfoRow(
                              '年齡',
                              '${userProfile.boundDevice!.age} 歲',
                            ),
                          _buildInfoRow(
                            '設備名稱',
                            userProfile.boundDevice!.deviceName,
                          ),
                          if (userProfile.boundDevice!.boundAt != null)
                            _buildInfoRow(
                              '綁定時間',
                              Helpers.formatDateTime(userProfile.boundDevice!.boundAt!),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 過去守護區塊
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const HistoryTimelineScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              CupertinoIcons.time,
                              color: AppConstants.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '過去守護',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textColor,
                                  ),
                                ),
                                Text(
                                  '查看歷史活動記錄',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeSmall,
                                    color: AppConstants.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_forward,
                            color: AppConstants.textColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 通知點設定區塊
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const NotificationPointsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppConstants.secondaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              CupertinoIcons.bell_fill,
                              color: AppConstants.secondaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '通知點位',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textColor,
                                  ),
                                ),
                                Text(
                                  '已設定 ${userProfile.notificationPointCount} 個通知點位',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeSmall,
                                    color: AppConstants.textColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_forward,
                            color: AppConstants.textColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // 登出按鈕
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMedium,
                    ),
                    color: AppConstants.secondaryColor,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    onPressed: _handleSignOut,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.square_arrow_right,
                          color: CupertinoColors.white,
                        ),
                        SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          '登出',
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textColor.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
