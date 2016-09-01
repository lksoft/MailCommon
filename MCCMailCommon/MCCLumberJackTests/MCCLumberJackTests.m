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

- (void)testFeatureNameLevelInfoLog {
	
	int	featureFlag = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureName"}];
	[LBJLumberJack setDebugLevel:LOG_LEVEL_INFO];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeature(featureFlag, @"This here is a log");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a log", @"FeatureName");
}

- (void)testFeatureNotOn {
	
	int	featureFlag = (1 << 0);
	int	featureFlag2 = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureNameOne", @(featureFlag2): @"FeatureNameTwo"}];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeature(featureFlag2, @"This here is a log");

	//	No log should have been outputted
	XCTAssertNil([self logMessages], @"Log Output was Created");
}

- (void)testOneOfTwoFeatureLog {
	
	int	featureFlag = (1 << 0);
	int	featureFlag2 = (1 << 1);
	int	featureFlag3 = (1 << 2);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureNameOne", @(featureFlag2): @"FeatureNameTwo", @(featureFlag3): @"FeatureNameThree"}];
	[LBJLumberJack addLogFeature:featureFlag3];
	MCCLogFeature(featureFlag, @"This here is a feature log");
	MCCLogFeature(featureFlag2, @"This here is a feature two log");
	MCCLogFeature(featureFlag3, @"This here is a feature three log");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a feature three log", @"FeatureNameThree");
}

- (void)testSecureFeatureNameLog {
	
	int	featureFlag = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureName"}];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeatureS(featureFlag, @"This here is a log with secure info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a log with secure info:<****>", @"FeatureName");
}

- (void)testSecureFeatureNameLogAsInsecure {
	
	int	featureFlag = (1 << 1);
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:@{@(featureFlag): @"FeatureName"}];
	[LBJLumberJack addLogFeature:featureFlag];
	MCCLogFeature(featureFlag, @"This here is a log with secure info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstFeatureLogEquals(@"This here is a log with secure info:\\*Should Not Be Visible", @"FeatureName");
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
	MCCLogS(@"This log has secured info:*%@", @"Should Not Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:<****>", VERBOSE_TYPE);
}

- (void)testSecureAndUnsecuredLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLogS(@"This log has secured info:*%@ and insecured info:%@", @"Should Not Be Visible", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has secured info:<****> and insecured info:Should Be Visible", VERBOSE_TYPE);
}

- (void)testUnsecuredIntegerArgument {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has an integer value:%d", 42);
	
	MCCAssertFirstLogEquals(@"This log has an integer value:42", VERBOSE_TYPE);
}

- (void)testSecuredIntegerArgument {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLogS(@"This log has an integer value:*%d", 42);
	
	MCCAssertFirstLogEquals(@"This log has an integer value:<****>", VERBOSE_TYPE);
}

- (void)testUnsecuredFloatArgument {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has a float value:%4.2f", 42.314);
	
	MCCAssertFirstLogEquals(@"This log has a float value:42.31", VERBOSE_TYPE);
}

- (void)testSecuredFloatArgument {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLogS(@"This log has a float value:*%4.2f", 42.314);
	
	MCCAssertFirstLogEquals(@"This log has a float value:<****>", VERBOSE_TYPE);
}


#pragma mark - Secure Passed as Insecure

- (void)testStringPassedAsSecureToInsecure {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has a string value:*%@", @"Should Show Up");
	
	MCCAssertFirstLogEquals(@"This log has a string value:\\*Should Show Up", VERBOSE_TYPE);
}

- (void)testStringPassedAsSecureToInsecureAlsoInsecure {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has a string value:*%@ and this is not marked:%@", @"Should Show Up", @"Here Too");
	
	MCCAssertFirstLogEquals(@"This log has a string value:\\*Should Show Up and this is not marked:Here Too", VERBOSE_TYPE);
}

- (void)testFloatPassedAsSecureToInsecure {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This log has a float value:*%4.3f", 42.31415);
	
	MCCAssertFirstLogEquals(@"This log has a float value:\\*42.314", VERBOSE_TYPE);
}


#pragma mark - Info Logs

- (void)testInsecureInfoLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCInfo(@"This log has insecured info:%@", @"Should Be Visible");
	
	MCCAssertFirstLogEquals(@"This log has insecured info:Should Be Visible", INFO_TYPE);
}

- (void)testSecureInfoLog {
	
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCInfoS(@"This log has secured info:*%@", @"Should Not Be Visible");
	
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
	MCCErrS(@"This log has secured info:*%@", @"Should Not Be Visible");
	
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
