//
//  MCCSwizzle.h
//  MailCommonCode
//
//  Created by Scott Little on 24/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#include "MCCCommonHeader.h"

typedef enum MCC_PREFIXED_NAME(SwizzleType) {
	MCC_PREFIXED_NAME(SwizzleTypeNone),
	MCC_PREFIXED_NAME(SwizzleTypeNormal),
	MCC_PREFIXED_NAME(SwizzleTypeAdd)
} MCC_PREFIXED_NAME(SwizzleType);

typedef NS_ENUM(NSInteger, MCC_PREFIXED_NAME(OSVersionValue)) {
	MCC_PREFIXED_NAME(OSVersionUnknown) = 0,
	MCC_PREFIXED_NAME(OSVersionLeopard) = 5,
	MCC_PREFIXED_NAME(OSVersionSnowLeopard),
	MCC_PREFIXED_NAME(OSVersionLion),
	MCC_PREFIXED_NAME(OSVersionMountainLion),
	MCC_PREFIXED_NAME(OSVersionMavericks)
};

typedef MCC_PREFIXED_NAME(SwizzleType)(^MCC_PREFIXED_NAME(SwizzleFilterBlock))(NSString *methodName);


// rename class to avoid conflicts
@interface MCC_PREFIXED_NAME(Swizzle) : NSObject

+ (void)swizzle;
+ (Class)makeSubclassOf:(Class)baseClass;
+ (void)addAllMethodsToClass:(Class)targetClass usingPrefix:(NSString*)prefix;
+ (void)addMethodsPassingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging;

@end

@interface MCC_PREFIXED_NAME(Swizzle) (Properties)
+ (void)swizzlePropertiesToClass:(Class)targetClass;
@end

//	Version information
MCC_PREFIXED_NAME(OSVersionValue) MCC_PREFIXED_NAME(OSVersion)(void);
#ifndef OSVERSION
#define OSVERSION MCC_PREFIXED_NAME(OSVersion)()
#endif

//	Macros to call the super of a method normally
#define SUPER_SELECTOR(selName,...)  objc_msgSendSuper(&(struct objc_super){self, class_getSuperclass([self class])},  @selector(selName) , ##__VA_ARGS__)
#define SUPER(...)  objc_msgSendSuper(&(struct objc_super){self, class_getSuperclass([self class])},_cmd, ##__VA_ARGS__)
