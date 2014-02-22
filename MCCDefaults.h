//
//  MCCDefaults.h
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCCommonHeader.h"


@protocol MCC_PREFIXED_NAME(DefaultsDelegate) <NSObject>

@optional
- (void)finishPreparingDefaultsWithDictionary:(NSMutableDictionary *)defaults;
- (void)backupCurrentDefaultsBeforeWriteAtURL:(NSURL *)currentFileURL;

@end


@interface MCC_PREFIXED_NAME(Defaults) : NSObject

@property (strong, atomic, readonly) NSDictionary	*defaultDictionary;
@property (strong) NSString							*defaultsBundleID;
@property (assign) NSTimeInterval					readInterval;
@property (assign) id								delegate;

+ (id)defaultForKey:(NSString *)key;
+ (id)objectForKey:(NSString *)key;
+ (BOOL)boolForKey:(NSString *)key;
+ (NSInteger)integerForKey:(NSString *)key;
+ (CGFloat)floatForKey:(NSString *)key;
+ (NSDictionary *)defaultsForKeys:(NSArray *)keys;

+ (void)setDefault:(id)value forKey:(NSString *)keys;
+ (void)setObject:(id)value forKey:(NSString*)key;
+ (void)setBool:(BOOL)value forKey:(NSString *)key;
+ (void)setInteger:(NSInteger)value forKey:(NSString *)key;
+ (void)setFloat:(CGFloat)value forKey:(NSString *)key;
+ (void)setDefaultsForDictionary:(NSDictionary *)newValues;

+ (void)resetCache;
+ (instancetype)sharedDefaults;
+ (instancetype)sharedDefaultsWithDelegate:(id)aDelegate;

@end
