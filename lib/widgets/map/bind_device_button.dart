import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../utils/constants.dart';
import '../dialogs/bind_device_dialog.dart';

/// 綁定設備按鈕（地圖左上角）
class BindDeviceButton extends StatelessWidget {
  const BindDeviceButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final hasDevice = userProvider.hasDevice;

    return Positioned(
      top: 100, // 避開 SafeArea
      left: 16,
      child: GestureDetector(
        onTap: () {
          if (!isAuthenticated) {
            // 未登入，顯示提示並提供登入選項
            showCupertinoDialog(
              context: context,
              builder: (dialogContext) => CupertinoAlertDialog(
                title: const Text('請先登入'),
                content: const Text('綁定設備前需要先登入帳號'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('前往登入'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      LoginScreen.show(context);
                    },
                  ),
                ],
              ),
            );
          } else {
            // 已登入，顯示綁定對話框（使用 bottom sheet）
            showCupertinoModalPopup(
              context: context,
              builder: (context) => const BindDeviceDialog(),
            );
          }
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: hasDevice
                ? AppConstants.primaryColor
                : AppConstants.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            hasDevice ? Symbols.shield_person : Symbols.smartphone,
            fill: hasDevice ? 1 : 0,
            weight: hasDevice ? null : 600,
            size: 30,
            color: hasDevice
                ? CupertinoColors.white
                : AppConstants.primaryColor,
          ),
        ),
      ),
    );
  }
}
