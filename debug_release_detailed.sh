#!/bin/bash

echo "🔍 详细调试小米手机Release包日历同步问题"
echo "============================================="

# 检查设备连接
echo "📱 检查设备连接..."
adb devices

echo ""
echo "📦 安装Release包..."
adb install -r build/app/outputs/flutter-apk/app-release.apk

echo ""
echo "🔍 开始详细监控日志..."
echo "请在小米手机上："
echo "1. 完全关闭应用（从最近任务中清除）"
echo "2. 重新打开应用"
echo "3. 新增一个事件"
echo "4. 查看系统日历应用"
echo ""
echo "监控的日志包括："
echo "- 设备检测和Google服务检测"
echo "- 权限请求和处理"
echo "- 日历同步过程"
echo "- 错误信息"
echo ""
echo "按 Ctrl+C 停止监控"
echo ""

# 监控所有相关日志
adb logcat | grep -E "(Debug:|🔍|📱|📅|✅|❌|日历|calendar|Calendar|设备检测|shouldUseCalendarSync|权限|permission|Permission|Google|google|小米|xiaomi|Xiaomi|MIUI|miui)"
