//
//  MCCLumberJackBase.m
//  MCCMailCommon
//
//  Created by Scott Little on 31/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCLumberJackBase.h"


@interface LBJLumberJack (TestingFeatureReset)
+ (void)resetLogFeature;
@end


@implementation MCCLumberJackBase

- (void)testFileCreated {
	[LBJLumberJack addStandardLoggersWithFeatureDict:nil];
	MCCLog(@"This here is a log");
	[DDLog flushLog];
	
	NSArray	*files = [self.manager contentsOfDirectoryAtURL:[self logTestFolderURL] includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
	XCTAssertEqual([files count], 1UL, @"");
}


#pragma mark - Helper Methods

- (NSArray *)logMessages {
	
	//	Ensure that all logs are written
	[DDLog flushLog];
	
	NSArray	*messages = nil;
	
	NSError	*error = nil;
	NSArray	*files = [self.manager contentsOfDirectoryAtURL:[self logTestFolderURL] includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
	
	if ([files count] == 1) {
		NSString	*fileContents = [NSString stringWithContentsOfURL:[files lastObject] encoding:NSUTF8StringEncoding error:&error];
		if (!fileContents) {
			XCTFail(@"Error reading file [%@] contents:%@", [files lastObject], error);
			return nil;
		}
		
		NSArray			*lines = [fileContents componentsSeparatedByString:@"\n"];
		NSMutableArray	*newMessages = [NSMutableArray arrayWithCapacity:[lines count]];
		for (NSString *aLine in lines) {
			if ([aLine length] > 25) {
				NSString	*dateString = [aLine substringToIndex:23];
				NSString	*contents = [aLine substringFromIndex:24];
				[newMessages addObject:@{@"date": [self.dateFormatter dateFromString:dateString], @"contents": contents}];
			}
			else {
				[newMessages addObject:@{@"date": [NSDate dateWithTimeIntervalSince1970:0], @"contents": aLine}];
			}
		}
		messages = [NSArray arrayWithArray:newMessages];
	}
	
	return messages;
}


#pragma mark - Setup and Cleanup

- (void)setUp {
	
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	
	//	Flush any logs to be sure
	[DDLog flushLog];
	
	//	Reset the log level and the Feature
	[LBJLumberJack setDebugLevel:LOG_LEVEL_VERBOSE];
	[LBJLumberJack resetLogFeature];
	
	//	Remove any existing log files starting with the current bundleID from the path below
	//	/Users/scott/Library/Logs/xctest/
	NSError			*error = nil;
	self.manager = [[NSFileManager alloc] init];
	if ([self.manager fileExistsAtPath:[[self logTestFolderURL] path]]) {
		NSArray	*fileURLs = [self.manager contentsOfDirectoryAtURL:[self logTestFolderURL] includingPropertiesForKeys:@[NSURLNameKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
		if (fileURLs == nil) {
			NSLog(@"Could not get list of files: %@", error);
		}
		for (NSURL *aURL in fileURLs) {
			if (![self.manager removeItemAtURL:aURL error:&error]) {
				NSLog(@"Could not remove a file [%@]: %@", [aURL lastPathComponent], error);
			}
		}
	}
	
	//	Create our date formatter once, if needed
	if (self.dateFormatter == nil) {
		self.dateFormatter = [[NSDateFormatter alloc] init];
		[self.dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
		[self.dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
	}
	
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
	[DDLog flushLog];
	[DDLog removeAllLoggers];
	self.manager = nil;
    [super tearDown];
}

- (NSURL *)logTestFolderURL {
	
	NSURL	*theURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
	theURL = [[theURL URLByAppendingPathComponent:@"Logs"] URLByAppendingPathComponent:@"xctest"];
	
	return theURL;
}


@end
