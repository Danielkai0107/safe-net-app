import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/map_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'avatar_picker_dialog.dart';

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
  final _deviceIdFocusNode = FocusNode();
  bool _showBindForm = false;
  bool _isLoading = false;
  String _selectedAvatar = '01.png'; // 預設頭像
  String? _selectedGender; // 選填：MALE, FEMALE, OTHER

  @override
  void dispose() {
    _deviceIdController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    _deviceIdFocusNode.dispose();
    super.dispose();
  }

  void _showFormAndFocus() {
    setState(() {
      _showBindForm = true;
    });
    // 延遲聚焦，等待表單渲染完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _deviceIdFocusNode.requestFocus();
      }
    });
  }

  Future<void> _handleBind() async {
    if (_isLoading) return; // 防止重複提交

    final deviceIdOrName = _deviceIdController.text.trim().toUpperCase();
    final nickname = _nicknameController.text.trim();
    final ageText = _ageController.text.trim();

    if (deviceIdOrName.isEmpty) {
      Helpers.showErrorDialog(context, '請輸入產品序號或設備 ID');
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

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 判斷輸入的是設備 ID（Firestore 文檔 ID，通常 20 字符以上）還是產品序號
    // 產品序號格式如：ABCDEF1234（英數字混合，通常較短）
    // Firestore 文檔 ID 通常是 20 字符的隨機字串
    final isDeviceId = deviceIdOrName.length >= 20;

    final success = await userProvider.bindDevice(
      userId: userId,
      deviceId: isDeviceId ? deviceIdOrName : null,
      deviceName: isDeviceId ? null : deviceIdOrName,
      nickname: nickname.isEmpty ? null : nickname,
      age: age,
      gender: _selectedGender,
      avatar: _selectedAvatar,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // 綁定成功後，開始即時監聽活動記錄
      final mapProvider = context.read<MapProvider>();
      mapProvider.startListeningToActivities(
        userId: userId,
        deviceId: userProvider.boundDevice?.id,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '設備綁定成功');
    } else {
      Helpers.showErrorDialog(context, userProvider.error ?? '設備綁定失敗');
    }
  }

  Future<void> _handleUnbind() async {
    if (_isLoading) return; // 防止重複提交

    final confirmed = await Helpers.showConfirmDialog(
      context,
      '解除綁定',
      '確定要解除設備綁定嗎？',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await userProvider.unbindDevice(userId: userId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // 解綁成功後，清空活動記錄
      final mapProvider = context.read<MapProvider>();
      mapProvider.clearActivities();

      Navigator.of(context).pop();
      Helpers.showSuccessDialog(context, '設備已解除綁定');
    } else {
      Helpers.showErrorDialog(context, userProvider.error ?? '解除綁定失敗');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final hasDevice = userProvider.hasDevice;
    final profile = userProvider.userProfile;

    // 獲取鍵盤高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: keyboardHeight > 0 ? keyboardHeight : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖動指示器
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 標題
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        hasDevice ? '設備資訊' : '綁定設備',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 已綁定設備資訊
                if (hasDevice && profile != null && profile.boundDevice != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.smartphone_rounded,
                              size: 18,
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '已綁定設備',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('設備名稱', profile.boundDevice!.deviceName),
                        const SizedBox(height: 8),
                        _buildInfoRow('設備 ID', profile.boundDevice!.id),
                        if (profile.boundDevice!.nickname != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow('暱稱', profile.boundDevice!.nickname!),
                        ],
                        if (profile.boundDevice!.age != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow('年齡', '${profile.boundDevice!.age} 歲'),
                        ],
                        if (profile.boundDevice!.gender != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            '性別',
                            _getGenderText(profile.boundDevice!.gender!),
                          ),
                        ],
                      ],
                    ),
                  ),

                // 綁定設備表單
                if (!hasDevice && _showBindForm)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '請填寫設備資訊',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 頭像選擇
                        GestureDetector(
                          onTap: () async {
                            final selectedAvatar = await showAvatarPicker(
                              context,
                              currentAvatar: _selectedAvatar,
                            );
                            if (selectedAvatar != null) {
                              setState(() {
                                _selectedAvatar = selectedAvatar;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                // 頭像預覽
                                Container(
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
                                      'assets/avatar/$_selectedAvatar',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.account_circle_rounded,
                                              size: 48,
                                              color: AppConstants.primaryColor,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 文字說明
                                const Expanded(
                                  child: Text(
                                    '點擊選擇頭像',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppConstants.textColor,
                                    ),
                                  ),
                                ),
                                // 箭頭
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: CupertinoColors.systemGrey2,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 性別選擇
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Text(
                                '性別（選填）',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.textColor.withOpacity(
                                    0.7,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: CupertinoSlidingSegmentedControl<String>(
                                groupValue: _selectedGender,
                                onValueChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                                children: const {
                                  'MALE': Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('男性'),
                                  ),
                                  'FEMALE': Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('女性'),
                                  ),
                                  'OTHER': Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('其他'),
                                  ),
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _deviceIdController,
                          focusNode: _deviceIdFocusNode,
                          placeholder: '產品序號（例如：1-1001）*',
                          padding: const EdgeInsets.all(14),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _nicknameController,
                          placeholder: '暱稱（選填）',
                          padding: const EdgeInsets.all(14),
                          textInputAction: TextInputAction.next,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _ageController,
                          placeholder: '年齡（選填）',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(14),
                          textInputAction: TextInputAction.done,
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 提示訊息（未綁定且未顯示表單時）
                if (!hasDevice && !_showBindForm)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.smartphone_rounded,
                          size: 48,
                          color: AppConstants.textColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '尚未綁定設備',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '綁定設備後可追蹤活動記錄',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConstants.textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // 操作按鈕
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (!hasDevice && !_showBindForm)
                        _buildActionButton(
                          label: '開始綁定設備',
                          icon: Icons.smartphone_rounded,
                          color: AppConstants.primaryColor,
                          onPressed: _showFormAndFocus,
                          showLoading: false,
                        ),

                      if (!hasDevice && _showBindForm) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: '取消',
                                icon: Icons.close_rounded,
                                color: CupertinoColors.systemGrey,
                                onPressed: () {
                                  if (!_isLoading) {
                                    setState(() {
                                      _showBindForm = false;
                                      _deviceIdController.clear();
                                      _nicknameController.clear();
                                      _ageController.clear();
                                      _selectedGender = null;
                                    });
                                  }
                                },
                                showLoading: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                label: '確認綁定',
                                icon: Icons.check_rounded,
                                color: AppConstants.primaryColor,
                                onPressed: _handleBind,
                                showLoading: _isLoading,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (hasDevice)
                        _buildActionButton(
                          label: '解除設備綁定',
                          icon: Icons.cancel_rounded,
                          color: CupertinoColors.systemRed,
                          onPressed: _handleUnbind,
                          showLoading: _isLoading,
                        ),

                      const SizedBox(height: 12),

                      _buildActionButton(
                        label: '關閉',
                        icon: Icons.cancel_rounded,
                        color: CupertinoColors.systemGrey2,
                        onPressed: () => Navigator.of(context).pop(),
                        outlined: true,
                        showLoading: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textColor.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
    bool showLoading = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: showLoading ? null : onPressed,
      child: Opacity(
        opacity: showLoading ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: outlined ? CupertinoColors.white : color,
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: showLoading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: outlined ? color : CupertinoColors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: outlined ? color : CupertinoColors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: outlined ? color : CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
