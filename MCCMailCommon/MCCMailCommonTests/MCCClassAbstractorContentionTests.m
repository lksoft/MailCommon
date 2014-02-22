//
//  MCCClassAbstractorContentionTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSTMailAbstractor.h"
#import "SubClass.h"


@interface MCCClassAbstractorContentionTests : XCTestCase

@end


@implementation MCCClassAbstractorContentionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	NSLog(@"%@", [CLS(BaseClass) class]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBaseClass {
	XCTAssertEqualObjects(NSClassFromString(@"BaseClass"), CLS(BaseClass), @"");
	BaseClass	*base = [[BaseClass alloc] init];
	XCTAssertEqualObjects([base testMethod], @"swizzled", @"");
}

- (void)testSubClass {
	XCTAssertEqualObjects(NSClassFromString(@"SubClass"), CLS(SubClass), @"");
	SubClass	*sub = [[SubClass alloc] init];
	XCTAssertEqualObjects([sub testMethod], @"sub", @"");
}

@end
