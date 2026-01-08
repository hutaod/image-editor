# Google Play 数据安全声明指南

## 问题概述
应用被Google Play拒绝，原因是"数据安全部分"（Data safety section）不符合Google Play用户数据政策要求。

## 应用收集的数据类型

根据代码分析，应用收集以下数据：

### 1. 设备ID（Device ID）
- **收集方式**：通过`device_info_plus`获取Android设备ID（`androidInfo.id`）和iOS的`identifierForVendor`
- **处理方式**：进行MD5哈希后发送到服务器
- **用途**：用户识别、认证
- **代码位置**：`lib/services/network_service.dart` 第94-129行

### 2. 应用使用数据（通过友盟统计）
- **SDK**：友盟统计（Umeng Analytics）
- **收集内容**：应用使用情况、页面访问统计、自定义事件
- **已禁用**：应用列表、IMEI、IMSI、ICCID、WiFi MAC地址
- **代码位置**：`lib/services/umeng_service.dart` 第40-48行

### 3. 会员订阅数据（通过RevenueCat）
- **SDK**：RevenueCat
- **收集内容**：购买记录、订阅状态
- **代码位置**：`lib/services/revenue_cat_service.dart`

### 4. 应用包名（Bundle ID）
- **收集方式**：通过`package_info_plus`获取
- **用途**：与设备ID组合用于认证
- **代码位置**：`lib/services/network_service.dart` 第131-140行

## Google Play Console 数据安全部分填写指南

### 步骤1：登录Google Play Console
1. 访问 [Google Play Console](https://play.google.com/console)
2. 选择你的应用：**Days Reminder - 倒数日历** (com.qualrb.daysreminder)
3. 进入 **政策** → **数据安全**（Data safety）

### 步骤2：填写数据收集和共享

**重要提示**：AndroidManifest.xml中声明了`READ_PHONE_STATE`权限，但根据代码分析，应用仅用于获取设备ID（`androidInfo.id`），并不收集电话号码等敏感信息。如果Google询问此权限用途，请说明：仅用于获取设备标识符，不收集电话号码、IMEI等敏感信息。

#### 2.1 设备ID或其他ID

**是否收集？** 选择 **是**

**数据类型**：
- ✅ **设备ID或其他ID**
  - 选择：**设备ID**
  - 用途：
    - ✅ **应用功能**（用于用户认证）
    - ✅ **分析**（可选，如果用于统计）
  - 是否与第三方共享：**是**
    - 共享方：**友盟（Umeng）**、**RevenueCat**（如果RevenueCat也使用设备ID）
  - 是否加密传输：**是**
  - 是否可要求删除：**否**（设备ID通常用于识别，删除后无法恢复）

#### 2.2 应用活动

**是否收集？** 选择 **是**

**数据类型**：
- ✅ **应用交互**
  - 用途：
    - ✅ **分析**（通过友盟统计）
  - 是否与第三方共享：**是**
    - 共享方：**友盟（Umeng）**
  - 是否加密传输：**是**
  - 是否可要求删除：**是**（可选）

- ✅ **应用内搜索历史**（如果应用有搜索功能）
  - 用途：
    - ✅ **应用功能**
  - 是否与第三方共享：**否**（如果只存储在本地）

- ✅ **其他用户生成的内容**（如果用户创建事件、备注等）
  - 用途：
    - ✅ **应用功能**
  - 是否与第三方共享：**否**（根据代码，这些数据只存储在本地）

#### 2.3 财务信息

**是否收集？** 选择 **是**（因为使用了RevenueCat进行应用内购买）

**数据类型**：
- ✅ **购买历史**
  - 用途：
    - ✅ **应用功能**（会员订阅管理）
  - 是否与第三方共享：**是**
    - 共享方：**RevenueCat**
  - 是否加密传输：**是**
  - 是否可要求删除：**否**（购买记录需要保留）

#### 2.4 应用信息和性能

**是否收集？** 选择 **是**

**数据类型**：
- ✅ **崩溃日志**
  - 用途：
    - ✅ **分析**（如果友盟收集崩溃日志）
  - 是否与第三方共享：**是**
    - 共享方：**友盟（Umeng）**
  - 是否加密传输：**是**

- ✅ **诊断信息**
  - 用途：
    - ✅ **分析**
  - 是否与第三方共享：**是**
    - 共享方：**友盟（Umeng）**

### 步骤3：填写数据安全做法

#### 3.1 数据加密
- ✅ **传输中的数据加密**：选择 **是**
  - 说明：所有网络请求使用HTTPS加密传输

#### 3.2 数据删除
- ✅ **用户可请求删除数据**：选择 **部分**
  - 说明：用户可以删除应用内创建的事件数据，但设备ID和购买记录无法删除（用于应用功能）

### 步骤4：填写隐私政策链接

**隐私政策URL**：
- 如果应用内已有隐私政策页面，需要提供一个可公开访问的URL
- 建议：在GitHub Pages、网站或应用官网托管隐私政策

### 步骤5：第三方SDK声明

#### 友盟统计（Umeng）
- **SDK名称**：友盟统计 / Umeng Analytics
- **收集的数据**：
  - 设备ID
  - 应用使用情况
  - 页面访问统计
  - 崩溃日志（如果启用）
- **隐私政策**：需要在友盟官网查找其隐私政策链接

#### RevenueCat
- **SDK名称**：RevenueCat
- **收集的数据**：
  - 购买记录
  - 订阅状态
  - 设备ID（可能）
- **隐私政策**：https://www.revenuecat.com/privacy

## 常见问题和解决方案

### Q1: 友盟统计是否收集敏感数据？
**A**: 根据代码，已经禁用了以下敏感数据收集：
- ✅ 应用列表（enableAplCollection: false）
- ✅ IMEI（enableImeiCollection: false）
- ✅ IMSI（enableImsiCollection: false）
- ✅ ICCID（enableIccidCollection: false）
- ✅ WiFi MAC地址（enableWiFiMacCollection: false）

但仍会收集基本的使用统计和设备信息，需要在数据安全部分声明。

### Q2: 设备ID是否属于敏感数据？
**A**: 设备ID本身不是敏感数据，但Google要求必须声明。由于应用对设备ID进行了MD5哈希处理，相对更安全。

### Q3: 本地存储的数据需要声明吗？
**A**: 如果数据只存储在本地设备，不发送到服务器或第三方，通常不需要在数据安全部分声明。但用户创建的事件数据如果只存储在本地，可以不声明。

### Q4: 如何确认第三方SDK收集的数据？
**A**: 
1. 查看SDK的官方文档
2. 查看SDK的隐私政策
3. 使用网络抓包工具（如Charles Proxy）检查实际发送的数据

### Q5: READ_PHONE_STATE权限需要声明吗？
**A**: AndroidManifest.xml中声明了此权限，但应用仅用于获取设备ID（通过`device_info_plus`的`androidInfo.id`），不收集电话号码。如果Google询问，请说明：
- 权限用途：仅用于获取设备标识符
- 不收集：电话号码、IMEI、IMSI等敏感信息
- 实际使用：通过`device_info_plus`获取设备ID，然后进行MD5哈希处理

## 检查清单

在提交审核前，请确认：

- [ ] 已声明所有收集的数据类型
- [ ] 已声明所有第三方SDK
- [ ] 已提供隐私政策链接
- [ ] 数据用途说明准确
- [ ] 数据共享情况准确
- [ ] 数据加密方式已说明
- [ ] 数据删除政策已说明

## 提交审核后的注意事项

1. **等待审核**：通常需要1-3个工作日
2. **查看反馈**：如果再次被拒，查看Google的详细反馈
3. **及时更新**：根据反馈更新数据安全声明
4. **保持一致性**：确保数据安全声明与应用实际行为一致

## 参考资源

- [Google Play 数据安全政策](https://support.google.com/googleplay/android-developer/answer/10787469)
- [数据安全表单填写指南](https://support.google.com/googleplay/android-developer/answer/10144311)
- [友盟统计隐私说明](https://developer.umeng.com/docs/119267/detail/118585)
- [RevenueCat 隐私政策](https://www.revenuecat.com/privacy)

## 联系支持

如果遇到问题，可以：
1. 点击Google邮件中的"个性化帮助"链接
2. 在Google Play Console中提交支持请求
3. 查看Google Play政策支持中心

---

**最后更新**：2024年11月

