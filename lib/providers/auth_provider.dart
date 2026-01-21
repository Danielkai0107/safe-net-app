import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// 認證狀態管理
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // 監聽 Firebase Auth 狀態變化
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// 註冊
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: 開始註冊');
      
      // Step 1: Firebase Auth 註冊
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('註冊失敗');
      }

      debugPrint('AuthProvider: Firebase Auth 註冊成功');

      // Step 2: 註冊到地圖 APP 系統
      final result = await _apiService.mapUserAuth(
        action: 'register',
        email: email,
        name: name,
        phone: phone,
      );

      debugPrint('AuthProvider: 後端註冊回應 - $result');

      if (result['success'] != true) {
        // 後端註冊失敗，刪除 Firebase Auth 用戶
        await userCredential.user?.delete();
        throw Exception(result['error'] ?? '註冊失敗');
      }

      _user = userCredential.user;
      debugPrint('AuthProvider: 註冊完成 userId=${_user?.uid}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('AuthProvider: 註冊失敗 - $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登入
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: 開始登入');
      
      // Step 1: Firebase Auth 登入
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('登入失敗');
      }

      debugPrint('AuthProvider: Firebase Auth 登入成功');

      // Step 2: 同步到地圖 APP 系統
      final result = await _apiService.mapUserAuth(
        action: 'login',
        email: email,
      );

      debugPrint('AuthProvider: 後端登入回應 - $result');

      if (result['success'] != true) {
        // 後端沒有用戶資料，登出 Firebase Auth
        await _authService.signOut();
        throw Exception(result['error'] ?? '後端無用戶資料,請重新註冊');
      }

      _user = userCredential.user;
      debugPrint('AuthProvider: 登入完成 userId=${_user?.uid}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('AuthProvider: 登入失敗 - $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// 取得 ID Token
  Future<String?> getIdToken() async {
    return await _user?.getIdToken();
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
