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

@implementation MyObject_TST

+ (void)load {
	[self makeSubclassOf:TSTClassFromString(@"TSTObject") usingClassName:@"MyObject"];
}

#define myself	((MyObject *)self)

#undef myself

@end
