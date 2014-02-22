//
//  SubClass.m
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "SubClass.h"
#import "MCCMailAbstractor.h"

@implementation SubClass

+ (void)initialize {
	Class	base = CLS(BaseClass);
	NSLog(@"Sub's initialize got class for base:%@", base);
}

- (NSString *)testMethod {
	return @"sub";
}

@end
