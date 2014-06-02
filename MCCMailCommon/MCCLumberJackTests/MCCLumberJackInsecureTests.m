//
//  MCCLumberJackInsecureTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 31/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCLumberJackBase.h"
#import "MCCFeatureFormatter.h"

@interface MCCLumberJackInsecureTests : MCCLumberJackBase

@end

@implementation MCCLumberJackInsecureTests


#pragma mark - Tests

- (void)testSecuredLogWithInsecureLogFlag {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLogS(@"This log has secured info:*%@ and non-secured info:%@", @"Should Not Be Visible", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:\\*Should Not Be Visible and non-secured info:Should Be Visible", VERBOSE_TYPE);
}

- (void)testSecureFeatureNameLog {
	
	int	featureFlag = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureName"}];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeatureS(featureFlag, @"This here is a log with secure info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a log with secure info:\\*Should Not Be Visible", @"FeatureName");
}

- (void)testSecureFeatureNameLogAsInsecure {
	
	int	featureFlag = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureName"}];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeature(featureFlag, @"This here is a log with secure info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a log with secure info:\\*Should Not Be Visible", @"FeatureName");
}

#pragma mark - Non-Verbose Logs

- (void)testSecureInfoLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCInfoS(@"This log has secured info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:\\*Should Not Be Visible", INFO_TYPE);
}

- (void)testSecureErrorLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCErrS(@"This log has secured info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:\\*Should Not Be Visible", ERROR_TYPE);
}


#pragma mark - Setup 

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end
