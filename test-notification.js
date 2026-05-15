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
    title: '重复通知',
    message: '这是一条会重复的通知（首次 5s 后，每隔 10s 重复一次）',
    delay: 5,
    repeat: true,
    interval: 10,
  }
);

// 4. Test with image (big image notification, delayed 5s)
console.log("=== Test 4: Big Image Notification (5s delay) ===");
CTYNotification.sendLocalNotification(
  (result) => console.log("SUCCESS:", result),
  (error) => console.log("ERROR:", error),
  {
    title: '图片通知',
    message: '这是一条带图片的通知',
    delay: 5,
    image: 'https://cdn-qa-js.szhytop.com/upload/image/20251211/251211114705105029.png',
  }
);

// 5. Test get device token (iOS only, useful for push notifications)
console.log("=== Test 5: Get Device Token ===");
CTYNotification.getDeviceToken(
  (token) => console.log("DEVICE TOKEN:", token),
  (error) => console.log("ERROR getting token:", error)
);
