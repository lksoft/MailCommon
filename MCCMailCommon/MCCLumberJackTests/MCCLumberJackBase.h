//
//  MCCLumberJackBase.h
//  MCCMailCommon
//
//  Created by Scott Little on 31/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface MCCLumberJackBase : XCTestCase

@property (strong) NSFileManager	*manager;
@property (strong) NSDateFormatter	*dateFormatter;

- (NSArray *)logMessages;
- (NSURL *)logTestFolderURL;

@end

#define MCCAssertLogEquals(s1, logMessage) \
	do { \
		NSMutableString	*adjustedTestString = [logMessage mutableCopy]; \
		[adjustedTestString replaceOccurrencesOfString:@"<****>" withString:@"<[*]{4}>" options:NSLiteralSearch range:NSMakeRange(0, [logMessage length])]; \
		NSString	*regPattern = [NSString stringWithFormat:@"\\[%@:[0-9]+ %@] . %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], NSStringFromSelector(_cmd), adjustedTestString]; \
		NSRegularExpression	*regEx = [NSRegularExpression regularExpressionWithPattern:regPattern options:0 error:NULL]; \
		NSUInteger	regExMatchCount = ([regEx numberOfMatchesInString:s1 options:0 range:NSMakeRange(0, [s1 length])]); \
		XCTAssertEqual(regExMatchCount, ((NSUInteger)1), @"'%@' != '%@'", s1, regPattern); \
	} while (0)

#define MCCAssertFirstLogEquals(logMessage) \
	do { \
		MCCAssertLogEquals(([[self logMessages] firstObject][@"contents"]), logMessage); \
	} while (0)
