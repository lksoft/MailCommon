//
//  MCCClassAbstractorNoMappingTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 3/6/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSTMailAbstractor.h"

@interface MCCClassAbstractorNoMappingTests : XCTestCase

@end

@implementation MCCClassAbstractorNoMappingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThrowsForNonSupportedOSVersion {

    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	TSTMailAbstractor *abstractor = [TSTMailAbstractor sharedInstance];
	abstractor.testVersionOS = 6;

	XCTAssertThrows([abstractor rebuildCurrentMappings], @"");
	
}

- (void)testNoMappingsForFutureOS {
	
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	TSTMailAbstractor *abstractor = [TSTMailAbstractor sharedInstance];

	//	The additional ones don't have 10 mappings
	abstractor.testVersionOS = 10;
	
	XCTAssertNoThrow([abstractor rebuildCurrentMappings], @"");
	
	XCTAssertNotNil(abstractor.mappings[@"DudeObject"], @"");
	XCTAssertEqualObjects(abstractor.mappings[@"DudeObject"], @"SubClass", @"");
	
}

- (void)testNoMappingsForFarFutureOS {
	
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	TSTMailAbstractor *abstractor = [TSTMailAbstractor sharedInstance];
	
	//	The additional ones don't have 10 mappings
	abstractor.testVersionOS = 20;
	
	XCTAssertThrows([abstractor rebuildCurrentMappings], @"");
	
	XCTAssertNil(abstractor.mappings[@"DudeObject"], @"");
	
}

@end
