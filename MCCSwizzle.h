//
//  MCCSwizzle.h
//  MailCommonCode
//
//  Created by Scott Little on 24/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

typedef enum MCC_PREFIXED_NAME(SwizzleType) {
	MCC_PREFIXED_NAME(SwizzleTypeNone),
	MCC_PREFIXED_NAME(SwizzleTypeNormal),
	MCC_PREFIXED_NAME(SwizzleTypeAdd)
} MCC_PREFIXED_NAME(SwizzleType);

typedef MCC_PREFIXED_NAME(SwizzleType)(^MCC_PREFIXED_NAME(SwizzleFilterBlock))(NSString *methodName);
typedef BOOL(^MCC_PREFIXED_NAME(AddIvarFilterBlock))(NSString *ivarName);


// rename class to avoid conflicts
@interface MCC_PREFIXED_NAME(Swizzle) : NSObject {
}
+ (Class)makeSubclassOf:(Class)baseClass usingClassName:(NSString*)subclassName;
+ (Class)makeSubclassOf:(Class)baseClass usingClassName:(NSString*)subclassName addIvarsPassingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))testBlock;

+ (void)swizzle;
+ (void)addMethodsPassingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock ivarsPassingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))ivarTestBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging;
+ (void)addAllMethodsToClass:(Class)targetClass usingPrefix:(NSString*)prefix;

@end

@interface MCC_PREFIXED_NAME(Swizzle) (Properties)
+ (void)swizzlePropertiesToClass:(Class)targetClass;
@end

//	Simple way to test most objects for emptyness
static inline BOOL IsEmpty(id thing) { return thing == nil || ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) || ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0); }
