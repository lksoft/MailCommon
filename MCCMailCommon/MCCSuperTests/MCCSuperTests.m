//
//  MCCSuperTests.m
//  MCCSuperTests
//
//  Created by Scott Little on 16/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MCCMailAbstractor.h"
#import "TSTObject.h"
#import "MyObject.h"

@interface MCCSuperTests : XCTestCase
@property	MyObject	*subObject;
@end

@implementation MCCSuperTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	self.subObject = [[CLS(MyObject) alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	self.subObject = nil;
    [super tearDown];
}

- (void)testSubclassedSuperCalled {
	XCTAssertNoThrow([self.subObject additive], @"Exception was thrown when super method called?!");
	XCTAssert([[self.subObject additive] isEqualToString:@"Original Additive - Whoop-dee-do"], @"methodWithSuper is %@", [self.subObject additive]);
}

- (void)testSubclassedSuperFunctionCalled {
	XCTAssertNoThrow([self.subObject methodWithSuper], @"Exception was thrown when SUPER() macro called?!");
	XCTAssert([[self.subObject methodWithSuper] isEqualToString:@"A Value - Whoop-dee-do"], @"methodWithSuper is %@", [self.subObject methodWithSuper]);
}


@end

