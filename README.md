# cordova-plugin-notification

本插件为 Cordova 应用提供本地/定时通知功能。

重要说明：`getDeviceToken` 状态

- Android: 已从本插件中移除 `getDeviceToken` 接口（不再由本插件提供）。建议在 Android 上集成国内厂商推送或第三方推送 SDK（例如 JPush、华为/小米/OPPO/Vivo 推送）。
- iOS: 本仓库已恢复 iOS 的 `getDeviceToken` 接口（插件会请求通知权限并注册 APNs，然后返回 device token）。

注意：中国大陆网络通常无法稳定访问 Google 后端，因此 FCM 在大陆环境中**不可保证可靠到达**。生产环境请优先考虑国内厂商推送或第三方推送服务。

推荐：JPush（极光推送） 
- 仓库： https://github.com/CTY-Library/jpush-phonegap-plugin
- 安装并使用后，可以通过 JS 获取设备标识（registration id）：

```javascript
// 初始化并获取 registration id
window.plugins.jPushPlugin.init();
window.plugins.jPushPlugin.getRegistrationID(function(regId){
  console.log('JPush registration id:', regId);
  // 将 regId 上报到你的后端，用于目标推送
});
```

## iOS: `getDeviceToken` 使用示例

下面示例演示如何在 JS 端从插件获取 iOS 的 APNs device token（仅在 iOS 真机可用）：

```javascript
// 建议在 deviceready 后调用
document.addEventListener('deviceready', function () {
  CTYNotification.getDeviceToken(function(token){
    console.log('APNs device token:', token);
    // 将 token 上报到后端以便服务器向该设备发送远程通知
  }, function(err){
    console.error('getDeviceToken failed:', err);
  });
});
```

说明：
- 该方法会先请求本地通知权限（若尚未授予），然后调用 `registerForRemoteNotifications` 注册 APNs 并在成功时返回 token。
- 模拟器不支持 APNs 设备 token，必须在真机上测试。
- 看到 `CtyNotification: didRegisterForRemoteNotifications token=...` 后，若你也看到 `APNs device token: ...`，表示 JS 回调已成功执行。
- `console.log` 可能显示在 Safari Web Inspector（WebView 控制台）或 Xcode 控制台（取决于运行环境与日志桥接配置）。

Safari 控制台调试（推荐）：
- `CTYNotification.getDeviceToken(...)` 现在会返回 Promise；可继续使用原回调写法，无需改接口。
- 如果你在控制台执行表达式后看到 `undefined`，通常是控制台对表达式返回值的回显，不等同于“回调失败”。
- 成功后插件会写入 `window.__CTY_APNS_TOKEN__`，可直接在控制台输入该变量验证。
- 成功后插件会派发 `CTYNotificationDeviceToken` 事件，可监听该事件观察 token。

```javascript
// 方式1：Promise（不改变原接口，仅多一种调试方式）
CTYNotification.getDeviceToken()
  .then(token => console.log('Promise token:', token))
  .catch(err => console.error('Promise error:', err));

// 方式2：查看插件写入的全局变量
console.log('window.__CTY_APNS_TOKEN__ =', window.__CTY_APNS_TOKEN__);

// 方式3：监听插件派发事件
window.addEventListener('CTYNotificationDeviceToken', function (e) {
  console.log('Event token:', e.detail && e.detail.token);
});
```

### iOS 推送配置清单

在 iOS 上成功获取 device token 前，请按下列步骤检查并配置：

1. Apple 开发者门户：
  - 在 Apple Developer → Identifiers 为你的 App ID 启用 **Push Notifications**。
  - 推荐使用 APNs Auth Key（.p8），或为开发/生产生成 APNs 证书（.cer）。记录 Key ID 与 Team ID。

2. Xcode 设置（App Target -> Signing & Capabilities）：
  - 打开 App Target -> `Signing & Capabilities`。
  - 添加 **Push Notifications** capability。
  - 同时确认 **Background Modes** 中已勾选 **Remote notifications**（建议开启）。
  - 确保 `Bundle Identifier` 与 Apple Developer 上的 App ID 一致，且使用包含 Push 权限的 Provisioning Profile。

3. Entitlements：
  - `.entitlements` 文件应包含 `aps-environment`，其值为 `development` 或 `production`，与 provisioning profile 环境匹配。

4. 原生行为与插件：
  - 请求通知权限后调用 `[[UIApplication sharedApplication] registerForRemoteNotifications]`。
  - 插件需能接收或拦截 `application:didRegisterForRemoteNotificationsWithDeviceToken:` 回调并将 token 返回给 JS（本仓库的 `CTYNotification.getDeviceToken` 已实现此逻辑）。

5. 真机验证：
  - 必须在真机上测试；模拟器无法获取 APNs token。
  - 使用 Xcode 安装带有正确 provisioning profile 的构建，并在设备控制台查看注册回调与 token。

6. 后端与发送：
  - 推荐使用 APNs Auth Key（.p8）在服务器端发送推送；或把证书上传至第三方推送服务。
  - 区分开发/生产环境并使用对应证书或参数。

7. 常见问题排查：
  - 若权限被拒绝，提示用户到设置打开通知权限并重试。
  - 若未获得 token，检查 Push capability、真机环境、以及 AppDelegate 回调是否被覆盖或未转发。

注意
- 如果你仅需要在设备上做定时或本地提醒（闹钟、日程等），本插件仍然支持 Android 与浏览器平台的本地通知功能。
- 若需要，我可以帮你将本插件的 JS 层扩展为：检测到 JPush 插件时自动代理 `getDeviceToken`（可选，向后兼容）。

若需进一步帮助（例如集成 JPush 或自动代理实现），请告诉我你的选择，我会继续协助你。

## 测试脚本（示例）

下面是一个用于在 `deviceready` 后在浏览器控制台或应用中运行的测试脚本 `test-notification.js`，用于验证本地/定时通知的调用参数与行为：

```javascript
/** 
 * Test script to verify notification parameter passing
 * Run this in browser console after deviceready
 */

// 1. Test immediate notification (should work)
console.log("=== Test 1: Immediate Common Notification ===");
CTYNotification.sendLocalNotification(
  (result) => console.log("SUCCESS:", result),
  (error) => console.log("ERROR:", error),
  {
    notificationId: 1001,
    title: '立即通知',
    message: '这是一条立即通知（无延迟）',
  }
);

// 2. Test delayed notification (5 second delay)
console.log("=== Test 2: Delayed Notification (5s) ===");
CTYNotification.sendLocalNotification(
  (result) => console.log("SUCCESS:", result),
  (error) => console.log("ERROR:", error),
  {
    notificationId: 1002,
    title: '延迟通知',
    message: '这是一条延迟 5 秒的通知',
    delay: 5,
  }
);

// 3. Test repeating notification (5s delay + 10s interval)
console.log("=== Test 3: Repeating Notification (5s delay + 10s interval) ===");
CTYNotification.sendLocalNotification(
  (result) => console.log("SUCCESS:", result),
  (error) => console.log("ERROR:", error),
  {
    notificationId: 3001,
    title: '重复通知',
    message: '这是一条会重复的通知（首次 6s 后，每隔 10s 重复一次, 共重复 5 次）',
    delay: 6,
    repeat: true,
    interval: 10,
    total: 5
  }
);

// 4. Test with image (big image notification, delayed 5s)
console.log("=== Test 4: Big Image Notification (5s delay) ===");
CTYNotification.sendLocalNotification(
  (result) => console.log("SUCCESS:", result),
  (error) => console.log("ERROR:", error),
  {
    notificationId: 1004,
    title: '图片通知',
    message: '这是一条带图片的通知',
    delay: 8,
    image: 'https://cdn-qa-js.szhytop.com/upload/image/20251211/251211114705105029.png',
  }
);

```
