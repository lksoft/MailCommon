//
//  MCCSeparatorTests.m
//  MCCSeparatorTests
//
//  Created by Scott Little on 15/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MCCMailAbstractor.h"

#import "AnotherObject.h"
#import "AnotherObject_TST.h"

NSInteger	osMinorVersion(void);


@interface MCCSeparatorTests : XCTestCase
@property	AnotherObject	*testObject;
@end

@implementation MCCSeparatorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	
	self.testObject = [[AnotherObject alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	self.testObject = nil;
    [super tearDown];
}

- (void)testSwizzledObjectUsingDifferentSeparators {
	XCTAssert([[self.testObject additive] isEqualToString:@"Original Additive - and some more"], @"Additive is %@", [self.testObject additive]);
}


@end


