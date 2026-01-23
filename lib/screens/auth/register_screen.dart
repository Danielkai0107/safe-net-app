import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      // 註冊成功，導航由 main.dart 的 Consumer 自動處理
      // 先 pop 回到登入頁面，然後 AuthenticationWrapper 會自動導航到主畫面
      Navigator.of(context).pop();
      
      // 顯示成功訊息
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Helpers.showSuccessDialog(context, '註冊成功！歡迎使用');
        }
      });
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
      child: SafeArea(
        child: Column(
          children: [
            // 自定義 AppBar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppConstants.backgroundColor,
              child: Row(
                children: [
                  // 返回按鈕（靠左）
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                  // 標題（置中）
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -6),
                      child: const Text(
                        '註冊',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColor,
                        ),
                      ),
                    ),
                  ),
                  // 佔位（保持標題置中）
                  const SizedBox(width: 44),
                ],
              ),
            ),
            // 內容區域
            Expanded(
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
                      Icons.person_rounded,
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
                      Icons.email_rounded,
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
                      Icons.phone_rounded,
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
                      Icons.lock_rounded,
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
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
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
          ],
        ),
      ),
    );
  }
}
