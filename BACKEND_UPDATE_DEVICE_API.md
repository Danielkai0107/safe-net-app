# 📱 Map App API 欄位說明（給前端）

---

## 1️⃣ 綁定設備 `bindDeviceToMapUser`

**URL**: `https://binddevicetomapuser-kmzfyt3t5a-uc.a.run.app`

**Method**: `POST`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <Firebase_ID_Token>
```

**Request Body**:
```json
{
  "userId": "string (必填) - Map App 用戶 ID",
  "deviceId": "string (選填) - 設備 ID，與 deviceName 二選一",
  "deviceName": "string (選填) - 產品序號，與 deviceId 二選一",
  "nickname": "string (選填) - 設備暱稱，例如：爸爸的卡片",
  "age": "number (選填) - 使用者年齡，例如：75",
  "gender": "string (選填) - 使用者性別：MALE | FEMALE | OTHER",
  "avatar": "string (選填) - 頭像檔名，例如：01.png"
}
```

**Response**:
```json
{
  "success": true,
  "device": {
    "id": "設備ID",
    "uuid": "UUID",
    "major": 1,
    "minor": 1001,
    "deviceName": "1-1001",
    "nickname": "爸爸的卡片",
    "age": 75,
    "gender": "MALE",
    "avatar": "01.png"
  },
  "boundAt": "2025-01-23T12:00:00.000Z"
}
```

---

## 2️⃣ 解綁設備 `unbindDeviceFromMapUser`

**URL**: `https://unbinddevicefrommapuser-kmzfyt3t5a-uc.a.run.app`

**Method**: `POST`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <Firebase_ID_Token>
```

**Request Body**:
```json
{
  "userId": "string (必填) - Map App 用戶 ID"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Device unbound successfully"
}
```

**⚠️ 注意**：解綁後，設備的活動記錄會被清空。重新綁定同一設備時，會從零開始記錄。

---

## 3️⃣ 更新設備資訊 `updateMapUserDevice`

**URL**: `https://updatemapuserdevice-kmzfyt3t5a-uc.a.run.app`

**Method**: `POST`

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <Firebase_ID_Token>
```

**Request Body**:
```json
{
  "userId": "string (必填) - Map App 用戶 ID",
  "avatar": "string (選填) - 頭像檔名，例如：01.png",
  "nickname": "string (選填) - 設備暱稱，例如：爸爸的卡片",
  "age": "number (選填) - 使用者年齡，例如：75",
  "gender": "string (選填) - 使用者性別：MALE | FEMALE | OTHER"
}
```

**Response**:
```json
{
  "success": true,
  "message": "設備資訊已更新",
  "updated": {
    "avatar": true,
    "nickname": true,
    "age": true,
    "gender": false
  }
}
```

**⚠️ 注意**：
- `avatar` 更新到用戶資料（`mapAppUsers`）
- `nickname`, `age`, `gender` 更新到設備資料（`devices`）
- 如果用戶沒有綁定設備，只會更新 `avatar`

---

## 📋 欄位對照表

| 欄位 | 類型 | 必填 | 說明 | 可用值 |
|------|------|------|------|--------|
| `userId` | string | ✅ | Map App 用戶 ID | - |
| `deviceId` | string | ⭕ | 設備 ID（與 deviceName 二選一） | - |
| `deviceName` | string | ⭕ | 產品序號（與 deviceId 二選一） | 例：`1-1001` |
| `avatar` | string | ❌ | 頭像檔名 | 例：`01.png`, `02.png` |
| `nickname` | string | ❌ | 設備暱稱 | 例：`爸爸的卡片` |
| `age` | number | ❌ | 使用者年齡 | 0-150 |
| `gender` | string | ❌ | 使用者性別 | `MALE`, `FEMALE`, `OTHER` |

---

## 🔄 使用流程

```
1. 用戶首次綁定設備
   → 呼叫 bindDeviceToMapUser（可同時帶入 nickname, age, gender, avatar）

2. 用戶更新頭像或設備資訊
   → 呼叫 updateMapUserDevice（可只更新部分欄位）

3. 用戶解綁設備
   → 呼叫 unbindDeviceFromMapUser
   → 活動記錄會被清空（匿名保存到後台統計用）

4. 用戶重新綁定（同一設備或不同設備）
   → 呼叫 bindDeviceToMapUser
   → 從零開始，不會看到舊的活動記錄
```

---

## ⚠️ 錯誤代碼

| HTTP Status | 說明 |
|-------------|------|
| 400 | 缺少必填欄位 / 用戶未綁定設備 |
| 401 | Token 無效或缺少 |
| 403 | 無權限操作他人資料 |
| 404 | 用戶或設備不存在 |
| 500 | 伺服器錯誤 |

---

## 📁 相關前端文件

| 文件 | 說明 |
|------|------|
| `lib/services/api_service.dart` | API 調用實作 |
| `lib/providers/user_provider.dart` | 狀態管理（含綁定流程） |
| `lib/widgets/dialogs/bind_device_dialog.dart` | 綁定設備對話框 |
| `lib/widgets/dialogs/avatar_picker_dialog.dart` | 頭像選擇器 |

---

**最後更新**: 2026-01-23
