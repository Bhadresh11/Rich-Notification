//
//  AppDelegate.m
//  Notification
//
//  Created by Bhadresh on 28/05/18.
//  Copyright © 2018 Bhadresh. All rights reserved.
//

#import "AppDelegate.h"

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

@import Firebase;
@import FirebaseInstanceID;
@import FirebaseMessaging;

// Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
// running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
// devices running iOS 10 and above.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
@end
#endif

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //Google Pluse login
    [self registerForRemoteNotification:application];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     [self connectToFcm];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)registerForRemoteNotification:(UIApplication *)application
{
    if(@available(iOS 10.0, *)){
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        UNNotificationAction *ActionBtn1 = [UNNotificationAction actionWithIdentifier:@"Kcategory" title:@"Kcategory1" options:UNNotificationActionOptionNone];
        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"category" actions:@[ActionBtn1] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
        
        NSSet *categories = [NSSet setWithObject:category];
        [center setNotificationCategories:categories];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
            if( !error ){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                    [FIRMessaging messaging].remoteMessageDelegate = self;
                });
            }
        }];
        
        
        
    }else{
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [[UIApplication sharedApplication] registerUserNotificationSettings:
             [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge |
                                                           UIRemoteNotificationTypeSound |
                                                           UIRemoteNotificationTypeAlert) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        else
        {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(                                                                                   UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
#else
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(                                                                               UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif
        // Override point for customization after application launch.
    }
    [FIRApp configure];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}
- (void)applicationReceivedRemoteMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"FIRMessagingRemoteMessage xxx:%@",remoteMessage.appData);
}
// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    // TODO: If necessary send token to application server.
}
// [START connect_to_fcm]
- (void)connectToFcm {
    // Won't connect since there is no  en
    if (![[FIRInstanceID instanceID] token]) {
        return;
    }
    // Disconnect previous FCM connection if it exists.
    [[FIRMessaging messaging] disconnect];
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    [[NSUserDefaults standardUserDefaults]setValue:refreshedToken forKey:@"FcmToken"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil){
            NSLog(@"Unable to connect to FCM. %@", error);
        }
        else{
            NSLog(@"Connected to FCM.");
        }
    }];
}
#pragma mark - Remote Notification Delegate // <= iOS 9.x

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

// [START receive_message]
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"QWQEWWQW %@", userInfo);
    // Print full message.
    [self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
    }];
}

-(void) application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler(UIBackgroundFetchResultNewData);
}
// [START ios_10_message_handling]
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"userInfo userInfo:%@", userInfo);
    
    if (@available(iOS 10.0, *)) {
        completionHandler(UNNotificationPresentationOptionAlert);
    } else {
        // Fallback on earlier versions
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    NSLog(@"withCompletionHandler:%@", userInfo);
   
    completionHandler();
}
// [START refresh_token]
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"FCM registration token: %@", fcmToken);
}
// [END refresh_token]
- (void)messaging:(FIRMessaging *)messaging didReceiveMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"Received data message: %@", remoteMessage.appData);
}
// [END ios_10_data_message]

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Unable to register for remote notifications: %@", error);
    [[NSUserDefaults standardUserDefaults]synchronize];
}
// This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
// If swizzling is disabled then this function must be implemented so that the APNs device token can be paired to
// the FCM registration token.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"APNs device token retrieved: %@", deviceToken);
    
}
@end
