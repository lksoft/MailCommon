//
//  MCCFeatureFormatter.m
//  Tealeaves
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCFeatureFormatter.h"

int	MCC_PREFIXED_NAME(DDLogFeatures) = 0;

#define ERROR_TYPE		@"<Err>"
#define WARN_TYPE		@"<Warn>"
#define INFO_TYPE		@"<Info>"
#define DEBUG_TYPE		@"<Debug>"
#define VERBOSE_TYPE	@""


@implementation MCC_PREFIXED_NAME(FeatureFormatter)

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
	
	NSString	*featureName = @"";
	NSString	*logLevelString = VERBOSE_TYPE;
	
	//	If the context is a feature formatting and there is a feature set, determine what to add
	if (self.featureMappings && (logMessage->logContext & MCCFeatureFormattingContext) && (logMessage->logFlag != 0)) {
		if (self.featureMappings[@(logMessage->logFlag)]) {
			featureName = [NSString stringWithFormat:@" (%@)", self.featureMappings[@(logMessage->logFlag)]];
		}
	}
	
	//	Check for the level below is not there to set value
	if (!(logMessage->logLevel & LOG_LEVEL_VERBOSE)) {
		logLevelString = DEBUG_TYPE;
	}
	if (!(logMessage->logLevel & LOG_LEVEL_DEBUG)) {
		logLevelString = INFO_TYPE;
	}
	if (!(logMessage->logLevel & LOG_LEVEL_INFO)) {
		logLevelString = WARN_TYPE;
	}
	if (!(logMessage->logLevel & LOG_LEVEL_WARN)) {
		logLevelString = ERROR_TYPE;
	}
	
	NSString	*fileName = [[NSString stringWithUTF8String:logMessage->file] lastPathComponent];
    NSString	*dateAndTime = [self.dateFormatter stringFromDate:(logMessage->timestamp)];
    
	return [NSString stringWithFormat:@"%@ %@ [%@:%d %s]%@ | %@", dateAndTime, logLevelString, fileName, logMessage->lineNumber, logMessage->function, featureName, logMessage->logMsg];
}


@end

@implementation MCC_PREFIXED_NAME(LumberJack) (FeatureFormatter)

+ (void)addLogFeature:(int)newFeature {
	MCC_PREFIXED_NAME(DDLogFeatures) = (MCC_PREFIXED_NAME(DDLogFeatures) | newFeature);
}

@end
