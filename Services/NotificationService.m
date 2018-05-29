//
//  NotificationService.m
//  Services
//
//  Created by Bhadresh on 29/05/18.
//  Copyright © 2018 Bhadresh. All rights reserved.
//

#import "NotificationService.h"
#import <UIKit/UIKit.h>

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    //
    NSDictionary *userInfo = request.content.userInfo;
    if (userInfo == nil) {
        [self contentComplete];
        return;
    }
    NSString *mediaUrl = userInfo[@"image"];
    
    
    NSString * documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imgName = [[NSUUID UUID]UUIDString];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *writablePath = [documentsDirectoryPath stringByAppendingPathComponent:imgName];
    if(![fileManager fileExistsAtPath:writablePath]){
        // file doesn't exist
        NSLog(@"file doesn't exist");
        //save Image From URL
        NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString: mediaUrl]];
        
        NSError *error = nil;
        [data writeToFile:[documentsDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", imgName]] options:NSAtomicWrite error:&error];
        
        if (error) {
            NSLog(@"Error Writing File : %@",error);
            
        }else{
            NSLog(@"Image %@ Saved SuccessFully",imgName);
            UIImage *image = [UIImage imageWithData:data];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
    }
    else{
        // file exist
        NSLog(@"file exist");
        
    }
    
    // Modify the notification content here...
    // self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    // self.bestAttemptContent.title = [request.content.userInfo valueForKey:@"message"];
    
    
   
    // NSString *mediaUrl = @"https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/FloorGoban.JPG/1024px-FloorGoban.JPG";
    
    NSString *mediaType = [self fileExtensionForMediaType:mediaUrl];
    if (mediaUrl == nil) {
        [self contentComplete];
        return;
    }
    // load the attachment
    [self loadAttachmentForUrlString:mediaUrl
                            withType:mediaType
                   completionHandler:^(UNNotificationAttachment *attachment) {
                       if (attachment) {
                           self.bestAttemptContent.attachments = [NSArray arrayWithObject:attachment];
                       }
                       [self contentComplete];
                   }];
}
- (void)contentComplete {
    self.contentHandler(self.bestAttemptContent);
}
- (NSString *)fileExtensionForMediaType:(NSString *)stringUrl {
    NSString *ext = @"jpg";
    NSArray *arr = [stringUrl componentsSeparatedByString:@"/"];
    if (arr.count > 0) {
        NSString *str = [arr lastObject];
        NSArray *arr1 = [str componentsSeparatedByString:@"."];
        if (arr1.count > 0) {
            ext = [arr1 lastObject];
        }
    }
    return [NSString stringWithFormat:@".%@",ext];
}
- (void)loadAttachmentForUrlString:(NSString *)urlString withType:(NSString *)type completionHandler:(void(^)(UNNotificationAttachment *))completionHandler  {
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlString];
    NSString *fileExt = [self fileExtensionForMediaType:type];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil) {
                        NSLog(@"%@", error.localizedDescription);
                    } else {
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
                        [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
                        NSError *attachmentError = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                        if (attachmentError) {
                            NSLog(@"%@", attachmentError.localizedDescription);
                        }
                    }
                    completionHandler(attachment);
                }] resume];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
