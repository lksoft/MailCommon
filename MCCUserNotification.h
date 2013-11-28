//
//  MCCUserNotification.h
//  Tealeaves
//
//  Created by Scott Little on 28/11/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "MCCCommonHeader.h"

@interface MCC_PREFIXED_NAME(UserNotification) : NSObject

@property (copy) NSString *title;
@property (copy) NSString *subtitle;
//@property (copy) NSString *informativeText;
//@property (copy) NSString *actionButtonTitle;
//@property (copy) NSDictionary *userInfo;
//@property (copy) NSDate *deliveryDate;
//@property (copy) NSTimeZone *deliveryTimeZone;
//@property (copy) NSDateComponents *deliveryRepeatInterval;
//@property (readonly) NSDate *actualDeliveryDate;
//@property (readonly, getter=isPresented) BOOL presented;
//@property (readonly, getter=isRemote) BOOL remote;
//@property (copy) NSString *soundName;
@property BOOL hasActionButton;
//@property (readonly) NSUserNotificationActivationType activationType;
//@property (copy) NSString *otherButtonTitle;

@end


@interface MCC_PREFIXED_NAME(UserNotificationCenter) : NSObject

+ (instancetype)defaultUserNotificationCenter;

//@property (assign) id <NSUserNotificationCenterDelegate> delegate;
//@property (copy) NSArray *scheduledNotifications;
//
//- (void)scheduleNotification:(NSUserNotification *)notification;
//- (void)removeScheduledNotification:(NSUserNotification *)notification;

//@property (readonly) NSArray *deliveredNotifications;

- (void)deliverNotification:(MCC_PREFIXED_NAME(UserNotification) *)notification;
//- (void)removeDeliveredNotification:(NSUserNotification *)notification;
//- (void)removeAllDeliveredNotifications;

@end

@protocol MCC_PREFIXED_NAME(UserNotificationCenterDelegate) <NSObject>
@optional

//- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification;
//
//- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;
//
//- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification;

@end


@interface MCC_PREFIXED_NAME(UserNoteOperation) : NSOperation
- (instancetype)initWithUserNotification:(MCC_PREFIXED_NAME(UserNotification) *)aNotification notificationCenter:(MCC_PREFIXED_NAME(UserNotificationCenter) *)aCenter;
@end
