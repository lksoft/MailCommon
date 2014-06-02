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
	
	//	Only put a logLevelString, if this is not a feature context
	if (!(logMessage->logContext & MCCFeatureFormattingContext)) {
		//	Check for the level below is not there to set value
		if (logMessage->logFlag & LOG_FLAG_DEBUG) {
			logLevelString = DEBUG_TYPE;
		}
		else if (logMessage->logFlag & LOG_FLAG_ERROR) {
			logLevelString = ERROR_TYPE;
		}
		else if (logMessage->logFlag & LOG_FLAG_INFO) {
			logLevelString = INFO_TYPE;
		}
		else if (logMessage->logFlag & LOG_FLAG_WARN) {
			logLevelString = WARN_TYPE;
		}
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
