//
//  MCCUtilities.h
//  MCCMailCommon
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCCommonHeader.h"

extern NSString *const MCC_PREFIXED_CONSTANT(NetworkAvailableNotification);
extern NSString *const MCC_PREFIXED_CONSTANT(NetworkUnavailableNotification);
extern NSString *const MCC_PREFIXED_CONSTANT(NetworkInteractionRequiredNotification);

@interface MCC_PREFIXED_NAME(Utilities) : NSObject

@property (strong) NSBundle *bundle;
@property (strong) NSString *scriptPathComponent;
+ (BOOL)notifyUserAboutSnitchesForPluginName:(NSString *)pluginName domainList:(NSArray *)domains usingIcon:(NSImage *)iconImage;
+ (instancetype)sharedInstance;
+ (NSURL *)applicationScriptsURL;
+ (NSURL *)helperScriptURL;
+ (void)runHelperScriptWithArguments:(NSArray <NSString *> *)arguments completionHandler:(NSUserUnixTaskCompletionHandler)handler;
+ (BOOL)helperScriptIsAvailable;
+ (BOOL)debugInfoScriptIsAvailable;
+ (void)addPluginMenu:(NSArray <NSDictionary <NSString*, NSString*> *> *)menuInfo toMailMenuWithTitle:(NSString *)pluginName target:(id)target;

#ifndef MCC_NO_EXTERNAL_OBJECTS

@property (atomic) BOOL		hasInternetConnection;

+ (BOOL)networkReachable;
+ (BOOL)reachabilityForInternetConnection;
+ (void)startTrackingReachabilityUsingHostName:(NSString *)hostName;
+ (void)runDebugInfoScriptUsingView:(NSView *)targetView;
#endif

@end


#define LOCALIZED(key)	NSLocalizedStringFromTableInBundle(key, nil, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @"")
#define LOCALIZED_TABLE(key, table)	NSLocalizedStringFromTableInBundle(key, table, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @"")
#define LOCALIZED_FORMAT(key, ...)	([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(key, nil, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @""), __VA_ARGS__])
#define LOCALIZED_TABLE_FORMAT(table, key, ...)	([NSString stringWithFormat:NSLocalizedStringFromTableInBundle(key, table, [MCC_PREFIXED_NAME(Utilities) sharedInstance].bundle, @""), __VA_ARGS__])


//	Simple way to test most objects for emptyness
static inline BOOL MCC_PREFIXED_NAME(IsEmpty)(id thing) { return thing == nil || [thing isEqual:[NSNull null]] || ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) || ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0); }

#define IS_EMPTY(value)	(MCC_PREFIXED_NAME(IsEmpty(value)))
#define IS_NOT_EMPTY(value)	(!MCC_PREFIXED_NAME(IsEmpty(value)))
#define NONNIL(x)	((x == nil)?@"":x)

#define THREAD_DICT		([[NSThread currentThread] threadDictionary])

#define MCCLogPluginVersion(pluginInfoDict) \
NSString	*MCCPluginVersionInformation = nil; \
do { \
	MCCPluginVersionInformation = [NSString stringWithFormat:@"\n\t\tLoaded ‘%@’ %@ (%@) by SmallCubed\n\t\tBuild [%@:%@]", \
							  pluginInfoDict[@"CFBundleName"], pluginInfoDict[@"CFBundleShortVersionString"], pluginInfoDict[@"CFBundleVersion"], pluginInfoDict[@"SCBuildBranch"], pluginInfoDict[@"SCBuildSHA"]]; \
	NSLog (@"%@", MCCPluginVersionInformation); \
} while (NO);

typedef NS_ENUM(NSInteger, MCC_PREFIXED_NAME(OSVersionValue)) {
	MCC_PREFIXED_NAME(OSVersionUnknown) = 0,
	MCC_PREFIXED_NAME(OSVersionLeopard) = 5,
	MCC_PREFIXED_NAME(OSVersionSnowLeopard),
	MCC_PREFIXED_NAME(OSVersionLion),
	MCC_PREFIXED_NAME(OSVersionMountainLion),
	MCC_PREFIXED_NAME(OSVersionMavericks),
	MCC_PREFIXED_NAME(OSVersionYosemite),
	MCC_PREFIXED_NAME(OSVersionElCapitan),
	MCC_PREFIXED_NAME(OSVersionSierra),
	MCC_PREFIXED_NAME(OSVersionHighSierra),
	MCC_PREFIXED_NAME(OSVersionMojave),
    MCC_PREFIXED_NAME(OSVersionCatalina)
};

//	Version information
MCC_PREFIXED_NAME(OSVersionValue) MCC_PREFIXED_NAME(OSVersion)(void);
#ifndef OSVERSION
#define OSVERSION MCC_PREFIXED_NAME(OSVersion)()
#endif
CGFloat MCC_PREFIXED_NAME(OSVersionFull)(void);
#ifndef OSVERSIONWITHPOINT
#define OSVERSIONWITHPOINT MCC_PREFIXED_NAME(OSVersionFull)()
#endif

