//
//  MCCFileEventTests.m
//  MCCMailCommon
//
//  Created by Scott Little on 23/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MCCFileEventQueue.h"
#import "XCTAsyncTestCase.h"


@interface MCCFileEventTests : XCTAsyncTestCase
@property (strong) TSTFileEventQueue	*eventQueue;
@property (strong) NSURL				*tempFileURL;
@end


@implementation MCCFileEventTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	self.eventQueue = [[TSTFileEventQueue alloc] init];

	NSFileManager	*manager = [NSFileManager defaultManager];
	NSError			*error = nil;
	NSURL			*tempFolder = [manager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	
	XCTAssertNil(error, @"");
	
	tempFolder = [tempFolder URLByAppendingPathComponent:@"FileEventQueueTests"];
	XCTAssertTrue([manager createDirectoryAtURL:tempFolder withIntermediateDirectories:YES attributes:nil error:NULL], @"");
	
	NSString	*fileName = [NSString stringWithFormat:@"%@.txt", NSStringFromSelector(self.selector)];
	self.tempFileURL = [tempFolder URLByAppendingPathComponent:fileName];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	self.eventQueue = nil;
	[[NSFileManager defaultManager] removeItemAtURL:self.tempFileURL error:NULL];
    [super tearDown];
}

- (void)testNonAtomicChange {
	[self prepare];
	
	NSError			*error = nil;
	XCTAssertTrue([@"Original File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	MCCFileEventTests	*blockSelf = self;
	[self.eventQueue addPath:self.tempFileURL.path withBlock:^(TSTFileEventQueue *anEventQueue, NSString *aNote, NSString *anAffectedPath) {
		if ([anAffectedPath isEqualToString:blockSelf.tempFileURL.path]) {
			[blockSelf notify:kXCTUnitWaitStatusSuccess];
		}
		else {
			[blockSelf notify:kXCTUnitWaitStatusFailure];
		}
	} notifyingAbout:(MCCNotifyAboutFileWrite)];
	
	XCTAssertTrue([@"New File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	[self waitForStatus:kXCTUnitWaitStatusSuccess timeout:2.0];
}

- (void)testAtomicChange {
	[self prepare];
	
	NSError			*error = nil;
	XCTAssertTrue([@"Original File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	MCCFileEventTests	*blockSelf = self;
	[self.eventQueue addAtomicPath:self.tempFileURL.path withBlock:^(TSTFileEventQueue *anEventQueue, NSString *aNote, NSString *anAffectedPath) {
		if ([anAffectedPath isEqualToString:blockSelf.tempFileURL.path]) {
			[blockSelf notify:kXCTUnitWaitStatusSuccess];
		}
		else {
			[blockSelf notify:kXCTUnitWaitStatusFailure];
		}
	} notifyingAbout:(MCCNotifyAboutFileWrite | MCCNotifyAboutFileDelete)];
	
	XCTAssertTrue([@"New File Content" writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[self waitForStatus:kXCTUnitWaitStatusSuccess timeout:2.0];
}

- (void)testAtomicChangeWithSecondChange {
	[self prepare];
	
	NSError			*error = nil;
	XCTAssertTrue([@"Original File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	NSString			*secondString = @"Second Value Written";
	MCCFileEventTests	*blockSelf = self;
	[self.eventQueue addAtomicPath:self.tempFileURL.path withBlock:^(TSTFileEventQueue *anEventQueue, NSString *aNote, NSString *anAffectedPath) {
		NSString	*contents = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:anAffectedPath] encoding:NSUTF8StringEncoding error:NULL];
		
		if (contents == nil) {
			[blockSelf notify:kXCTUnitWaitStatusFailure];
		}
		
		if ([contents isEqualToString:secondString]) {
			[blockSelf notify:kXCTUnitWaitStatusSuccess];
		}
		
	} notifyingAbout:(MCCNotifyAboutFileWrite | MCCNotifyAboutFileDelete)];
	
	XCTAssertTrue([@"New File Content" writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	
	XCTAssertTrue([secondString writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[self waitForStatus:kXCTUnitWaitStatusSuccess timeout:3.0];
}

- (void)testAtomicChangeDoneWithoutAtomicDeclaration {
	[self prepare];
	
	NSError			*error = nil;
	XCTAssertTrue([@"Original File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	NSString			*secondString = @"Second Value Written";
	MCCFileEventTests	*blockSelf = self;
	[self.eventQueue addPath:self.tempFileURL.path withBlock:^(TSTFileEventQueue *anEventQueue, NSString *aNote, NSString *anAffectedPath) {
		NSString	*contents = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:anAffectedPath] encoding:NSUTF8StringEncoding error:NULL];
		
		if (contents == nil) {
			[blockSelf notify:kXCTUnitWaitStatusFailure];
		}
		
		if ([contents isEqualToString:secondString]) {
			[blockSelf notify:kXCTUnitWaitStatusSuccess];
		}
		
	} notifyingAbout:(MCCNotifyAboutFileWrite | MCCNotifyAboutFileDelete)];
	
	XCTAssertTrue([@"New File Content" writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[self.eventQueue readdPath:self.tempFileURL.path];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	
	XCTAssertTrue([secondString writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[self waitForStatus:kXCTUnitWaitStatusSuccess timeout:3.0];
}

- (void)testAtomicChangeDoneWithoutAtomicDeclarationNorReaddFails {
	[self prepare];
	
	NSError			*error = nil;
	XCTAssertTrue([@"Original File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	NSString			*secondString = @"Second Value Written";
	MCCFileEventTests	*blockSelf = self;
	[self.eventQueue addPath:self.tempFileURL.path withBlock:^(TSTFileEventQueue *anEventQueue, NSString *aNote, NSString *anAffectedPath) {
		NSString	*contents = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:anAffectedPath] encoding:NSUTF8StringEncoding error:NULL];
		
		if (contents == nil) {
			[blockSelf notify:kXCTUnitWaitStatusFailure];
		}
		
		if ([contents isEqualToString:secondString]) {
			[blockSelf notify:kXCTUnitWaitStatusSuccess];
		}
		
	} notifyingAbout:(MCCNotifyAboutFileWrite | MCCNotifyAboutFileDelete)];
	
	XCTAssertTrue([@"New File Content" writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	
	XCTAssertTrue([secondString writeToURL:self.tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error], @"");
	
	[self waitForTimeout:2.0];
}

- (void)testFileDeleted {
	[self prepare];
	
	NSError			*error = nil;
	XCTAssertTrue([@"Original File Content" writeToURL:self.tempFileURL atomically:NO encoding:NSUTF8StringEncoding error:&error], @"");
	
	MCCFileEventTests	*blockSelf = self;
	[self.eventQueue addPath:self.tempFileURL.path withBlock:^(TSTFileEventQueue *anEventQueue, NSString *aNote, NSString *anAffectedPath) {
		
		if ([aNote isEqualToString:TSTFileEventDeleteNotification]) {
			[blockSelf notify:kXCTUnitWaitStatusSuccess];
		}
		
	} notifyingAbout:(MCCNotifyAboutFileDelete)];
	
	[[NSFileManager defaultManager] removeItemAtURL:self.tempFileURL error:NULL];
	
	[self waitForStatus:kXCTUnitWaitStatusSuccess timeout:1.0];
}

@end
