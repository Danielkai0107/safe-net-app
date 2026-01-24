#!/bin/bash

# Flutter 應用安裝腳本
# 用於將應用安裝到連接的手機設備

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Flutter 應用安裝腳本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 檢查 Flutter 是否已安裝
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}錯誤: Flutter 未安裝或不在 PATH 中${NC}"
    exit 1
fi

# 顯示 Flutter 版本
echo -e "${GREEN}Flutter 版本:${NC}"
flutter --version | head -n 1
echo ""

# 檢查連接的設備
echo -e "${YELLOW}正在檢查連接的設備...${NC}"
echo ""

DEVICES=$(flutter devices 2>/dev/null)
echo "$DEVICES"
echo ""

# 檢查是否有設備連接
if echo "$DEVICES" | grep -q "No devices detected"; then
    echo -e "${RED}錯誤: 沒有偵測到任何設備${NC}"
    echo ""
    echo "請確保："
    echo "  1. 手機已通過 USB 連接到電腦"
    echo "  2. 手機已開啟 USB 調試模式 (Android) 或信任此電腦 (iOS)"
    echo "  3. 已安裝相應的驅動程式"
    exit 1
fi

# 構建模式選擇
echo -e "${YELLOW}請選擇構建模式:${NC}"
echo "  1) Debug (調試模式 - 開發用)"
echo "  2) Release (發布模式 - 正式版)"
echo "  3) Profile (效能分析模式)"
echo ""
read -p "請輸入選項 (1/2/3) [預設: 2]: " BUILD_MODE

case $BUILD_MODE in
    1)
        MODE="debug"
        MODE_FLAG="--debug"
        ;;
    3)
        MODE="profile"
        MODE_FLAG="--profile"
        ;;
    *)
        MODE="release"
        MODE_FLAG="--release"
        ;;
esac

echo ""
echo -e "${GREEN}已選擇: ${MODE} 模式${NC}"
echo ""

# 平台選擇
echo -e "${YELLOW}請選擇目標平台:${NC}"
echo "  1) Android"
echo "  2) iOS"
echo "  3) 自動偵測 (安裝到所有連接的設備)"
echo ""
read -p "請輸入選項 (1/2/3) [預設: 3]: " PLATFORM_CHOICE

# 是否清理舊構建
echo ""
read -p "是否要先清理舊的構建檔案? (y/n) [預設: n]: " CLEAN_BUILD

if [[ "$CLEAN_BUILD" == "y" || "$CLEAN_BUILD" == "Y" ]]; then
    echo ""
    echo -e "${YELLOW}正在清理舊的構建檔案...${NC}"
    flutter clean
    echo -e "${GREEN}清理完成${NC}"
    echo ""
    
    echo -e "${YELLOW}正在獲取依賴套件...${NC}"
    flutter pub get
    echo -e "${GREEN}依賴套件獲取完成${NC}"
    echo ""
fi

# 執行安裝
echo -e "${YELLOW}正在構建並安裝應用...${NC}"
echo ""

case $PLATFORM_CHOICE in
    1)
        # Android
        echo -e "${BLUE}目標平台: Android${NC}"
        echo ""
        
        # 構建 APK
        echo -e "${YELLOW}正在構建 APK...${NC}"
        flutter build apk $MODE_FLAG
        
        # 安裝到設備
        echo ""
        echo -e "${YELLOW}正在安裝到 Android 設備...${NC}"
        flutter install $MODE_FLAG
        ;;
    2)
        # iOS
        echo -e "${BLUE}目標平台: iOS${NC}"
        echo ""
        
        # 構建 iOS 應用
        echo -e "${YELLOW}正在構建 iOS 應用...${NC}"
        flutter build ios $MODE_FLAG
        
        # 安裝到設備
        echo ""
        echo -e "${YELLOW}正在安裝到 iOS 設備...${NC}"
        flutter install $MODE_FLAG
        ;;
    *)
        # 自動偵測並安裝
        echo -e "${BLUE}自動偵測設備並安裝...${NC}"
        echo ""
        flutter install $MODE_FLAG
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    安裝完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "應用已成功安裝到您的設備。"
echo -e "如果應用沒有自動啟動，請在設備上手動開啟 ${BLUE}flutter_app${NC}。"
echo ""
