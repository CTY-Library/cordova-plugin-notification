# cordova-plugin-notification

本插件为 Cordova 应用提供本地/定时通知功能。

重要说明：`getDeviceToken` 已移除

- 本插件已从 Android 和 iOS 中移除 `getDeviceToken` 接口。
- 在中国大陆使用远程推送（服务器下发）请集成第三方推送服务，例如 极光（JPush）。

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

注意
- 如果你仅需要在设备上做定时或本地提醒（闹钟、日程等），本插件仍然支持 Android 与浏览器平台的本地通知功能。
- 若需要，我可以帮你将本插件的 JS 层扩展为：检测到 JPush 插件时自动代理 `getDeviceToken`（可选，向后兼容）。

若需进一步帮助（例如集成 JPush 或自动代理实现），请告诉我你的选择，我会继续协助。

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
