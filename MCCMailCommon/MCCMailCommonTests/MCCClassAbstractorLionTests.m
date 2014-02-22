//
//  MCCClassAbstractorLionTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 20/1/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSTMailAbstractor.h"

@interface MCCClassAbstractorLionTests : XCTestCase
@property	(strong)	NSDictionary	*mappings;
@end

@implementation MCCClassAbstractorLionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	TSTMailAbstractor *abstractor = [TSTMailAbstractor sharedInstance];
	abstractor.testVersionOS = 7;
	[abstractor rebuildCurrentMappings];
	self.mappings = abstractor.mappings;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	self.mappings = nil;
    [super tearDown];
}

- (void)testMappingsExist {
	
	XCTAssertNotNil(self.mappings, @"");
	XCTAssertTrue([self.mappings count] > 0, @"");
	
}

- (void)testMavericksToLionMappings {
	
	XCTAssertNotNil(self.mappings[@"MFMessageDeliverer"], @"");
	XCTAssertEqualObjects(self.mappings[@"MFMessageDeliverer"], @"MailDelivery", @"");
	
	XCTAssertNotNil(self.mappings[@"MFSMTPDeliverer"], @"");
	XCTAssertEqualObjects(self.mappings[@"MFSMTPDeliverer"], @"SMTPDelivery", @"");
	
	XCTAssertNotNil(self.mappings[@"MFEWSDeliverer"], @"");
	XCTAssertEqualObjects(self.mappings[@"MFEWSDeliverer"], @"EWSDelivery", @"");

	XCTAssertNotNil(self.mappings[@"MFMailbox"], @"");
	XCTAssertEqualObjects(self.mappings[@"MFMailbox"], @"MailboxUid", @"");

	XCTAssertNotNil(self.mappings[@"RulesPreferences"], @"");
	XCTAssertEqualObjects(self.mappings[@"RulesPreferences"], @"MailSorterPreferences", @"");

	XCTAssertNotNil(self.mappings[@"MFSmartMailbox"], @"");
	XCTAssertEqualObjects(self.mappings[@"MFSmartMailbox"], @"SmartMailboxUid", @"");
}

- (void)testMountainLionToLionMappings {
	
	XCTAssertNil(self.mappings[@"MailDelivery"], @"");
	
	XCTAssertNil(self.mappings[@"SMTPDeliverer"], @"");
	
	XCTAssertNil(self.mappings[@"EWSDelivery"], @"");

	XCTAssertNil(self.mappings[@"MailDocumentEditor"], @"");
	
	XCTAssertNil(self.mappings[@"MailboxUid"], @"");
	
	XCTAssertNotNil(self.mappings[@"RulesPreferences"], @"");
	XCTAssertEqualObjects(self.mappings[@"RulesPreferences"], @"MailSorterPreferences", @"");
	
	XCTAssertNil(self.mappings[@"SmartMailboxUid"], @"");
}

//	Uses mappings defined in PluginClassMappings.plist
- (void)testClassesThatShouldExist {
	
	XCTAssertNotNil(CLS(MavsObject), @"");
	XCTAssertEqualObjects(CLS(MavsObject), [NSObject class], @"");
	
	XCTAssertNotNil(CLS(MLObject), @"");
	XCTAssertEqualObjects(CLS(MLObject), [NSObject class], @"");
	
	XCTAssertNil(CLS(LionObject), @"");
	
}

@end
