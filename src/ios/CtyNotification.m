#import <cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <UserNotifications/UserNotifications.h>

@interface CtyNotification : CDVPlugin{
    CDVPluginResult* pluginResult;
}
     -(void) commonNotice:(CDVInvokedUrlCommand*)command;
     -(void) timedNotice:(CDVInvokedUrlCommand*)command;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler;
     -(void)timedCancelNotice:(CDVInvokedUrlCommand*)command;
     -(void)bigImageNotice:(CDVInvokedUrlCommand*)command;
     -(void)largeTextNotice:(CDVInvokedUrlCommand*)command;
     -(void)importantNotice:(CDVInvokedUrlCommand*)command;
@end

@implementation CtyNotification
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
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];
    
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
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];
    
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
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
    
    NSString* identifier = [NSUUID UUID].UUIDString;

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    
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
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];

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

    BOOL* repeats =[strRepeat boolValue];
    
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

    if(repeats)
    {
        int intValue=[interval intValue];
        //判断是否是Int值
        if(intValue!=0||[interval isEqualToString:@"0"])
        {
            NSDateComponents *oneTime = [[NSDateComponents alloc] init];
            oneTime.second=intValue;
            NSDate *nextDate = [calendar dateByAddingComponents:oneTime toDate:[calendar dateFromComponents:dateComponents] options:0] //时间相加
            NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nextDate];
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:YES];
        }
        else
        {
            NSDate *nsIntervalDate = [dateFormatter dateFromString:interval];//间隔时间为日期时
            NSDateComponents *oneTime = [[NSDateComponents alloc] init];
             if(nsIntervalDate.year>0)
             {
                oneTime.year=nsIntervalDate.year;
             }
             if(nsIntervalDate.month>0)
             {
                oneTime.month=nsIntervalDate.month;
             }
             if(nsIntervalDate.day>0)
             {
                oneTime.day=nsIntervalDate.day;
             }
             if(nsIntervalDate.hour>0)
             {
                oneTime.hour=nsIntervalDate.hour;
             }
             if(nsIntervalDate.minute>0)
             {
                oneTime.minute=nsIntervalDate.minute;
             }
             if(nsIntervalDate.second>0)
             {
                oneTime.second=nsIntervalDate.second;
             }
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:oneTime repeats:YES];
        }
    } 
     UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
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

    //当有重复任务时调用
    if(repeats){
    [self timedNoticeRepeat:command];
    }
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
    NSString* interval =[arguments objectAtIndex:8]; //通知间隔时间
    NSString* strType = [arguments objectAtIndex:9];

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

    BOOL* repeats =[strRepeat boolValue];
    
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

    NSDateComponents *oneTime = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nextDate];
    if(repeats)
    {
        int intValue=[interval intValue];
        //判断是否是Int值
        if(intValue!=0||[interval isEqualToString:@"0"])
        {
            oneTime.second=intValue;
            UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents oneTime:YES];
        }
        else
        {
             NSDate *nsIntervalDate = [dateFormatter dateFromString:interval];//间隔时间为日期时
             if(nsIntervalDate.year>0)
             {
                oneTime.year=nsIntervalDate.year;
             }
             if(nsIntervalDate.month>0)
             {
                oneTime.month=nsIntervalDate.month;
             }
             if(nsIntervalDate.day>0)
             {
                oneTime.day=nsIntervalDate.day;
             }
             if(nsIntervalDate.hour>0)
             {
                oneTime.hour=nsIntervalDate.hour;
             }
             if(nsIntervalDate.minute>0)
             {
                oneTime.minute=nsIntervalDate.minute;
             }
             if(nsIntervalDate.second>0)
             {
                oneTime.second=nsIntervalDate.second;
             }
        }
    } 
    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:oneTime repeats:YES];
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
