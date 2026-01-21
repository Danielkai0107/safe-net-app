# FCM 推播通知設定完成

## ✅ 已完成的修改

### 1. AndroidManifest.xml 更新
**路徑:** `android/app/src/main/AndroidManifest.xml`

**新增內容:**
- ✅ `POST_NOTIFICATIONS` 權限 (Android 13+ 必需)
- ✅ Firebase Cloud Messaging Service 宣告
- ✅ FCM 預設通知圖標配置
- ✅ FCM 預設通知顏色配置
- ✅ FCM 預設通知頻道 ID (`location_alerts`)

### 2. 顏色資源文件
**路徑:** `android/app/src/main/res/values/colors.xml`

**內容:**
- 定義通知顏色為綠色 (`#4CAF50`)

### 3. main.dart 改進
**路徑:** `lib/main.dart`

**改進內容:**
- ✅ 添加詳細的 FCM 訊息接收日誌
- ✅ 改進前景通知對話框，顯示更多資訊
- ✅ 添加通知點擊處理的 debug 日誌
- ✅ 改進地圖跳轉邏輯

---

## 🧪 測試指南

### **步驟 1: 重新建置 App**
由於修改了 Android 原生配置，需要重新建置：

```bash
flutter clean
flutter pub get
flutter run
```

### **步驟 2: 檢查通知權限**
1. App 啟動時會自動請求通知權限
2. 確認在系統設置中已授權通知權限
3. 查看日誌確認顯示：`"用戶已授權通知權限"`

### **步驟 3: 確認 FCM Token**
查看日誌應該會看到：
```
I/flutter: FCM Token: [你的 token]
```

### **步驟 4: 測試推播通知**

#### **背景/關閉狀態測試:**
1. 將 app 切到背景或完全關閉
2. 觸發活動記錄（設備經過通知點位）
3. 應該會收到系統原生通知
4. 點擊通知會打開 app 並跳轉到地圖位置

#### **前景狀態測試:**
1. 保持 app 在前景
2. 觸發活動記錄
3. 會顯示 CupertinoAlertDialog 對話框
4. 點擊「查看位置」會跳轉到地圖

### **步驟 5: 查看 Debug 日誌**

**收到推播時會顯示:**
```
I/flutter: ========== 收到前景 FCM 訊息 ==========
I/flutter: Message ID: xxx
I/flutter: Notification: {title: 位置通知, body: 已到達家門口}
I/flutter: Data: {type: LOCATION_ALERT, gatewayId: xxx, ...}
I/flutter: =====================================
```

**點擊通知時會顯示:**
```
I/flutter: ========== 用戶點擊通知 (背景) ==========
I/flutter: Message ID: xxx
I/flutter: Data: {...}
I/flutter: =====================================
I/flutter: 處理通知點擊
I/flutter: 通知類型: LOCATION_ALERT
I/flutter: 跳轉到地圖位置: (25.047908, 121.517315)
I/flutter: 地圖已更新至通知位置
```

---

## 📋 檢查清單

### **前端 (已完成)**
- ✅ AndroidManifest.xml 配置完整
- ✅ 通知權限已請求
- ✅ FCM Token 自動上傳到後端
- ✅ 前景/背景通知處理邏輯完整
- ✅ Debug 日誌完整

### **需要確認的後端事項**
- ⚠️ 確認後端有正確的 FCM Server Key
- ⚠️ 確認 `receiveBeaconData` 函數會在適當時機發送 FCM 推播
- ⚠️ 確認推播 payload 格式符合文檔規範

---

## 🔧 後端推播格式要求

根據 `MAP_APP_API_ENDPOINTS.md`，後端應發送以下格式的推播：

```json
{
  "notification": {
    "title": "位置通知",
    "body": "已到達家門口"
  },
  "data": {
    "type": "LOCATION_ALERT",
    "gatewayId": "gateway_001",
    "gatewayName": "台北車站東門",
    "notificationPointId": "point_xyz123",
    "latitude": "25.047908",
    "longitude": "121.517315"
  }
}
```

**重要:**
- `notification` 部分用於系統原生通知顯示
- `data` 部分用於 app 內處理和導航
- 兩者都要包含才能正常工作

---

## 🐛 疑難排解

### **問題 1: 沒收到通知**
**檢查:**
1. Firestore 中用戶的 `fcmToken` 是否存在且為最新
2. 後端日誌確認推播是否有發送
3. Android 系統設置中通知權限是否開啟
4. 查看 app 日誌是否有錯誤訊息

### **問題 2: 前景通知不顯示**
**檢查:**
1. 查看日誌是否有 "收到前景 FCM 訊息"
2. 確認 `message.notification` 不為 null
3. 檢查是否有 dialog 顯示錯誤

### **問題 3: 點擊通知無反應**
**檢查:**
1. 查看日誌確認 `_handleNotificationTap` 是否被調用
2. 確認 `data['type']` 是否為 `"LOCATION_ALERT"`
3. 確認經緯度資料是否有效

---

## 📝 下一步建議

1. **測試實際場景**: 使用真實設備經過通知點位測試
2. **檢查後端日誌**: 確認後端推播發送邏輯正確
3. **監控 Firestore**: 確認活動記錄正確寫入
4. **優化通知頻率**: 避免重複推播（後端可加入防抖邏輯）

---

**更新日期:** 2026-01-22  
**狀態:** ✅ 前端配置完成
