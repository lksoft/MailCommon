//
//  MCCMailAbstractor+MCCTesting.m
//  MCCMailCommon
//
//  Created by Scott Little on 15/6/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import "MCCMailAbstractor+MCCTesting.h"

@implementation TSTMailAbstractor (MCCTesting)

@dynamic testOSVersion;

- (void)setTestOSVersion:(NSInteger)testOSVersion {
	_testOSVersion = testOSVersion;
}

@end
