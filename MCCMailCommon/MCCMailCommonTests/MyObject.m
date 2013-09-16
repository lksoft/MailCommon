//
//  MyObject.m
//  MCCMailCommon
//
//  Created by Scott Little on 15/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import "MyObject.h"
#import "MCCMailAbstractor.h"
#import "MCCSwizzle.h"

@interface MyObject_TST : TSTSwizzle

@end

@interface TSTSwizzle (SuperDupping)
- (NSString *)additive;
- (NSString *)methodWithSuper;
@end

@implementation MyObject_TST

+ (void)load {
	[self makeSubclassOf:CLS(TSTObject)];
}

#define myself	((MyObject *)self)

- (NSString *)additive {
	NSString	*original = [super additive];
	return [NSString stringWithFormat:@"%@ - %@", original, @"Whoop-dee-do"];
}


- (NSString *)methodWithSuper {
	NSString	*original = SUPER();
	return [NSString stringWithFormat:@"%@ - %@", original, @"Whoop-dee-do"];
}

#undef myself

@end
