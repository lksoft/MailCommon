//
//  MCCBugFormatter.m
//  Tealeaves
//
//  Created by Scott Little on 22/8/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCBugFormatter.h"


@implementation MCC_PREFIXED_NAME(BugFormatter)

- (instancetype)init {
	self = [super init];
	if (self) {
		self.dateFormatter = [NSDateFormatter new];
		[self.dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
		[self.dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
	}
	return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
	
	NSString	*bugName = @"";
	
	//	Only put a logLevelString, if this is not a bug context
	if (!(logMessage->logContext & MCCBugFormattingContext)) {
		return nil;
	}
	
	//	If the context is a bug formatting and there is a feature set, determine what to add
	if (self.featureMappings && (logMessage->logFlag != 0)) {
		if (self.featureMappings[@(logMessage->logFlag)]) {
			bugName = [NSString stringWithFormat:@" (%@)", self.featureMappings[@(logMessage->logFlag)]];
		}
	}
	
	NSString	*fileName = [[NSString stringWithUTF8String:logMessage->file] lastPathComponent];
    NSString	*dateAndTime = [self.dateFormatter stringFromDate:(logMessage->timestamp)];
    
	return [NSString stringWithFormat:@"%@ <Bug> [%@:%d %s]%@ | %@", dateAndTime, fileName, logMessage->lineNumber, logMessage->function, bugName, logMessage->logMsg];
}


@end

