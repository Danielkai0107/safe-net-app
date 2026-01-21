import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// 註冊頁面
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // 驗證
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Helpers.showErrorDialog(context, '請填寫所有必填欄位');
      return;
    }

    if (password != confirmPassword) {
      Helpers.showErrorDialog(context, '密碼不一致');
      return;
    }

    if (password.length < 6) {
      Helpers.showErrorDialog(context, '密碼長度至少 6 個字元');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: email,
      password: password,
      name: name,
      phone: phone.isEmpty ? null : phone,
    );

    if (!mounted) return;

    if (success) {
      // 註冊成功，導航由 main.dart 的 Consumer 處理
      Navigator.of(context).pop(); // 返回登入頁面
    } else {
      Helpers.showErrorDialog(
        context,
        authProvider.error ?? '註冊失敗',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppConstants.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppConstants.backgroundColor,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('註冊'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // 標題
              const Text(
                '建立新帳號',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeXXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppConstants.paddingSmall),
              
              Text(
                '填寫以下資訊以建立帳號',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textColor.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // 姓名輸入框
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
                  controller: _nameController,
                  placeholder: '姓名 *',
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: const BoxDecoration(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: AppConstants.paddingMedium),
                    child: Icon(
                      CupertinoIcons.person,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
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
                  placeholder: 'Email *',
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
              
              // 電話輸入框
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
                  controller: _phoneController,
                  placeholder: '電話（選填）',
                  keyboardType: TextInputType.phone,
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: const BoxDecoration(),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: AppConstants.paddingMedium),
                    child: Icon(
                      CupertinoIcons.phone,
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
                  placeholder: '密碼 * (至少 6 個字元)',
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
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              // 確認密碼輸入框
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
                  controller: _confirmPasswordController,
                  placeholder: '確認密碼 *',
                  obscureText: _obscureConfirmPassword,
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
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    child: Icon(
                      _obscureConfirmPassword
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: AppConstants.textColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // 註冊按鈕
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMedium,
                    ),
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            '註冊',
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                  );
                },
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              Text(
                '* 必填欄位',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppConstants.textColor.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
