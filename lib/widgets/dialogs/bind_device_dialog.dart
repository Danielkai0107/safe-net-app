import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';

/// 綁定設備對話框
class BindDeviceDialog extends StatefulWidget {
  const BindDeviceDialog({super.key});

  @override
  State<BindDeviceDialog> createState() => _BindDeviceDialogState();
}

class _BindDeviceDialogState extends State<BindDeviceDialog> {
  final _deviceIdController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _deviceIdController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleBind() async {
    final deviceId = _deviceIdController.text.trim();
    final nickname = _nicknameController.text.trim();
    final ageText = _ageController.text.trim();

    if (deviceId.isEmpty) {
      Helpers.showErrorDialog(context, '請輸入設備 ID');
      return;
    }

    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age <= 0 || age > 150) {
        Helpers.showErrorDialog(context, '請輸入有效的年齡');
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final success = await userProvider.bindDevice(
      userId: userId,
      deviceId: deviceId,
      nickname: nickname.isEmpty ? null : nickname,
      age: age,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '設備綁定成功');
    } else {
      Helpers.showErrorDialog(
        context,
        userProvider.error ?? '設備綁定失敗',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('綁定設備'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
            CupertinoTextField(
              controller: _deviceIdController,
              placeholder: '設備 ID *',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _nicknameController,
              placeholder: '暱稱（選填）',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _ageController,
              placeholder: '年齡（選填）',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('綁定'),
          onPressed: _handleBind,
        ),
      ],
    );
  }
}
