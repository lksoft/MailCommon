//
//  MCCDefaults.h
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

//	NOTE that this file also requires MCCFileEventQueue be in your project to watch for changes to the prefs file

#import "MCCCommonHeader.h"


//	This is an informal protocol for the delegate passed to the makeSharedDefaultsWithDelegate: method
@protocol MCC_PREFIXED_NAME(DefaultsDelegate) <NSObject>

@optional
- (void)finishPreparingDefaultsWithDictionary:(NSMutableDictionary *)defaults;
- (void)backupCurrentDefaultsBeforeWriteAtURL:(NSURL *)currentFileURL;

@end


@interface MCC_PREFIXED_NAME(Defaults) : NSObject

- (NSDictionary *)allDefaults;

+ (id)defaultForKey:(NSString *)key;
+ (id)objectForKey:(NSString *)key;
+ (BOOL)boolForKey:(NSString *)key;
+ (NSInteger)integerForKey:(NSString *)key;
+ (CGFloat)floatForKey:(NSString *)key;
+ (NSDictionary *)defaultsForKeys:(NSArray *)keys;

+ (id)launchDefaultForKey:(NSString *)key;
+ (BOOL)launchBoolForKey:(NSString *)key;

+ (void)setDefault:(id)value forKey:(NSString *)keys;
+ (void)setObject:(id)value forKey:(NSString*)key;
+ (void)setBool:(BOOL)value forKey:(NSString *)key;
+ (void)setInteger:(NSInteger)value forKey:(NSString *)key;
+ (void)setFloat:(CGFloat)value forKey:(NSString *)key;
+ (void)setDefaultsForDictionary:(NSDictionary *)newValues;

+ (instancetype)sharedDefaults;
+ (instancetype)makeSharedDefaultsWithDelegate:(id<MCC_PREFIXED_NAME(DefaultsDelegate)>)aDelegate;

@end
