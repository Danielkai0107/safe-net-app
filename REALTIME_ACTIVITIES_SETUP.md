# 即時活動記錄設定指南

## 概述

本應用已實現活動記錄的即時自動更新功能，採用混合方案：

### 方案架構

1. **APP 在前景時**：使用 Firestore 即時監聽
   - 自動接收新活動記錄
   - 無需手動刷新
   - 即時更新 UI

2. **APP 在背景時**：依賴 FCM 推播
   - 停止 Firestore 監聽（省電）
   - 透過 FCM 推播通知用戶
   - 用戶點擊通知後 APP 恢復並重新載入

3. **APP 恢復前景時**：重新啟動監聽
   - 自動連接 Firestore
   - 獲取最新資料

---

## Firebase 設定

### 1. Firestore 安全規則

在 Firebase Console > Firestore Database > Rules 中添加以下規則：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // mapUserActivities - 地圖用戶的活動記錄
    match /mapUserActivities/{activityId} {
      // 只允許讀取自己的活動記錄
      allow read: if request.auth != null 
                  && request.auth.uid == resource.data.mapAppUserId;
      
      // 只允許後端（Cloud Functions）寫入
      allow write: if false;
    }
    
    // 其他規則...
  }
}
```

### 2. Firestore 索引

需要為查詢創建複合索引：

**索引配置：**
- Collection: `mapUserActivities`
- Fields:
  - `mapAppUserId` (Ascending)
  - `timestamp` (Descending)
- Query scope: `Collection`

**創建方式：**

#### 方法 1：透過 Firebase Console
1. 前往 Firebase Console > Firestore Database > Indexes
2. 點擊「建立索引」
3. 添加以下欄位：
   - `mapAppUserId`: Ascending
   - `timestamp`: Descending
4. 點擊「建立」

#### 方法 2：透過 firestore.indexes.json
創建 `firestore.indexes.json` 檔案：

```json
{
  "indexes": [
    {
      "collectionGroup": "mapUserActivities",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "mapAppUserId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

然後執行：
```bash
firebase deploy --only firestore:indexes
```

---

## 使用說明

### 1. 安裝依賴

確保 `pubspec.yaml` 中已添加：

```yaml
dependencies:
  cloud_firestore: ^5.5.0
```

執行：
```bash
flutter pub get
```

### 2. 程式碼架構

#### MapProvider
- `startListeningToActivities()`: 開始監聽活動記錄
- `stopListeningToActivities()`: 停止監聽
- `clearActivities()`: 清除記錄並停止監聽

#### MapTab
- 使用 `WidgetsBindingObserver` 監聽 APP 生命週期
- `didChangeAppLifecycleState()`: 處理前景/背景切換
- 自動管理監聽的啟動和停止

### 3. 資料流程

```
1. 用戶綁定設備
   ↓
2. MapProvider 開始監聽 Firestore
   ↓
3. 設備經過接收點
   ↓
4. Cloud Function 寫入 mapUserActivities
   ↓
5. Firestore 推送更新到 APP
   ↓
6. MapProvider 接收並更新 activities
   ↓
7. TimelineBottomSheet 自動顯示新記錄
```

---

## 測試方式

### 1. 測試即時監聽

1. 綁定設備
2. 觀察 Debug Console：
   ```
   MapProvider: 開始監聽活動記錄 userId=xxx
   ```
3. 手動在 Firestore 新增一筆測試記錄
4. APP 應該立即顯示新記錄（無需刷新）

### 2. 測試生命週期

1. APP 在前景時，綁定設備
2. 按 Home 鍵讓 APP 進入背景
3. 觀察 Debug Console：
   ```
   MapTab: APP 進入背景，停止監聽活動記錄
   MapProvider: 停止監聽活動記錄
   ```
4. 重新打開 APP
5. 觀察 Debug Console：
   ```
   MapTab: APP 恢復前景，開始監聽活動記錄
   MapProvider: 開始監聽活動記錄 userId=xxx
   ```

### 3. 測試資料同步

1. 使用兩個設備登入同一帳號
2. 在設備 A 新增活動記錄（透過 Cloud Function）
3. 設備 B 應該立即看到新記錄

---

## 效能優化

### 1. 查詢限制
- 每次查詢最多 100 筆記錄
- 按時間戳降序排列（最新的在前）

### 2. 監聽管理
- APP 進入背景時自動停止監聽（省電省流量）
- 使用 `StreamSubscription` 確保資源正確釋放
- 避免重複訂閱同一個查詢

### 3. 錯誤處理
- 監聽錯誤會記錄在 `_error` 中
- 自動停止錯誤的監聽
- UI 顯示錯誤訊息

---

## 疑難排解

### 問題 1：索引錯誤

**錯誤訊息：**
```
[cloud_firestore/failed-precondition] The query requires an index.
```

**解決方案：**
1. 點擊錯誤訊息中的連結自動創建索引
2. 或按照上述「Firestore 索引」說明手動創建
3. 等待索引建立完成（可能需要數分鐘）

### 問題 2：無法接收更新

**檢查清單：**
- [ ] 確認已安裝 `cloud_firestore` 依賴
- [ ] 確認 Firestore 安全規則正確
- [ ] 確認索引已建立
- [ ] 確認用戶已登入
- [ ] 確認已綁定設備
- [ ] 檢查 Debug Console 是否有錯誤訊息

### 問題 3：記憶體洩漏

**檢查清單：**
- [ ] 確認 `dispose()` 中有呼叫 `stopListeningToActivities()`
- [ ] 確認 `WidgetsBindingObserver` 已正確移除
- [ ] 使用 Flutter DevTools 檢查 Stream 是否正確關閉

---

## 未來改進

1. **分頁載入**
   - 目前一次載入 100 筆
   - 可改為無限滾動載入

2. **快取策略**
   - 使用 Firestore 離線持久化
   - APP 啟動時先顯示快取資料

3. **差異更新**
   - 只更新變更的記錄
   - 減少 UI 重建

4. **智能監聽**
   - 根據用戶行為調整監聽頻率
   - 長時間無活動時降低監聽頻率

---

## 相關文檔

- [Cloud Firestore 文檔](https://firebase.google.com/docs/firestore)
- [Flutter Firestore Plugin](https://pub.dev/packages/cloud_firestore)
- [Firebase 安全規則](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore 索引](https://firebase.google.com/docs/firestore/query-data/indexing)

---

**更新日期：** 2026-01-21  
**版本：** 1.0.0
