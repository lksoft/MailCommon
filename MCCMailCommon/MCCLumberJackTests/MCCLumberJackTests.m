//
//  MCCLumberJackTests.m
//  MCCLumberJackTests
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCLumberJackBase.h"
#import "MCCFeatureFormatter.h"


@interface MCCLumberJackTests : MCCLumberJackBase
@end

@implementation MCCLumberJackTests


#pragma mark - Feature Logs

- (void)testFeatureNameLog {
	
	int	featureFlag = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureName"}];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeature(featureFlag, @"This here is a log");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a log", @"FeatureName");
}


#pragma mark - Standard Logs

- (void)testSimpleLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This here is a log");

	MCCAssertFirstLogEquals(@"This here is a log", VERBOSE_TYPE);
}

- (void)testInsecureLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has insecured info:%@", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has insecured info:Should Be Visible", VERBOSE_TYPE);
}

- (void)testSecureLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has secured info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:<****>", VERBOSE_TYPE);
}

- (void)testSecureAndUnsecuredLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has secured info:*%@ and insecured info:%@", @"Should Not Be Visible", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:<****> and insecured info:Should Be Visible", VERBOSE_TYPE);
}

- (void)testUnsecuredIntegerArgument {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has an integer value:%d", 42);
	
	MCCAssertFirstLogEquals(@"This log has an integer value:42", VERBOSE_TYPE);
}

- (void)testSecuredIntegerArgument {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has an integer value:*%d", 42);
	
	MCCAssertFirstLogEquals(@"This log has an integer value:<****>", VERBOSE_TYPE);
}


#pragma mark - Info Logs

- (void)testInsecureInfoLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCInfo(@"This log has insecured info:%@", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has insecured info:Should Be Visible", INFO_TYPE);
}

- (void)testSecureInfoLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCInfo(@"This log has secured info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:<****>", INFO_TYPE);
}


#pragma mark - Error Logs

- (void)testInsecureErrorLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCErr(@"This log has insecured info:%@", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has insecured info:Should Be Visible", ERROR_TYPE);
}

- (void)testSecureErrorLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCErr(@"This log has secured info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:<****>", ERROR_TYPE);
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
