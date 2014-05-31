//
//  MCCFeatureFormatter.m
//  Tealeaves
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCFeatureFormatter.h"

int	MCC_PREFIXED_NAME(DDLogFeatures) = 0;


@implementation MCC_PREFIXED_NAME(FeatureFormatter)

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
	
	NSString	*featureName = @"";
	
	//	If the context is a feature formatting and there is a feature set, determine what to add
	if (self.featureMappings && (logMessage->logContext & MCCFeatureFormattingContext) && (logMessage->logFlag != 0)) {
		if (self.featureMappings[@(logMessage->logFlag)]) {
			featureName = [NSString stringWithFormat:@" (%@)", self.featureMappings[@(logMessage->logFlag)]];
		}
	}

	NSString	*fileName = [[NSString stringWithUTF8String:logMessage->file] lastPathComponent];
	NSString	*newMessage = [NSString stringWithFormat:@"[%@:%d %s]%@ | %@", fileName, logMessage->lineNumber, logMessage->function, featureName, logMessage->logMsg];
	[logMessage setValue:newMessage forKey:@"logMsg"];
	
	return [super formatLogMessage:logMessage];
}


@end

@implementation MCC_PREFIXED_NAME(LumberJack) (FeatureFormatter)

+ (void)addLogFeature:(int)newFeature {
	MCC_PREFIXED_NAME(DDLogFeatures) = (MCC_PREFIXED_NAME(DDLogFeatures) | newFeature);
}

@end
