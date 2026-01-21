import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// API 使用範例
/// 
/// 這個檔案展示如何使用 AuthService 和 ApiService
class ApiUsageExample extends StatefulWidget {
  const ApiUsageExample({super.key});

  @override
  State<ApiUsageExample> createState() => _ApiUsageExampleState();
}

class _ApiUsageExampleState extends State<ApiUsageExample> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  String _status = '等待操作...';
  bool _isLoading = false;

  /// 範例 1: 註冊並登入到系統
  Future<void> _registerAndLogin() async {
    setState(() {
      _isLoading = true;
      _status = '正在註冊...';
    });

    try {
      // Step 1: 使用 Firebase Auth 註冊
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      if (userCredential == null) {
        throw Exception('註冊失敗');
      }

      setState(() => _status = '註冊成功，正在註冊到地圖系統...');

      // Step 2: 註冊到地圖 APP 系統
      final result = await _apiService.mapUserAuth(
        action: 'register',
        email: 'test@example.com',
        name: '測試用戶',
        phone: '0912345678',
      );

      setState(() {
        _status = '完成！用戶 ID: ${result['user']['id']}';
      });
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 範例 2: 取得公共接收點
  Future<void> _getGateways() async {
    setState(() {
      _isLoading = true;
      _status = '正在取得接收點...';
    });

    try {
      final result = await _apiService.getPublicGateways();
      
      if (result['success'] == true) {
        final gateways = result['gateways'] as List;
        setState(() {
          _status = '找到 ${gateways.length} 個接收點\n'
              '第一個: ${gateways.isNotEmpty ? gateways[0]['name'] : '無'}';
        });
      } else {
        throw Exception(result['error'] ?? '未知錯誤');
      }
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 範例 3: 綁定設備
  Future<void> _bindDevice() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _status = '請先登入');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '正在綁定設備...';
    });

    try {
      final result = await _apiService.bindDeviceToMapUser(
        userId: user.uid,
        deviceId: 'device_test_123', // 替換為實際的設備 ID
      );

      if (result['success'] == true) {
        setState(() {
          _status = '設備綁定成功！\n'
              '設備名稱: ${result['device']['deviceName']}';
        });
      } else {
        throw Exception(result['error'] ?? '未知錯誤');
      }
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 範例 4: 新增通知點位
  Future<void> _addNotificationPoint() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _status = '請先登入');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '正在新增通知點位...';
    });

    try {
      final result = await _apiService.addMapUserNotificationPoint(
        userId: user.uid,
        gatewayId: 'gateway_001', // 替換為實際的接收點 ID
        name: '我的家',
        notificationMessage: '已到達家門口',
      );

      if (result['success'] == true) {
        setState(() {
          _status = '通知點位新增成功！\n'
              '點位名稱: ${result['notificationPoint']['name']}';
        });
      } else {
        throw Exception(result['error'] ?? '未知錯誤');
      }
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 範例 5: 取得活動記錄
  Future<void> _getActivities() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _status = '請先登入');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '正在取得活動記錄...';
    });

    try {
      // 取得最近 24 小時的活動
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      final result = await _apiService.getMapUserActivities(
        userId: user.uid,
        startTime: oneDayAgo.millisecondsSinceEpoch,
        limit: 50,
      );

      if (result['success'] == true) {
        final activities = result['activities'] as List;
        setState(() {
          _status = '找到 ${activities.length} 筆活動記錄\n'
              '${activities.isNotEmpty ? '最新: ${activities[0]['gatewayName']}' : ''}';
        });
      } else {
        throw Exception(result['error'] ?? '未知錯誤');
      }
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 使用範例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 狀態顯示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '狀態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 當前用戶資訊
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '當前用戶',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<User?>(
                      stream: _authService.authStateChanges,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user == null) {
                          return const Text('未登入');
                        }
                        return Text('Email: ${user.email}\nUID: ${user.uid}');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 操作按鈕
            const Text(
              '測試操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: ListView(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _registerAndLogin,
                    child: const Text('1. 註冊並登入'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getGateways,
                    child: const Text('2. 取得公共接收點'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _bindDevice,
                    child: const Text('3. 綁定設備'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addNotificationPoint,
                    child: const Text('4. 新增通知點位'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getActivities,
                    child: const Text('5. 取得活動記錄'),
                  ),
                  const Divider(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await _authService.signOut();
                            setState(() => _status = '已登出');
                          },
                    child: const Text('登出'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
