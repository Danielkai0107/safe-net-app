import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'register_screen.dart';

/// 登入頁面（從下而上彈窗）
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// 顯示登入彈窗
  static Future<bool?> show(BuildContext context) {
    return showCupertinoModalPopup<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LoginScreen(),
    );
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 收起鍵盤
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Helpers.showErrorDialog(context, '請輸入 Email 和密碼');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(email: email, password: password);

    if (!mounted) return;

    if (success) {
      // 登入成功，返回 true
      Navigator.of(context).pop(true);
    } else {
      Helpers.showErrorDialog(context, authProvider.error ?? '登入失敗');
    }
  }

  void _navigateToRegister() {
    // 先關閉登入彈窗，再打開註冊頁面
    Navigator.of(context).pop();
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute(builder: (context) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Stack(
          children: [
            Container(
              // 根據鍵盤調整高度
              height: MediaQuery.of(context).size.height * 0.7 + bottomPadding,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
        children: [
          // 頂部拖曳指示器
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 關閉按鈕
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: CupertinoColors.systemGrey3,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // 內容區域
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppConstants.paddingLarge,
                right: AppConstants.paddingLarge,
                bottom: AppConstants.paddingLarge + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 標題
                  const Text(
                    '歡迎回來',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeXXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.paddingSmall),

                  Text(
                    '登入以繼續使用',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeMedium,
                      color: AppConstants.textColor.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Email 輸入框
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
                    child: CupertinoTextField(
                      controller: _emailController,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: const BoxDecoration(),
                      prefix: const Padding(
                        padding: EdgeInsets.only(
                          left: AppConstants.paddingMedium,
                        ),
                        child: Icon(
                          Icons.email_rounded,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // 密碼輸入框
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
                    child: CupertinoTextField(
                      controller: _passwordController,
                      placeholder: '密碼',
                      obscureText: _obscurePassword,
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: const BoxDecoration(),
                      prefix: const Padding(
                        padding: EdgeInsets.only(
                          left: AppConstants.paddingMedium,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      suffix: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: AppConstants.textColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // 登入按鈕
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
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      child: const Text(
                        '登入',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // 註冊連結
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '還沒有帳號？',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeMedium,
                          color: AppConstants.textColor.withOpacity(0.6),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingSmall,
                        ),
                        onPressed: _navigateToRegister,
                        child: const Text(
                          '立即註冊',
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
            ),
            // 全螢幕 Loading 遮罩
            if (authProvider.isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(
                          radius: 16,
                          color: CupertinoColors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '登入中...',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
