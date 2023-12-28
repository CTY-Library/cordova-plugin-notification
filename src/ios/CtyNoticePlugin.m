#import <cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <UserNotifications/UserNotifications.h>

@interface CtyNoticePlugin : CDVPlugin{
    CDVPluginResult* pluginResult;
}
     -(void) commonNotice:(CDVInvokedUrlCommand*)command;
     -(void) timedNotice:(CDVInvokedUrlCommand*)command;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler;
     -(void)timedCancelNotice:(CDVInvokedUrlCommand*)command;
     -(void)bigImageNotice:(CDVInvokedUrlCommand*)command;
@end

@implementation CtyNoticePlugin
//普通通知
- (void)commonNotice:(CDVInvokedUrlCommand*)command {
    
    NSArray* arguments = command.arguments;
    NSString* notificationId = [arguments objectAtIndex:0];
    NSString* title = [arguments objectAtIndex:1];
    NSString* subtitle = [arguments objectAtIndex:2];
    NSString* message = [arguments objectAtIndex:3];
    NSString* urlLargeIco = [arguments objectAtIndex:4];
    NSString* urlBigImage = [arguments objectAtIndex:5];
    NSString* strDate = [arguments objectAtIndex:6];
    NSString* strRepeat = [arguments objectAtIndex:7];
    NSString* strType = [arguments objectAtIndex:8];
    
    //通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    //设置通知请求发送时APP图标上显示的数字
    content.badge=@0;
    //通知标题
    content.title=title;
    //通知副标题
    content.subtitle=subtitle;
    //通知内容
    content.body=message;
    //通知声音
    content.sound=[UNNotificationSound defaultSound];
    //设置从通知激活App时的lanunchImage图片
    //content.lauchImageName = @"lanunchImage";

    //通知触发时间
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];

    //设置通知请求
    //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
    NSString* identifier = [NSUUID UUID].UUIDString;

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

    //将通知添加到UNUserNotificationCenter中
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     } else {
        [center addNotificationRequest:request withCompletionHandler:nil];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"success"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     }
    }];
}

- (void)bigImageNotice:(CDVInvokedUrlCommand *)command{
    
    NSArray* arguments = command.arguments;
    NSString* notificationId = [arguments objectAtIndex:0];
    NSString* title = [arguments objectAtIndex:1];
    NSString* subtitle = [arguments objectAtIndex:2];
    NSString* message = [arguments objectAtIndex:3];
    NSString* urlLargeIco = [arguments objectAtIndex:4];
    NSString* urlBigImage = [arguments objectAtIndex:5];
    NSString* strDate = [arguments objectAtIndex:6];
    NSString* strRepeat = [arguments objectAtIndex:7];
    NSString* strType = [arguments objectAtIndex:8];
    
    //通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    //设置通知请求发送时APP图标上显示的数字
    content.badge=@0;
    //通知标题
    content.title=title;
    //通知副标题
    content.subtitle=subtitle;
    //通知内容
    content.body=message;
    //通知声音
    content.sound=[UNNotificationSound defaultSound];
    //设置从通知激活App时的lanunchImage图片
    //content.lauchImageName = @"lanunchImage";

    UNNotificationAttachment *attachment=[UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL URLWithString:urlBigImage] options:nil error:nil];
    
    content.attachments=@[attachment];

    //通知触发时间
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
    
    NSString* identifier = [NSUUID UUID].UUIDString;

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger,options:nil];
    
    //将通知添加到UNUserNotificationCenter中
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
     } else {
        //通知添加成功后触发通知
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"success"];
     }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

//定时通知
-(void)timedNotice:(CDVInvokedUrlCommand*)command {
    
    NSString* notificationId = [command.arguments objectAtIndex:0];
    NSString* title = [command.arguments objectAtIndex:1];
    NSString* subtitle = [command.arguments objectAtIndex:2];
    NSString* message = [command.arguments objectAtIndex:3];
    NSString* urlLargeIco = [command.arguments objectAtIndex:4];
    NSString* urlBigImage = [command.arguments objectAtIndex:5];
    NSString* strDate = [command.arguments objectAtIndex:6];
    NSString* strRepeat = [command.arguments objectAtIndex:7];
    NSString* strType = [command.arguments objectAtIndex:8];

    //通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    //设置通知请求发送时APP图标上显示的数字
    content.badge=@0;
    //通知标题
    content.title=title;
    //通知副标题
    content.subtitle=subtitle;
    //通知内容
    content.body=message;
    //通知声音
    content.sound=[UNNotificationSound defaultSound];
    //设置从通知激活App时的lanunchImage图片
    //content.lauchImageName = @"lanunchImage";

    //通知触发时间
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *nsDate = [dateFormatter dateFromString:strDate];

    //周期日历触发器
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nsDate];


    
    BOOL* repeats =false;

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
    }];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"success"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


//取消定时通知
- (void)timedCancelNotice:(CDVInvokedUrlCommand*)command {
    
    NSString* notificationId = [command.arguments objectAtIndex:0];
    NSString* title = [command.arguments objectAtIndex:1];
    NSString* subtitle = [command.arguments objectAtIndex:2];
    NSString* message = [command.arguments objectAtIndex:3];
    NSString* urlLargeIco = [command.arguments objectAtIndex:4];
    NSString* urlBigImage = [command.arguments objectAtIndex:5];
    NSString* strDate = [command.arguments objectAtIndex:6];
    NSString* strRepeat = [command.arguments objectAtIndex:7];
    NSString* strType = [command.arguments objectAtIndex:8];

    //通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    //设置通知请求发送时APP图标上显示的数字
    content.badge=@0;
    //通知标题
    content.title=title;
    //通知副标题
    content.subtitle=subtitle;
    //通知内容
    content.body=message;
    //通知声音
    content.sound=[UNNotificationSound defaultSound];
    //设置从通知激活App时的lanunchImage图片
    //content.lauchImageName = @"lanunchImage";

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
    }];
}


//仅当应用程序在前台时，才会调用这个方法，如果未实现该方法，通知将不会被触发
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound|UNNotificationPresentationOptionAlert);
}

//当接收到通知，在用户点击通知激活应用程序时调用这个方法，无论是在前台还是后台
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

@end
