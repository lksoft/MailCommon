//
//  BaseClass.m
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "BaseClass.h"

@implementation BaseClass

- (id)init {
	self = [super init];
	if (self) {
		//	nothing to see here
	}
	return self;
}

- (NSString *)testMethod {
	return @"test";
}

@end
