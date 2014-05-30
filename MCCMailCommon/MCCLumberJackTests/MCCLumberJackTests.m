//
//  MCCLumberJackTests.m
//  MCCLumberJackTests
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface MCCLumberJackTests : XCTestCase

@end

@implementation MCCLumberJackTests

- (void)testExample {
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This here is a log");
	MCCSecDebug(@"This here is a secure log:%@", @"Blah");
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

#pragma mark - Setup and Cleanup

- (void)setUp {
	
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	
	//	Flush any logs to be sure
	[DDLog flushLog];
	
	//	Remove any existing log files starting with the current bundleID from the path below
	//	/Users/scott/Library/Logs/xctest/
	NSError			*error = nil;
	NSString		*bundleID = [[NSBundle bundleForClass:[LBJLumberJack class]] bundleIdentifier];
	NSFileManager	*manager = [[NSFileManager alloc] init];
	NSMutableArray	*URLsToDelete = [NSMutableArray array];
	if ([manager fileExistsAtPath:[[self logTestFolderURL] path]]) {
		NSArray	*fileURLs = [manager contentsOfDirectoryAtURL:[self logTestFolderURL] includingPropertiesForKeys:@[NSURLNameKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
		if (fileURLs == nil) {
			NSLog(@"Could not get list of files: %@", error);
		}
		for (NSURL *aURL in fileURLs) {
			if ([[aURL lastPathComponent] hasPrefix:bundleID]) {
				[URLsToDelete addObject:aURL];
			}
		}
	}
	for (NSURL *aURL in URLsToDelete) {
		if (![manager removeItemAtURL:aURL error:&error]) {
			NSLog(@"Could not remove a file [%@]: %@", [aURL lastPathComponent], error);
		}
	}
	
	//	Reset the log level to a norm
	[LBJLumberJack setDebugLevel:LOG_LEVEL_VERBOSE];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	[DDLog removeAllLoggers];
    [super tearDown];
}

- (NSURL *)logTestFolderURL {

	NSURL	*theURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
	theURL = [[theURL URLByAppendingPathComponent:@"Logs"] URLByAppendingPathComponent:@"xctest"];
	
	return theURL;
}

@end
