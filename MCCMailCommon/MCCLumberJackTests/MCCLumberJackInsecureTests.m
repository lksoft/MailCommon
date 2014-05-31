//
//  MCCLumberJackInsecureTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 31/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCLumberJackBase.h"

@interface MCCLumberJackInsecureTests : MCCLumberJackBase

@end

@implementation MCCLumberJackInsecureTests

- (void)testSecuredLogWithInsecureLogFlag {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has secured info:*%@ and non-secured info:%@", @"Should Not Be Visible", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:Should Not Be Visible and non-secured info:Should Be Visible");
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end
