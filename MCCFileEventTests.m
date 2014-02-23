//
//  MCCFileEventTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 23/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MCCFileEvent.h"

@interface MCCFileEventTests : XCTestCase
@property (strong) TSTFileEvent	*eventQueue;
@end

@implementation MCCFileEventTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	self.eventQueue = [[TSTFileEvent alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	self.eventQueue = nil;
    [super tearDown];
}

- (void)testExample {
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
