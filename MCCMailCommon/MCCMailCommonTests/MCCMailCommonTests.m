//
//  MCCMailCommonTests.m
//  MCCMailCommonTests
//
//  Created by Scott Little on 15/6/13.
//  Copyright (c) 2013 Scott Little. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MCCMailAbstractor.h"
#import "TSTObject.h"
#import "TSTObject+MCCSwizzle.h"
#import "MyObject.h"

@interface MCCMailCommonTests : XCTestCase
@property	TSTObject	*simpleObject;
@property	MyObject	*subObject;
@end

@implementation MCCMailCommonTests

- (void)setUp {
    [super setUp];
    // Set-up code here.
	self.simpleObject = [[TSTObject alloc] init];
	self.subObject = [[CLS(MyObject) alloc] init];
}

- (void)tearDown {
    // Tear-down code here.
    self.simpleObject = nil;
	self.subObject = nil;
    [super tearDown];
}

- (void)testNormalObject {
	XCTAssert([[self.simpleObject bar] isEqualToString:@"Original Bar"]);
	XCTAssert([self.simpleObject.testProp isEqualToString:@"Original PropValue"], @"Property Value is:%@", self.simpleObject.testProp);
}

- (void)testSwizzledObject {
	XCTAssert([[self.simpleObject foo] isEqualToString:@"A New Foo"]);
	XCTAssert([[self.simpleObject valueForKey:@"addedProp"] isEqualToString:@"One More PropValue"]);
	XCTAssert([self.simpleObject.addedProp isEqualToString:@"One More PropValue"]);
}

- (void)testSwizzledPropGetterDefined {
	XCTAssert([self.simpleObject.getterProp isEqualToString:@"This getter has a method"], @"GetterProp is %@", self.simpleObject.getterProp);
}

- (void)testSwizzledMethodSuperCalled {
	XCTAssert([[self.simpleObject additive] isEqualToString:@"Original Additive - this was added"], @"Additive is %@", [self.simpleObject additive]);
}

- (void)testSwizzledPropReadOnly {
	XCTAssert([self.simpleObject.readOnlyProp isEqualToString:@"Read Only Property"], @"readOnly is %@", self.simpleObject.readOnlyProp);
	XCTAssertFalse([self.simpleObject respondsToSelector:NSSelectorFromString(@"setReadOnlyProp:")]);
}

- (void)testSwizzledPropReadExternalOnly {
	XCTAssert([self.simpleObject.readOnlyExternalProp isEqualToString:@"Can Do"], @"readExternalOnly is %@", self.simpleObject.readOnlyExternalProp);
	XCTAssert([self.simpleObject respondsToSelector:NSSelectorFromString(@"setReadOnlyExternalProp:")]);
}

- (void)testSubclassedSuperCalledWithException {
	XCTAssertThrows([self.subObject additive], @"Exception was not thrown when super called without the experimental flag.");
}

- (void)testSubclassedSuperFunctionCalled {
	XCTAssertNoThrow([self.subObject methodWithSuper], @"Exception was thrown when SUPER() macro called?!");
	XCTAssert([[self.subObject methodWithSuper] isEqualToString:@"A Value - Whoop-dee-do"], @"methodWithSuper is %@", [self.subObject methodWithSuper]);
}

@end


