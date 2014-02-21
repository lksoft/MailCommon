//
//  MCCUtilitiesTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MCCUtilities.h"

@interface MCCUtilitiesTests : XCTestCase
@property (strong) 	TSTUtilities	*utils;
@end

@implementation MCCUtilitiesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	
	self.utils = [TSTUtilities sharedInstance];
	self.utils.bundle = [NSBundle bundleForClass:[self class]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	
	self.utils = nil;
    [super tearDown];
}

- (void)testBundlePath {
	XCTAssertEqualObjects(@"MCCMailCommonTests.xctest", [[self.utils.bundle bundlePath] lastPathComponent], @"");
}

- (void)testNonExistentKeyReturnsSame {
	XCTAssertEqualObjects(LOCALIZED(@"NON_EXISTENT_KEY"), @"NON_EXISTENT_KEY", @"");
}

- (void)testSimpleLocalization {
	XCTAssertEqualObjects(LOCALIZED(@"TEST1"), @"This is a simple test string", @"");
}

- (void)testSimpleFormatting {
	XCTAssertEqualObjects(LOCALIZED_FORMAT(@"TEST_FORMAT", @"value"), @"This string has a replaceable ‘value’", @"");
}

- (void)testOrderedFormatting {
	XCTAssertEqualObjects(LOCALIZED_FORMAT(@"TEST_FORMAT_2_PARAMS_A", @"one", @"two"), @"You can say one’s two", @"");
	XCTAssertEqualObjects(LOCALIZED_FORMAT(@"TEST_FORMAT_2_PARAMS_B", @"one", @"two"), @"But, I prefer to say the two of one", @"");
}

- (void)testSimpleTable {
	XCTAssertEqualObjects(LOCALIZED_TABLE(@"SNITCHER_FOUND", @"MCCUtilities"), @"‘%1$@’ found ‘%2$@’ Installed.", @"");
}

- (void)testOrderedTable {
	XCTAssertEqualObjects(LOCALIZED_TABLE_FORMAT(@"MCCUtilities", @"SNITCHER_FOUND", @"SignatureProfiler", @"Little Snitch"), @"‘SignatureProfiler’ found ‘Little Snitch’ Installed.", @"");
}


@end
