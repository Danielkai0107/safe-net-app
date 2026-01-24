import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../constants/error_codes.dart';

/// 認證狀態枚舉
enum AuthState {
  /// 初始狀態
  initial,

  /// 認證中（登入/註冊進行中）
  authenticating,

  /// 已認證
  authenticated,

  /// 未認證
  unauthenticated,

  /// 錯誤狀態
  error,
}

/// 認證狀態管理
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _user;
  AuthState _authState = AuthState.initial;
  String? _error;
  String? _errorCode;

  User? get user => _user;
  AuthState get authState => _authState;
  bool get isLoading => _authState == AuthState.authenticating;
  String? get error => _error;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _user != null && _authState == AuthState.authenticated;

  AuthProvider() {
    // 監聽 Firebase Auth 狀態變化
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      // 根據 Firebase Auth 狀態自動更新認證狀態
      if (user == null && _authState != AuthState.authenticating) {
        _authState = AuthState.unauthenticated;
      }
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
    _authState = AuthState.authenticating;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: 開始註冊');

      // Step 1: Firebase Auth 註冊
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('Firebase 註冊失敗');
      }

      debugPrint('AuthProvider: Firebase Auth 註冊成功');

      // Step 2: 註冊到後端系統
      final result = await _apiService.mapUserAuth(
        action: 'register',
        email: email,
        name: name,
        phone: phone,
      );

      debugPrint('AuthProvider: 後端註冊回應 - $result');

      if (result['success'] != true) {
        // 後端註冊失敗，刪除 Firebase Auth 用戶（補償機制）
        debugPrint('AuthProvider: 後端註冊失敗，刪除 Firebase Auth 帳號');
        await userCredential.user?.delete();

        _errorCode = result['errorCode'];
        throw Exception(result['error'] ?? '後端註冊失敗');
      }

      _user = userCredential.user;
      _authState = AuthState.authenticated;
      debugPrint('AuthProvider: 註冊完成 userId=${_user?.uid}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _authState = AuthState.error;
      debugPrint('AuthProvider: 註冊失敗 - $_error');
      notifyListeners();
      return false;
    }
  }

  /// 登入
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _authState = AuthState.authenticating;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: 開始登入');

      // Step 1: Firebase Auth 登入
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null) {
        throw Exception('Firebase 登入失敗');
      }

      debugPrint('AuthProvider: Firebase Auth 登入成功');

      // Step 2: 驗證後端用戶資料
      final result = await _apiService.mapUserAuth(
        action: 'login',
        email: email,
      );

      debugPrint('AuthProvider: 後端登入回應 - $result');

      if (result['success'] != true) {
        _errorCode = result['errorCode'];

        // 根據錯誤碼提供明確的錯誤訊息
        if (_errorCode == ApiErrorCodes.userNotFound) {
          // 用戶不存在：Firebase 有帳號但後端沒有
          // 不再自動修復，而是提示用戶聯繫客服
          await _authService.signOut();
          _authState = AuthState.unauthenticated;
          _error =
              'Firebase 認證成功，但系統中找不到您的帳號資料。這可能是資料同步問題，請聯繫客服協助處理。';
          debugPrint('AuthProvider: 後端無用戶資料，已登出 Firebase Auth');
          notifyListeners();
          return false;
        } else {
          // 其他錯誤
          await _authService.signOut();
          throw Exception(result['error'] ?? '後端登入失敗');
        }
      }

      _user = userCredential.user;
      _authState = AuthState.authenticated;
      debugPrint('AuthProvider: 登入完成 userId=${_user?.uid}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _authState = AuthState.error;
      debugPrint('AuthProvider: 登入失敗 - $_error');
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _authState = AuthState.unauthenticated;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  /// 刪除 Firebase Auth 帳號
  Future<bool> deleteFirebaseAccount() async {
    _authState = AuthState.authenticating;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: 開始刪除 Firebase Auth 帳號');

      if (_user != null) {
        await _user!.delete();
        debugPrint('AuthProvider: Firebase Auth 帳號已刪除');
        _user = null;
      }

      _authState = AuthState.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _authState = AuthState.error;
      debugPrint('AuthProvider: 刪除 Firebase Auth 帳號失敗 - $_error');
      notifyListeners();
      return false;
    }
  }

  /// 取得 ID Token
  Future<String?> getIdToken() async {
    return await _user?.getIdToken();
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}
