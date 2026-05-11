#import <cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <UserNotifications/UserNotifications.h>

@interface CtyNotification : CDVPlugin{
    CDVPluginResult* pluginResult;
    NSData *_deviceToken;
    NSString *_pendingTokenCallbackId;
}
     -(void) commonNotification:(CDVInvokedUrlCommand*)command;
     -(void) timedNotice:(CDVInvokedUrlCommand*)command;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler;
     -(void) timedCancelNotice:(CDVInvokedUrlCommand*)command;
     -(void) bigImageNotice:(CDVInvokedUrlCommand*)command;
     -(void) largeTextNotice:(CDVInvokedUrlCommand*)command;
     -(void) importantNotice:(CDVInvokedUrlCommand*)command;
     -(void) getDeviceToken:(CDVInvokedUrlCommand*)command;
     -(void) requestNotificationPermission:(void(^)(BOOL granted))completionHandler;
@end

@implementation CtyNotification

- (void)pluginInitialize {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    // 监听 Cordova AppDelegate 注册远程通知成功时发出的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidRegisterForRemoteNotifications:)
                                                 name:@"CDVRemoteNotification"
                                               object:nil];
    // 监听注册失败
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidFailToRegisterForRemoteNotifications:)
                                                 name:@"CDVRemoteNotificationError"
                                               object:nil];
}

- (void)onDidRegisterForRemoteNotifications:(NSNotification *)notification {
    _deviceToken = (NSData *)notification.object;
    if (_pendingTokenCallbackId) {
        NSString *hexToken = [self hexStringFromDeviceToken:_deviceToken];
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:hexToken];
        [self.commandDelegate sendPluginResult:result callbackId:_pendingTokenCallbackId];
        _pendingTokenCallbackId = nil;
    }
}

- (void)onDidFailToRegisterForRemoteNotifications:(NSNotification *)notification {
    if (_pendingTokenCallbackId) {
        NSError *error = (NSError *)notification.object;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                   messageAsString:error.localizedDescription ?: @"注册远程通知失败"];
        [self.commandDelegate sendPluginResult:result callbackId:_pendingTokenCallbackId];
        _pendingTokenCallbackId = nil;
    }
}

- (NSString *)hexStringFromDeviceToken:(NSData *)token {
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    if ([systemVersion doubleValue] > 13.0) {
        NSUInteger len = token.length;
        const unsigned char *buf = (const unsigned char *)token.bytes;
        NSMutableString *hex = [NSMutableString stringWithCapacity:len * 2];
        for (NSUInteger i = 0; i < len; i++) {
            [hex appendFormat:@"%02x", buf[i]];
        }
        return [hex copy];
    } else {
        NSString *hex = [[token description] stringByTrimmingCharactersInSet:
                         [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
        return [hex stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
}

//请求通知权限
-(void) requestNotificationPermission:(void(^)(BOOL granted))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    //检查当前权限状态
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
            //权限未决定，申请权限
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge) 
                                  completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    //权限获取成功，在主线程更新 UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] registerForRemoteNotifications];
                    });
                }
                completionHandler(granted);
            }];
        } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized || 
                   settings.authorizationStatus == UNAuthorizationStatusProvisional) {
            //权限已授予
            completionHandler(YES);
        } else {
            //权限被拒绝
            completionHandler(NO);
        }
    }];
}

//普通通知
- (void)commonNotification:(CDVInvokedUrlCommand*)command {
    
    NSArray* arguments = command.arguments;
    NSString* notificationId = [arguments objectAtIndex:0];
    NSString* title = [arguments objectAtIndex:1];
    NSString* subtitle = [arguments objectAtIndex:2];
    NSString* message = [arguments objectAtIndex:3];
    NSString* urlLargeIco = [arguments objectAtIndex:4];
    NSString* urlBigImage = [arguments objectAtIndex:5];
    NSString* strDate = [arguments objectAtIndex:6];
    NSString* strRepeat = [arguments objectAtIndex:7];
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];
    
    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝，请在设置中启用通知权限"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];

        //设置通知请求
        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
        NSString* identifier = [NSUUID UUID].UUIDString;

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}

 -(void)largeTextNotice:(CDVInvokedUrlCommand*)command {
    
    NSArray* arguments = command.arguments;
    NSString* notificationId = [arguments objectAtIndex:0];
    NSString* title = [arguments objectAtIndex:1];
    NSString* subtitle = [arguments objectAtIndex:2];
    NSString* message = [arguments objectAtIndex:3];
    NSString* urlLargeIco = [arguments objectAtIndex:4];
    NSString* urlBigImage = [arguments objectAtIndex:5];
    NSString* strDate = [arguments objectAtIndex:6];
    NSString* strRepeat = [arguments objectAtIndex:7];
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];
    
    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];

        //设置通知请求
        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
        NSString* identifier = [NSUUID UUID].UUIDString;

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}

- (void)importantNotice:(CDVInvokedUrlCommand *)command {
    
    NSArray* arguments = command.arguments;
    NSString* notificationId = [arguments objectAtIndex:0];
    NSString* title = [arguments objectAtIndex:1];
    NSString* subtitle = [arguments objectAtIndex:2];
    NSString* message = [arguments objectAtIndex:3];
    NSString* urlLargeIco = [arguments objectAtIndex:4];
    NSString* urlBigImage = [arguments objectAtIndex:5];
    NSString* strDate = [arguments objectAtIndex:6];
    NSString* strRepeat = [arguments objectAtIndex:7];
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];
    
    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];

        //设置通知请求
        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
        NSString* identifier = [NSUUID UUID].UUIDString;

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
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
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];
    
    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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
       
        NSURL *imageURL=[NSURL URLWithString:urlBigImage];
        
        NSData *imageData=[NSData dataWithContentsOfURL:imageURL];
        
        // Save the downloaded image to a temporary file
        NSString *temporaryDirectory = NSTemporaryDirectory();
        NSString *imagePath = [temporaryDirectory stringByAppendingPathComponent:@"image.jpg"];
        [imageData writeToFile:imagePath atomically:YES];
        
        // Create a UNNotificationAttachment with the temporary image file
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:nil];
        if (attachment) {
            // Attach the image to the notification content
            content.attachments = @[attachment];
        }
        //通知触发时间
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
        
        NSString* identifier = [NSUUID UUID].UUIDString;

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        
        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
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
    NSString* interval =[command.arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [command.arguments objectAtIndex:9];

    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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

        Boolean initRepeats=[strRepeat boolValue];
        Boolean* repeats =&initRepeats;
        
        NSURL *imageURL=[NSURL URLWithString:urlBigImage];
        
        NSData *imageData=[NSData dataWithContentsOfURL:imageURL];
        
        // Save the downloaded image to a temporary file
        NSString *temporaryDirectory = NSTemporaryDirectory();
        NSString *imagePath = [temporaryDirectory stringByAppendingPathComponent:@"image.jpg"];
        [imageData writeToFile:imagePath atomically:YES];
        
        // Create a UNNotificationAttachment with the temporary image file
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:nil];
        if (attachment) {
            // Attach the image to the notification content
            content.attachments = @[attachment];
        }
        //周期日历触发器   //设置通知触发时间  //设置通知触发时间  

        UNCalendarNotificationTrigger *trigger;
        
        if(*repeats)
        {
            int intValue=[interval intValue];
            //判断是否是Int值
            if(intValue!=0||[interval isEqualToString:@"0"])
            {
                NSDateComponents *oneTime = [[NSDateComponents alloc] init];
                oneTime.second=intValue;
                NSDate *nextDate = [calendar dateByAddingComponents:oneTime toDate:[calendar dateFromComponents:dateComponents] options:0]; //时间相加
                NSDateComponents *nextDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nextDate];
                trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:nextDateComponents repeats:YES];
            }
            else
            {
                NSDate *nsIntervalDate = [dateFormatter dateFromString:interval];//间隔时间为日期时
                NSDateComponents *oneTime = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond     fromDate:nsIntervalDate];
                trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:oneTime repeats:YES];
            }
        } 
        else
        {
            trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
        }
        //设置通知请求
        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
        NSString* identifier = [[NSUUID UUID] UUIDString];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
        //当有重复任务时调用
        if(*repeats){
        [self timedNoticeRepeat:command];
        }
    }];
}

//重复定时通知
-(void)timedNoticeRepeat:(CDVInvokedUrlCommand*)command {
    
    NSString* notificationId = [command.arguments objectAtIndex:0];
    NSString* title = [command.arguments objectAtIndex:1];
    NSString* subtitle = [command.arguments objectAtIndex:2];
    NSString* message = [command.arguments objectAtIndex:3];
    NSString* urlLargeIco = [command.arguments objectAtIndex:4];
    NSString* urlBigImage = [command.arguments objectAtIndex:5];
    NSString* strDate = [command.arguments objectAtIndex:6];
    NSString* strRepeat = [command.arguments objectAtIndex:7];
    NSString* interval =[command.arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [command.arguments objectAtIndex:9];

    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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

        NSURL *imageURL=[NSURL URLWithString:urlBigImage];
        
        NSData *imageData=[NSData dataWithContentsOfURL:imageURL];
        
        // Save the downloaded image to a temporary file
        NSString *temporaryDirectory = NSTemporaryDirectory();
        NSString *imagePath = [temporaryDirectory stringByAppendingPathComponent:@"image.jpg"];
        [imageData writeToFile:imagePath atomically:YES];
        
        // Create a UNNotificationAttachment with the temporary image file
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:nil];
        if (attachment) {
            // Attach the image to the notification content
            content.attachments = @[attachment];
        } 
        
        //Create trigger with interval
        int intValue=[interval intValue];
        UNCalendarNotificationTrigger *trigger;
        
        //判断是否是Int值
        if(intValue!=0||[interval isEqualToString:@"0"])
        {
            NSDateComponents *oneTime = [[NSDateComponents alloc] init];
            oneTime.second=intValue;
            NSDate *nextDate = [calendar dateByAddingComponents:oneTime toDate:[calendar dateFromComponents:dateComponents] options:0]; //时间相加
            NSDateComponents *nextDateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nextDate];
            trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:nextDateComponents repeats:YES];
        }
        else
        {
            NSDate *nsIntervalDate = [dateFormatter dateFromString:interval];//间隔时间为日期时
            NSDateComponents *oneTime = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nsIntervalDate];
            trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:oneTime repeats:YES];
        }
        
        //设置通知请求
        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
        NSString* identifier = [[NSUUID UUID] UUIDString];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
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

    //请求通知权限
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
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
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];

        //设置通知请求
        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
        NSString* identifier = [[NSUUID UUID] UUIDString];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        //将通知添加到UNUserNotificationCenter中
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
             if (error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}

//仅当应用程序在前台时，才会调用这个方法，如果未实现该方法，通知将不会被触发
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList);
    } else {
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    }
}

//当接收到通知，在用户点击通知激活应用程序时调用这个方法，无论是在前台还是后台
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

-(void) getDeviceToken:(CDVInvokedUrlCommand*)command
{
    // 如果已经持有 token，直接返回
    if (_deviceToken) {
        NSString *hexToken = [self hexStringFromDeviceToken:_deviceToken];
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:hexToken];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    // 保存 callbackId，等待 APNs 异步返回 token
    _pendingTokenCallbackId = command.callbackId;

    // 请求权限后注册远程通知
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            _pendingTokenCallbackId = nil;
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                       messageAsString:@"通知权限被拒绝，无法获取 deviceToken"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        });
    }];
}
@end
