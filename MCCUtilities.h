//
//  MCCUtilities.h
//  MCCMailCommon
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

@interface MCC_PREFIXED_NAME(Utilities) : NSObject

@property (strong) NSBundle	*bundle;

+ (BOOL)notifyUserAboutSnitchesForPluginName:(NSString *)pluginName domainList:(NSArray *)domains usingIcon:(NSImage *)iconImage;
+ (instancetype)sharedInstance;
@end


#define LOCALIZED(key)	NSLocalizedStringFromTableInBundle(key, nil, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @"")
#define LOCALIZED_TABLE(key, table)	NSLocalizedStringFromTableInBundle(key, table, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @"")
#define LOCALIZED_FORMAT(key, ...)	([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(key, nil, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @""), __VA_ARGS__])
#define LOCALIZED_TABLE_FORMAT(table, key, ...)	([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(key, table, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @""), __VA_ARGS__])


//	Simple way to test most objects for emptyness
static inline BOOL MCC_PREFIXED_NAME(IsEmpty)(id thing) { return thing == nil || ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) || ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0); }

#define IS_EMPTY(value)	(MCC_PREFIXED_NAME(IsEmpty(value)))
#define NONNIL(x)	((x == nil)?@"":x)




