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
      // Step 1: Firebase Auth 註冊
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('註冊失敗');
      }

      // Step 2: 註冊到地圖 APP 系統
      final result = await _apiService.mapUserAuth(
        action: 'register',
        email: email,
        name: name,
        phone: phone,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? '註冊失敗');
      }

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      // Step 1: Firebase Auth 登入
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('登入失敗');
      }

      // Step 2: 同步到地圖 APP 系統
      final result = await _apiService.mapUserAuth(
        action: 'login',
        email: email,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? '登入失敗');
      }

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
