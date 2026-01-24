import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/dialogs/avatar_picker_dialog.dart';
import '../auth/login_screen.dart';
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
  bool _wasAuthenticated = false; // 追蹤上一次的登入狀態

  @override
  void initState() {
    super.initState();
    // 延遲載入，確保 Provider 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  /// 檢查登入狀態變化並重新載入資料
  void _checkAuthStateAndReload(bool isAuthenticated) {
    if (isAuthenticated && !_wasAuthenticated) {
      debugPrint('ProfileTab: 偵測到登入狀態變化，重新載入用戶資料');
      _loadUserProfile();
    }
    _wasAuthenticated = isAuthenticated;
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

        // 如果用戶資料已經存在（例如註冊時已載入），不需要重新載入
        if (userProvider.userProfile != null) {
          debugPrint('ProfileTab: 用戶資料已存在，無需重新載入');

          // 只載入通知點位
          final mapProvider = context.read<MapProvider>();
          await mapProvider.loadNotificationPoints(userId);
          return;
        }

        // 載入用戶資料，返回 false 表示正在載入中（由其他地方觸發）
        final didLoad = await userProvider.loadUserProfile(userId);

        // 同時載入通知點位
        final mapProvider = context.read<MapProvider>();
        await mapProvider.loadNotificationPoints(userId);

        // 只有在實際執行載入時才顯示錯誤訊息
        if (didLoad && userProvider.error != null) {
          debugPrint('ProfileTab: 載入錯誤 = ${userProvider.error}');
          if (mounted) {
            Helpers.showErrorDialog(context, '載入用戶資料失敗: ${userProvider.error}');
          }
        } else if (userProvider.userProfile != null) {
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
      Helpers.showErrorDialog(context, userProvider.error ?? '移除設備失敗');
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await Helpers.showConfirmDialog(context, '登出', '確定要登出嗎？');

    if (!confirmed || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final mapProvider = context.read<MapProvider>();
    final userProvider = context.read<UserProvider>();

    await authProvider.signOut();
    mapProvider.reset();
    userProvider.reset();
  }

  Future<void> _handleDeleteAccount() async {
    // 第一次確認
    final confirmed = await Helpers.showConfirmDialog(
      context,
      '註銷帳號',
      '此操作將永久刪除您的帳號及所有資料，包括綁定的設備、通知點位等。此操作無法復原，確定要繼續嗎？',
    );

    if (!confirmed || !mounted) return;

    // 第二次確認（加強警告）
    final finalConfirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('最後確認'),
        content: const Text('您即將永久刪除您的帳號，此操作無法復原。請確認您已了解後果。'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('確定刪除'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (finalConfirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final mapProvider = context.read<MapProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) {
      if (mounted) {
        Helpers.showErrorDialog(context, '無法取得用戶 ID');
      }
      return;
    }

    // 顯示載入中
    if (mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('正在註銷帳號...'),
            ],
          ),
        ),
      );
    }

    try {
      // 步驟 1: 刪除後端資料
      final backendSuccess = await userProvider.deleteAccount(userId: userId);

      if (!backendSuccess) {
        if (mounted) {
          Navigator.of(context).pop(); // 關閉載入對話框
          Helpers.showErrorDialog(
            context,
            userProvider.error ?? '註銷帳號失敗，請稍後再試',
          );
        }
        return;
      }

      // 步驟 2: 刪除 Firebase Auth 帳號
      final authSuccess = await authProvider.deleteFirebaseAccount();

      if (mounted) {
        Navigator.of(context).pop(); // 關閉載入對話框
      }

      if (authSuccess) {
        // 清空所有狀態
        mapProvider.reset();
        userProvider.reset();

        if (mounted) {
          // 顯示成功訊息
          await showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('帳號已註銷'),
              content: const Text('您的帳號及所有資料已永久刪除'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('確定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          Helpers.showErrorDialog(
            context,
            authProvider.error ?? '刪除 Firebase 帳號失敗',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 關閉載入對話框
        Helpers.showErrorDialog(context, '註銷過程發生錯誤: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('個人資料', style: TextStyle(fontSize: 20)),
        border: null,
        backgroundColor: AppConstants.backgroundColor,
        padding: const EdgeInsetsDirectional.only(
          start: 16,
          end: 16,
          top: 8,
          bottom: 8,
        ),
      ),
      child: SafeArea(
        child: Consumer2<UserProvider, AuthProvider>(
          builder: (context, userProvider, authProvider, child) {
            final userProfile = userProvider.userProfile;
            final isLoading = userProvider.isLoading;
            final isAuthenticated = authProvider.isAuthenticated;

            // 檢查登入狀態變化並重新載入資料（使用 addPostFrameCallback 避免在 build 中觸發）
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAuthStateAndReload(isAuthenticated);
            });

            // 未登入時顯示引導登入畫面
            if (!isAuthenticated) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '登入以查看個人資料',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        '登入後可以綁定設備、設定通知點位',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeMedium,
                          color: AppConstants.textColor.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.paddingMedium,
                          ),
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          onPressed: () async {
                            final success = await LoginScreen.show(context);
                            if (success == true && mounted) {
                              // 登入成功，立即載入用戶資料
                              await _loadUserProfile();
                            }
                          },
                          child: const Text(
                            '登入 / 註冊',
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

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
                      Icons.warning_rounded,
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
                    child: Column(
                      children: [
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
                                Icons.phone_rounded,
                                size: 16,
                                color: AppConstants.textColor.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                userProfile.phone!,
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeMedium,
                                  color: AppConstants.textColor.withOpacity(
                                    0.6,
                                  ),
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
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
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
                              // 頭像（可點擊更換）
                              GestureDetector(
                                onTap: () async {
                                  final currentAvatar =
                                      userProfile.avatar ?? '01.png';
                                  final selectedAvatar = await showAvatarPicker(
                                    context,
                                    currentAvatar: currentAvatar,
                                  );

                                  if (selectedAvatar != null &&
                                      selectedAvatar != currentAvatar &&
                                      mounted) {
                                    final authProvider = context
                                        .read<AuthProvider>();
                                    final userProvider = context
                                        .read<UserProvider>();
                                    final userId = authProvider.user?.uid;

                                    if (userId != null) {
                                      final success = await userProvider
                                          .updateAvatar(
                                            userId: userId,
                                            avatar: selectedAvatar,
                                          );

                                      if (mounted) {
                                        if (success) {
                                          Helpers.showSuccessDialog(
                                            context,
                                            '頭像已更新',
                                          );
                                        } else {
                                          Helpers.showErrorDialog(
                                            context,
                                            userProvider.error ?? '更新頭像失敗',
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: AppConstants.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(23),
                                    child: Image.asset(
                                      'assets/avatar/${userProfile.avatar ?? "01.png"}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: AppConstants.primaryColor
                                                  .withOpacity(0.2),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color:
                                                    AppConstants.primaryColor,
                                                size: 28,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
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
                                onPressed: _isUnbindingDevice
                                    ? null
                                    : _handleUnbindDevice,
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
                          if (userProfile.boundDevice!.gender != null)
                            _buildInfoRow(
                              '性別',
                              _getGenderText(userProfile.boundDevice!.gender!),
                            ),
                          _buildInfoRow(
                            '設備名稱',
                            userProfile.boundDevice!.deviceName,
                          ),
                          if (userProfile.boundDevice!.boundAt != null)
                            _buildInfoRow(
                              '綁定時間',
                              Helpers.formatDateTime(
                                userProfile.boundDevice!.boundAt!,
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 過去守護區塊
                  Container(
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
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
                              Icons.access_time_rounded,
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
                            Icons.chevron_right_rounded,
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
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
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
                            builder: (context) =>
                                const NotificationPointsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppConstants.secondaryColor.withOpacity(
                                0.2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
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
                                    color: AppConstants.textColor.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
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
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    onPressed: _handleSignOut,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
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

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 註銷帳號按鈕
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMedium,
                    ),
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    onPressed: _handleDeleteAccount,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_forever_rounded,
                          color: CupertinoColors.destructiveRed,
                        ),
                        SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          '註銷帳號',
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.destructiveRed,
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

  String _getGenderText(String gender) {
    switch (gender) {
      case 'MALE':
        return '男性';
      case 'FEMALE':
        return '女性';
      case 'OTHER':
        return '其他';
      default:
        return gender;
    }
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
