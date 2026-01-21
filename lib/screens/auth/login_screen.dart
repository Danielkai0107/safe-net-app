import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'register_screen.dart';

/// 登入頁面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Helpers.showErrorDialog(context, '請輸入 Email 和密碼');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      // 登入成功，導航由 main.dart 的 Consumer 處理
    } else {
      Helpers.showErrorDialog(
        context,
        authProvider.error ?? '登入失敗',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo / Icon
              Icon(
                CupertinoIcons.map_fill,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              
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
              
              const SizedBox(height: 40),
              
              // Email 輸入框
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
                child: CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: const BoxDecoration(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: AppConstants.paddingMedium),
                    child: Icon(
                      CupertinoIcons.mail,
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
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
                    padding: EdgeInsets.only(left: AppConstants.paddingMedium),
                    child: Icon(
                      CupertinoIcons.lock,
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
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: AppConstants.textColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // 登入按鈕
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMedium,
                    ),
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            '登入',
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                  );
                },
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
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
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
    );
  }
}
