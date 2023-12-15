#import <cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface CTYUserNotifications : CDVPlugin
     CDVPluginResult* pluginResult;
@end

@implementation CTYUserNotifications
- (void)addLocalNotificationNS:(CDVInvokedUrlCommand*)command {
    
    NSString* title = [command.arguments objectAtIndex:0];
    NSString* subtitle = [command.arguments objectAtIndex:1];
    NSString* body = [command.arguments objectAtIndex:2];

    //通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    //设置通知请求发送时APP图标上显示的数字
    content.badge=@0;
    //通知标题
    content.title=title;
    //通知副标题
    content.subtitle=subtitle;
    //通知内容
    content.body=body;
    //通知声音
    content.sound=[UNNotificationSound defaultSound];
    //设置从通知激活App时的lanunchImage图片
    content.lauchImageName = @"lanunchImage";

    //通知触发时间
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];

    //设置通知请求
    //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
    NSString* identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

    //将通知添加到UNUserNotificationCenter中
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }
    }]
}


-(void)addLocalNotificationCalendar:(CDVInvokedUrlCommand*)command {
    
    NSString* title = [command.arguments objectAtIndex:0];
    NSString* subtitle = [command.arguments objectAtIndex:1];
    NSString* body = [command.arguments objectAtIndex:2];
    NSString* date = [command.arguments objectAtIndex:3];
    NSString* bRepeats = [command.arguments objectAtIndex:3];

    //通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    //设置通知请求发送时APP图标上显示的数字
    content.badge=@0;
    //通知标题
    content.title=title;
    //通知副标题
    content.subtitle=subtitle;
    //通知内容
    content.body=body;
    //通知声音
    content.sound=[UNNotificationSound defaultSound];
    //设置从通知激活App时的lanunchImage图片
    content.lauchImageName = @"lanunchImage";

    //通知触发时间
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *nsDate = [dateFormatter dateFromString:date];

    //周期日历触发器
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = nsDate.year;
    dateComponents.month =nsDate.month;
    dateComponents.day =nsDate.day;
    dateComponents.hour =nsDate.hour;
    dateComponents.minute =nsDate.minute;
    dateComponents.second =nsDate.second;
    
    BOOL* repeats = [bRepeats boolValue];

    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:repeats];

    //设置通知请求
    //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
    NSString* identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

    //将通知添加到UNUserNotificationCenter中
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        }
    }]
}

//仅当应用程序在前台时，才会调用这个方法，如果未实现该方法，通知将不会被触发
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
}

//当接收到通知，在用户点击通知激活应用程序时调用这个方法，无论是在前台还是后台
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}



