//
//  AASwizzledBaseClass.m
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "AASwizzledBaseClass.h"
#import "MCCSwizzle.h"
#import "MCCMailAbstractor.h"


@interface BaseClass_TST : TSTSwizzle

@end


@implementation BaseClass_TST

+ (void)load {
	[self swizzle];
	Class	aClass = CLS(DudeObject);	//	Should be translated to SubClass
	NSLog(@"Swizzled Base calling Subclass:%@", aClass);
}

+ (void)initialize {
}

- (NSString *)testMethod {
	return @"swizzled";
}

@end
