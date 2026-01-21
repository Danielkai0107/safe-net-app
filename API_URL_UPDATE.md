# API URL 更新說明

## ✅ 已完成更新

所有 API URL 已從舊的 1st Gen Cloud Functions URL 更新為新的 2nd Gen Cloud Functions URL。

## 🔄 URL 變更對照

### 舊 URL 格式（1st Gen）
```
https://us-central1-safe-net-tw.cloudfunctions.net/[functionName]
```

### 新 URL 格式（2nd Gen）
```
https://[functionname]-kmzfyt3t5a-uc.a.run.app
```

## 📡 完整 API URL 列表

| API 名稱 | 完整 URL |
|---------|---------|
| mapUserAuth | `https://mapuserauth-kmzfyt3t5a-uc.a.run.app` |
| updateMapUserFcmToken | `https://updatemapuserfcmtoken-kmzfyt3t5a-uc.a.run.app` |
| bindDeviceToMapUser | `https://binddevicetomapuser-kmzfyt3t5a-uc.a.run.app` |
| unbindDeviceFromMapUser | `https://unbinddevicefrommapuser-kmzfyt3t5a-uc.a.run.app` |
| getPublicGateways | `https://getpublicgateways-kmzfyt3t5a-uc.a.run.app` |
| addMapUserNotificationPoint | `https://addmapusernotificationpoint-kmzfyt3t5a-uc.a.run.app` |
| getMapUserNotificationPoints | `https://getmapusernotificationpoints-kmzfyt3t5a-uc.a.run.app` |
| updateMapUserNotificationPoint | `https://updatemapusernotificationpoint-kmzfyt3t5a-uc.a.run.app` |
| removeMapUserNotificationPoint | `https://removemapusernotificationpoint-kmzfyt3t5a-uc.a.run.app` |
| getMapUserActivities | `https://getmapuseractivities-kmzfyt3t5a-uc.a.run.app` |
| getMapUserProfile | `https://getmapuserprofile-kmzfyt3t5a-uc.a.run.app` |

## 📝 更新的檔案

- ✅ `lib/services/api_service.dart` - 所有 API URL 已更新
- ✅ `MAP_APP_API_ENDPOINTS.md` - API 文檔已更新

## 🧪 測試

更新後請進行熱重啟測試：

```bash
# 在 Flutter 終端機按 R（大寫）進行完全重啟
R
```

然後測試：
1. ✅ 載入接收點（地圖標記）
2. ✅ 用戶資料載入（個人資料頁）
3. ✅ 綁定設備
4. ✅ 新增通知點位

## 🔍 Debug 日誌

現在應該能看到：
```
I/flutter: MapTab: 開始載入接收點
I/flutter: 開始載入接收點...
I/flutter: API 回應: {success: true, gateways: [...]}
I/flutter: 成功載入 X 個接收點
```

---

**更新日期**: 2026-01-21  
**狀態**: ✅ 所有 API URL 已更新為 2nd Gen Functions
