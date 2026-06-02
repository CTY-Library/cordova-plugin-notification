#import <cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <UserNotifications/UserNotifications.h>
#import <objc/runtime.h>

@interface CtyNotification : CDVPlugin{
    CDVPluginResult* pluginResult;
}
    -(void)getDeviceToken:(CDVInvokedUrlCommand*)command;
     -(void) commonNotification:(CDVInvokedUrlCommand*)command;
     -(void) timedNotice:(CDVInvokedUrlCommand*)command;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
     -(void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler;
     -(void) timedCancelNotice:(CDVInvokedUrlCommand*)command;
     -(void) bigImageNotice:(CDVInvokedUrlCommand*)command;
     -(void) largeTextNotice:(CDVInvokedUrlCommand*)command;
     -(void) importantNotice:(CDVInvokedUrlCommand*)command;
     -(void) requestNotificationPermission:(void(^)(BOOL granted))completionHandler;
@end

@implementation CtyNotification

static NSString *gDeviceToken = nil;
static NSMutableArray<NSString *> *gPendingCallbackIds = nil;
static CtyNotification *gSharedPlugin = nil;
static IMP gOriginalDidRegisterImp = NULL;
static IMP gOriginalDidFailImp = NULL;
static BOOL gSwizzled = NO;
static BOOL gTokenRequestInFlight = NO;
static const NSTimeInterval kDeviceTokenTimeoutSeconds = 60.0;

static NSString *cty_escapeJSString(NSString *input) {
    if (!input) return @"";
    NSMutableString *escaped = [input mutableCopy];
    [escaped replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"'" withString:@"\\'" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, escaped.length)];
    [escaped replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, escaped.length)];
    return escaped;
}

static void cty_emitJsConsole(BOOL isError, NSString *message) {
    if (!gSharedPlugin || !message || message.length == 0) return;
    NSString *escaped = cty_escapeJSString(message);
    NSString *level = isError ? @"error" : @"log";
    NSString *js = [NSString stringWithFormat:@"(function(){try{console.%@('%@');}catch(e){}})();", level, escaped];
    [gSharedPlugin.commandDelegate evalJs:js];
}

static void cty_addPendingCallback(NSString *callbackId) {
    if (!callbackId || callbackId.length == 0) return;
    if (!gPendingCallbackIds) {
        gPendingCallbackIds = [NSMutableArray array];
    }
    if (![gPendingCallbackIds containsObject:callbackId]) {
        [gPendingCallbackIds addObject:callbackId];
    }
}

static BOOL cty_removePendingCallback(NSString *callbackId) {
    if (!callbackId || !gPendingCallbackIds) return NO;
    NSUInteger idx = [gPendingCallbackIds indexOfObject:callbackId];
    if (idx == NSNotFound) return NO;
    [gPendingCallbackIds removeObjectAtIndex:idx];
    return YES;
}

static NSArray<NSString *> *cty_drainPendingCallbacks(void) {
    if (!gPendingCallbackIds || gPendingCallbackIds.count == 0) return @[];
    NSArray<NSString *> *all = [gPendingCallbackIds copy];
    [gPendingCallbackIds removeAllObjects];
    return all;
}

static NSUInteger cty_pendingCallbackCount(void) {
    return gPendingCallbackIds ? gPendingCallbackIds.count : 0;
}

// Swizzled handlers
static void cty_didRegister(id self, SEL _cmd, UIApplication *application, NSData *deviceToken) {
    if (gOriginalDidRegisterImp) {
        ((void(*)(id,SEL,UIApplication*,NSData*))gOriginalDidRegisterImp)(self, _cmd, application, deviceToken);
    }
    const unsigned *dataBuffer = (const unsigned *)[deviceToken bytes];
    if (!dataBuffer) return;
    NSMutableString *hex = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [hex appendFormat:@"%02x", ((const unsigned char *)[deviceToken bytes])[i]];
    }
    gDeviceToken = [hex copy];
    NSLog(@"CtyNotification: didRegisterForRemoteNotifications token=%@", gDeviceToken);
    cty_emitJsConsole(NO, [NSString stringWithFormat:@"CtyNotification: didRegisterForRemoteNotifications token=%@", gDeviceToken]);
    gTokenRequestInFlight = NO;

    if (gSharedPlugin) {
        NSArray<NSString *> *callbacks = cty_drainPendingCallbacks();
        NSLog(@"CtyNotification: dispatching token to %lu JS callback(s)", (unsigned long)callbacks.count);
        cty_emitJsConsole(NO, [NSString stringWithFormat:@"CtyNotification: dispatching token to %lu JS callback(s)", (unsigned long)callbacks.count]);
        for (NSString *callbackId in callbacks) {
            CDVPluginResult *pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:gDeviceToken];
            [gSharedPlugin.commandDelegate sendPluginResult:pr callbackId:callbackId];
        }
    }
}

static void cty_didFail(id self, SEL _cmd, UIApplication *application, NSError *error) {
    if (gOriginalDidFailImp) {
        ((void(*)(id,SEL,UIApplication*,NSError*))gOriginalDidFailImp)(self, _cmd, application, error);
    }
    NSLog(@"CtyNotification: didFailToRegisterForRemoteNotifications error=%@", error);
    cty_emitJsConsole(YES, [NSString stringWithFormat:@"CtyNotification: didFailToRegisterForRemoteNotifications error=%@", error]);
    NSString *errorMessage = [error localizedDescription] ?: @"APNs 注册失败";
    if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == 3000) {
        errorMessage = @"APNs 注册失败：缺少 aps-environment 权限。请在 Xcode 开启 Push Notifications capability，并使用包含 APS Environment 的签名配置后重装应用。";
    }
    gTokenRequestInFlight = NO;
    if (gSharedPlugin) {
        NSArray<NSString *> *callbacks = cty_drainPendingCallbacks();
        NSLog(@"CtyNotification: dispatching register error to %lu JS callback(s)", (unsigned long)callbacks.count);
        cty_emitJsConsole(YES, [NSString stringWithFormat:@"CtyNotification: dispatching register error to %lu JS callback(s)", (unsigned long)callbacks.count]);
        for (NSString *callbackId in callbacks) {
            CDVPluginResult *pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
            [gSharedPlugin.commandDelegate sendPluginResult:pr callbackId:callbackId];
        }
    }
}

// Perform method swizzling on the app delegate to capture APNs callbacks
- (void)swizzleAppDelegate {
    if (gSwizzled) return;
    id delegate = [UIApplication sharedApplication].delegate;
    if (!delegate) return;
    Class appDelegateClass = object_getClass(delegate);
    SEL selRegister = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
    SEL selFail = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);

    Method mReg = class_getInstanceMethod(appDelegateClass, selRegister);
    if (mReg) {
        gOriginalDidRegisterImp = method_getImplementation(mReg);
        method_setImplementation(mReg, (IMP)cty_didRegister);
    } else {
        class_addMethod(appDelegateClass, selRegister, (IMP)cty_didRegister, "v@:@@");
    }
    Method mFail = class_getInstanceMethod(appDelegateClass, selFail);
    if (mFail) {
        gOriginalDidFailImp = method_getImplementation(mFail);
        method_setImplementation(mFail, (IMP)cty_didFail);
    } else {
        class_addMethod(appDelegateClass, selFail, (IMP)cty_didFail, "v@:@@");
    }
    gSwizzled = YES;
}

- (void)pluginInitialize {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    NSLog(@"CtyNotification: pluginInitialize start");
    gSharedPlugin = self;
    [self swizzleAppDelegate];
}

// JS action wrappers (match names from CtyNotificationConstants.js)
- (void)bigImageNotification:(CDVInvokedUrlCommand*)command {
    [self bigImageNotice:command];
}

- (void)largeTextNotification:(CDVInvokedUrlCommand*)command {
    [self largeTextNotice:command];
}

- (void)importantNotification:(CDVInvokedUrlCommand*)command {
    [self importantNotice:command];
}

- (void)timedNotication:(CDVInvokedUrlCommand*)command {
    // Note: JS constant spelled 'timedNotication' (typo); delegate to timedNotice
    [self timedNotice:command];
}

// APNs/token handling removed: plugin no longer exposes getDeviceToken.

//请求通知权限
- (void) requestNotificationPermission:(void(^)(BOOL granted))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    NSLog(@"CtyNotification: requestNotificationPermission start");
    //检查当前权限状态
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSLog(@"CtyNotification: current notification settings: %ld", (long)settings.authorizationStatus);
        if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
            //权限未决定，申请权限
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge) 
                                  completionHandler:^(BOOL granted, NSError * _Nullable error) {
                NSLog(@"CtyNotification: requestAuthorization completion granted=%d error=%@", granted, error);
                if (granted) {
                    //权限获取成功，在主线程更新 UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"CtyNotification: permission granted");
                    });
                }
                completionHandler(granted);
            }];
        } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized || 
                   settings.authorizationStatus == UNAuthorizationStatusProvisional) {
            //权限已授予
            NSLog(@"CtyNotification: authorization already granted");
            completionHandler(YES);
        } else {
            //权限被拒绝
            NSLog(@"CtyNotification: authorization denied");
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

    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝，请在设置中启用通知权限"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        //通知内容
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.badge=@0;
        content.title=title;
        content.subtitle=subtitle;
        content.body=message;
        content.sound=[UNNotificationSound defaultSound];

        // 异步下载图片并在主线程调度通知（避免阻塞 UI）
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *imageURL = (urlBigImage && urlBigImage.length>0) ? [NSURL URLWithString:urlBigImage] : nil;
            NSData *imageData = nil;
            if (imageURL) {
                imageData = [NSData dataWithContentsOfURL:imageURL];
            }

            NSString *temporaryDirectory = NSTemporaryDirectory();
            NSString *imagePath = nil;
            UNNotificationAttachment *attachment = nil;

            if (imageData) {
                NSString *ext = imageURL.pathExtension;
                if (!ext || ext.length == 0) {
                    ext = @"jpg";
                }
                imagePath = [temporaryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cty_image_%@.%@", [[NSUUID UUID] UUIDString], ext]];
                BOOL ok = [imageData writeToFile:imagePath atomically:YES];
                if (ok) {
                    NSError *attErr = nil;
                    attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:&attErr];
                    if (attErr) {
                        NSLog(@"CtyNotification: attachment error=%@", attErr);
                        attachment = nil;
                    }
                }
            } else if (imageURL) {
                NSLog(@"CtyNotification: failed to download image for URL=%@", urlBigImage);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (attachment) {
                    content.attachments = @[attachment];
                }
                //简单延迟触发
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
                NSString* identifier = [NSUUID UUID].UUIDString;
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
                    }
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }];
            });
        });
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

// Exposed JS method to get device token from APNs
- (void)getDeviceToken:(CDVInvokedUrlCommand*)command {
    NSLog(@"CtyNotification: getDeviceToken called");
    cty_emitJsConsole(NO, @"CtyNotification: getDeviceToken called");
    [self swizzleAppDelegate];
    NSString *callbackId = command.callbackId;
    cty_addPendingCallback(callbackId);
    NSLog(@"CtyNotification: pending JS callbacks=%lu", (unsigned long)cty_pendingCallbackCount());
    cty_emitJsConsole(NO, [NSString stringWithFormat:@"CtyNotification: pending JS callbacks=%lu", (unsigned long)cty_pendingCallbackCount()]);

    if (gDeviceToken && gDeviceToken.length > 0) {
        CDVPluginResult *pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:gDeviceToken];
        [self.commandDelegate sendPluginResult:pr callbackId:callbackId];
        cty_removePendingCallback(callbackId);
        return;
    }

    // Request permission and register for remote notifications
    [self requestNotificationPermission:^(BOOL granted) {
        if (!granted) {
            CDVPluginResult *pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"通知权限被拒绝"]; 
            cty_emitJsConsole(YES, @"CtyNotification: getDeviceToken failed: 通知权限被拒绝");
            if (cty_removePendingCallback(callbackId)) {
                [self.commandDelegate sendPluginResult:pr callbackId:callbackId];
            }
            return;
        }
        if (!gTokenRequestInFlight) {
            gTokenRequestInFlight = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"CtyNotification: registerForRemoteNotifications start");
                cty_emitJsConsole(NO, @"CtyNotification: registerForRemoteNotifications start");
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        } else {
            NSLog(@"CtyNotification: registerForRemoteNotifications already in-flight, callback will wait");
            cty_emitJsConsole(NO, @"CtyNotification: registerForRemoteNotifications already in-flight, callback will wait");
        }

        // Set a timeout to fail if no token arrives
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDeviceTokenTimeoutSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (cty_removePendingCallback(callbackId)) {
                if (cty_pendingCallbackCount() == 0) {
                    gTokenRequestInFlight = NO;
                }
                NSLog(@"CtyNotification: getDeviceToken timeout callbackId=%@", callbackId);
                cty_emitJsConsole(YES, [NSString stringWithFormat:@"CtyNotification: getDeviceToken timeout callbackId=%@", callbackId]);
                CDVPluginResult *pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"获取 deviceToken 超时"];
                [self.commandDelegate sendPluginResult:pr callbackId:callbackId];
            }
        });
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
       
        // 异步下载图片并在完成后调度通知
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *imageURL=[NSURL URLWithString:urlBigImage];
            NSData *imageData = nil;
            if (imageURL) {
                imageData = [NSData dataWithContentsOfURL:imageURL];
            }

            NSString *temporaryDirectory = NSTemporaryDirectory();
            NSString *imagePath = nil;
            UNNotificationAttachment *attachment = nil;

            if (imageData) {
                NSString *ext = imageURL.pathExtension;
                if (!ext || ext.length == 0) {
                    ext = @"jpg";
                }
                imagePath = [temporaryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cty_image_%@.%@", [[NSUUID UUID] UUIDString], ext]];
                BOOL ok = [imageData writeToFile:imagePath atomically:YES];
                if (ok) {
                    NSError *attErr = nil;
                    attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:&attErr];
                    if (attErr) {
                        NSLog(@"CtyNotification: attachment error=%@", attErr);
                        attachment = nil;
                    }
                }
            } else {
                NSLog(@"CtyNotification: failed to download image for URL=%@", urlBigImage);
            }

            // 在主线程创建并添加通知请求
            dispatch_async(dispatch_get_main_queue(), ^{
                if (attachment) {
                    content.attachments = @[attachment];
                }
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
                NSString* identifier = [NSUUID UUID].UUIDString;
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
                    }
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }];
            });
        });
    }];
}

//定时通知
-(void)timedNotice:(CDVInvokedUrlCommand*)command {
    NSLog(@"CtyNotification: timedNotice called args count=%lu", (unsigned long)[command.arguments count]);
    
    if ([command.arguments count] < 10) {
        NSLog(@"CtyNotification: timedNotice insufficient args, expected 10 got %lu", (unsigned long)[command.arguments count]);
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Missing required arguments for timed notification"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
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
    
    if (!strDate || [strDate isEqualToString:@""]) {
        NSLog(@"CtyNotification: timedNotice strDate is nil or empty");
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"strDate cannot be empty"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    NSLog(@"CtyNotification: timedNotice validated: id=%@ title=%@ strDate=%@ interval=%@ repeat=%@ strType=%@", notificationId, title, strDate, interval, strRepeat, strType);

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

        BOOL repeats = [strRepeat boolValue];
        
        // 不在此同步下载图片，改为异步下载以避免无效附件 URL
        NSURL *imageURL = (urlBigImage && urlBigImage.length>0) ? [NSURL URLWithString:urlBigImage] : nil;

        //周期日历触发器   //设置通知触发时间  //设置通知触发时间  

        UNNotificationTrigger *trigger;

        if(repeats)
        {
            NSLog(@"CtyNotification: scheduling repeating trigger, interval=%@ repeats=%d", interval, repeats);
            int intValue=[interval intValue];
            // 如果 interval 为数字（秒）
            if(intValue!=0 || [interval isEqualToString:@"0"]) {
                if (intValue >= 60) {
                    // iOS 要求重复的 time interval >= 60 秒
                    trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(NSTimeInterval)intValue repeats:YES];
                } else {
                    // 无法使用重复的 timeInterval < 60s，退回到单次触发（并记录）
                    NSLog(@"CtyNotification: repeating timeInterval < 60s not supported by iOS, scheduling single occurrence");
                    trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(NSTimeInterval)intValue repeats:NO];
                }
            } else {
                // interval 是日期字符串，使用日历组件重复（例如每天/每月的固定时间）
                NSDate *nsIntervalDate = [dateFormatter dateFromString:interval];//间隔时间为日期时
                NSDateComponents *oneTime = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nsIntervalDate];
                trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:oneTime repeats:YES];
            }
        } else {
            NSLog(@"CtyNotification: scheduling single calendar trigger at %@", strDate);
            trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
        }
        // 异步下载图片并在主线程创建并添加通知请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UNNotificationAttachment *attachment = nil;
            if (imageURL) {
                NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                if (imageData) {
                    NSString *ext = imageURL.pathExtension;
                    if (!ext || ext.length == 0) ext = @"jpg";
                    NSString *temporaryDirectory = NSTemporaryDirectory();
                    NSString *imagePath = [temporaryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cty_image_%@.%@", [[NSUUID UUID] UUIDString], ext]];
                    BOOL ok = [imageData writeToFile:imagePath atomically:YES];
                    if (ok) {
                        NSError *attErr = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:&attErr];
                        if (attErr) {
                            NSLog(@"CtyNotification: attachment error=%@", attErr);
                            attachment = nil;
                        }
                    }
                } else {
                    NSLog(@"CtyNotification: failed to download image for URL=%@", urlBigImage);
                }
            }

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (attachment) {
                        content.attachments = @[attachment];
                    }
                    // If this is a repeating schedule, delegate to timedNoticeRepeat
                    // which will create the appropriate trigger and add the request.
                    if (repeats) {
                        [self timedNoticeRepeat:command];
                    } else {
                        //设置通知请求
                        //如果使用相同的[requestWithIdentifier]会一直覆盖之前的旧通知
                        NSString* identifier = [[NSUUID UUID] UUIDString];
                        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

                        //将通知添加到UNUserNotificationCenter中
                        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"CtyNotification: addNotificationRequest error=%@", error);
                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
                            } else {
                                NSLog(@"CtyNotification: addNotificationRequest success identifier=%@", identifier);
                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
                            }
                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                        }];
                    }
                });
        });
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
    NSInteger total = [command.arguments count] > 10 ? [[command.arguments objectAtIndex:10] integerValue] : 0;

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

        NSURL *imageURL = (urlBigImage && urlBigImage.length>0) ? [NSURL URLWithString:urlBigImage] : nil;

        //Create trigger with interval
        int intValue=[interval intValue];
        UNNotificationTrigger *trigger;
        BOOL useShortIntervalBatch = NO;

        //判断是否是Int值
        if(intValue!=0||[interval isEqualToString:@"0"]) {
            if (intValue >= 60) {
                trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(NSTimeInterval)intValue repeats:YES];
            } else {
                // iOS does not support repeats=YES for interval < 60s.
                // Use pre-queued one-shot notifications instead.
                NSLog(@"CtyNotification: interval < 60s, switching to pre-queued one-shot scheduling");
                useShortIntervalBatch = YES;
                trigger = nil;
            }
        } else {
            NSDate *nsIntervalDate = [dateFormatter dateFromString:interval];//间隔时间为日期时
            NSDateComponents *oneTime = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:nsIntervalDate];
            trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:oneTime repeats:YES];
        }

        // Attach metadata so short-interval repeats (<60s) can auto-reschedule
        NSMutableDictionary *ctyUserInfo = [NSMutableDictionary dictionary];
        [ctyUserInfo setObject:@(YES) forKey:@"cty_repeat"];
        if(intValue!=0||[interval isEqualToString:@"0"]) {
            [ctyUserInfo setObject:@(intValue) forKey:@"cty_interval"];
        } else {
            if (interval) [ctyUserInfo setObject:interval forKey:@"cty_interval_raw"];
        }
        [ctyUserInfo setObject:@(!useShortIntervalBatch) forKey:@"cty_reschedule"];
        if (notificationId) [ctyUserInfo setObject:notificationId forKey:@"cty_notificationId"];
        if (title) [ctyUserInfo setObject:title forKey:@"cty_title"];
        if (subtitle) [ctyUserInfo setObject:subtitle forKey:@"cty_subtitle"];
        if (message) [ctyUserInfo setObject:message forKey:@"cty_message"];
        if (strType) [ctyUserInfo setObject:strType forKey:@"cty_strType"];
        if (urlBigImage) [ctyUserInfo setObject:urlBigImage forKey:@"cty_urlBigImage"];
        content.userInfo = ctyUserInfo;

        // 异步下载图片并在主线程创建并添加通知请求
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UNNotificationAttachment *attachment = nil;
            if (imageURL) {
                NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                if (imageData) {
                    NSString *ext = imageURL.pathExtension;
                    if (!ext || ext.length == 0) ext = @"jpg";
                    NSString *temporaryDirectory = NSTemporaryDirectory();
                    NSString *imagePath = [temporaryDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"cty_image_%@.%@", [[NSUUID UUID] UUIDString], ext]];
                    BOOL ok = [imageData writeToFile:imagePath atomically:YES];
                    if (ok) {
                        NSError *attErr = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"imageAttachment" URL:[NSURL fileURLWithPath:imagePath] options:nil error:&attErr];
                        if (attErr) {
                            NSLog(@"CtyNotification: attachment error=%@", attErr);
                            attachment = nil;
                        }
                    }
                } else {
                    NSLog(@"CtyNotification: failed to download image for URL=%@", urlBigImage);
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (attachment) {
                    content.attachments = @[attachment];
                }
                UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                if (useShortIntervalBatch) {
                    // Pre-queue multiple one-shot notifications to emulate short-interval repeats in background.
                    // Use total if specified; otherwise default to 30.
                    NSInteger batchCount = (total > 0) ? total : 30;
                    NSDate *baseDate = nsDate ?: [NSDate dateWithTimeIntervalSinceNow:intValue > 0 ? intValue : 1];
                    for (NSInteger i = 0; i < batchCount; i++) {
                        NSDate *fireDate = [baseDate dateByAddingTimeInterval:(NSTimeInterval)(i * intValue)];
                        NSDateComponents *dc = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:fireDate];
                        UNCalendarNotificationTrigger *oneShot = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dc repeats:NO];

                        UNMutableNotificationContent *itemContent = [[UNMutableNotificationContent alloc] init];
                        itemContent.badge = @0;
                        itemContent.title = content.title ?: @"";
                        itemContent.subtitle = content.subtitle ?: @"";
                        itemContent.body = content.body ?: @"";
                        itemContent.sound = [UNNotificationSound defaultSound];
                        itemContent.userInfo = content.userInfo;
                        if (attachment) {
                            itemContent.attachments = @[attachment];
                        }

                        NSString *identifier = [NSString stringWithFormat:@"cty-short-%@-%ld", notificationId ?: @"0", (long)i];
                        UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:identifier content:itemContent trigger:oneShot];
                        [center addNotificationRequest:req withCompletionHandler:nil];
                    }
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    //设置通知请求
                    NSString* identifier = [[NSUUID UUID] UUIDString];
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"error: %@", error.description]];
                        } else {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"success"];
                        }
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }];
                }
            });
        });
        
        // NOTE: previously this block duplicated the addNotificationRequest call
        // (once inside the async block and once here). The async block delegates
        // to timedNoticeRepeat for repeating schedules; for non-repeating the
        // request is already added in the async completion above. Do not add
        // another request here to avoid duplicate notifications.
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
    NSDictionary *ui = notification.request.content.userInfo;
    if (ui && [ui[@"cty_reschedule"] boolValue]) {
        NSNumber *ival = ui[@"cty_interval"];
        if (ival && [ival intValue] > 0 && [ival intValue] < 60) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scheduleNextFromUserInfo:ui];
            });
        }
    }
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList);
    } else {
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    }
}

//当接收到通知，在用户点击通知激活应用程序时调用这个方法，无论是在前台还是后台
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary *ui = response.notification.request.content.userInfo;
    if (ui && [ui[@"cty_reschedule"] boolValue]) {
        NSNumber *ival = ui[@"cty_interval"];
        if (ival && [ival intValue] > 0 && [ival intValue] < 60) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scheduleNextFromUserInfo:ui];
            });
        }
    }
    completionHandler();
}



// Schedule the next occurrence for short-interval repeating notifications
- (void)scheduleNextFromUserInfo:(NSDictionary*)userInfo {
    NSNumber *ival = userInfo[@"cty_interval"];
    if (!ival) return;
    NSTimeInterval interval = [ival doubleValue];
    if (interval <= 0) return;

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = userInfo[@"cty_title"] ?: @"";
    content.subtitle = userInfo[@"cty_subtitle"] ?: @"";
    content.body = userInfo[@"cty_message"] ?: @"";
    content.sound = [UNNotificationSound defaultSound];
    content.userInfo = userInfo;

    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:interval repeats:NO];
    NSString* identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"CtyNotification: scheduleNextFromUserInfo error=%@", error);
        } else {
            NSLog(@"CtyNotification: scheduled next short-interval notification (identifier=%@) interval=%f", identifier, interval);
        }
    }];
}
@end
