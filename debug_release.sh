#!/bin/bash

echo "🔍 调试小米手机Release包日历同步问题"
echo "=================================="

# 检查设备连接
echo "📱 检查设备连接..."
adb devices

echo ""
echo "📦 安装Release包..."
adb install -r build/app/outputs/flutter-apk/app-release.apk

echo ""
echo "🔍 开始监控日志..."
echo "请在小米手机上："
echo "1. 打开应用"
echo "2. 新增一个事件"
echo "3. 查看系统日历应用"
echo ""
echo "按 Ctrl+C 停止监控"
echo ""

# 监控日志，过滤关键信息
adb logcat | grep -E "(日历|calendar|Calendar|设备检测|shouldUseCalendarSync|Debug:|🔍|📱|📅|✅|❌)"
