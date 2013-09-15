//
//  MCCMailCommonTests.m
//  MCCMailCommonTests
//
//  Created by Scott Little on 15/6/13.
//  Copyright (c) 2013 Scott Little. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSTObject.h"
#import "TSTObject+MCCSwizzle.h"

@interface MCCMailCommonTests : XCTestCase

@end

@implementation MCCMailCommonTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testNormalObject {
	TSTObject	*anObject = [[TSTObject alloc] init];
	
	XCTAssert([[anObject bar] isEqualToString:@"Original Bar"]);
	XCTAssert([anObject.testProp isEqualToString:@"Original PropValue"], @"Property Value is:%@", anObject.testProp);
}

- (void)testSwizzledObject {
	TSTObject	*anObject = [[TSTObject alloc] init];

	XCTAssert([[anObject foo] isEqualToString:@"A New Foo"]);
	XCTAssert([[anObject valueForKey:@"addedProp"] isEqualToString:@"One More PropValue"]);
	XCTAssert([anObject.addedProp isEqualToString:@"One More PropValue"]);
}

- (void)testSwizzledPropGetterDefined {
	TSTObject	*anObject = [[TSTObject alloc] init];
	
	XCTAssert([anObject.getterProp isEqualToString:@"This getter has a method"], @"GetterProp is %@", anObject.getterProp);
}

- (void)testSwizzledMethodSuperCalled {
	TSTObject	*anObject = [[TSTObject alloc] init];
	
	XCTAssert([[anObject additive] isEqualToString:@"Original Additive - this was added"], @"Additive is %@", [anObject additive]);
}

- (void)testSwizzledPropReadOnly {
	TSTObject	*anObject = [[TSTObject alloc] init];
	
	XCTAssert([anObject.readOnlyProp isEqualToString:@"Read Only Property"], @"readOnly is %@", anObject.readOnlyProp);
	XCTAssertFalse([anObject respondsToSelector:NSSelectorFromString(@"setReadOnlyProp:")]);
}

- (void)testSwizzledPropReadExternalOnly {
	TSTObject	*anObject = [[TSTObject alloc] init];
	
	XCTAssert([anObject.readOnlyExternalProp isEqualToString:@"Can Do"], @"readExternalOnly is %@", anObject.readOnlyExternalProp);
	XCTAssert([anObject respondsToSelector:NSSelectorFromString(@"setReadOnlyExternalProp:")]);
}

@end
