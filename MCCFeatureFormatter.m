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
	
	//	If the context is a feature formatting and there is a feature set, determine what to add
	if (self.featureMappings && (logMessage->logContext & MCCFeatureFormattingContext) && (logMessage->logFlag != 0)) {
		
		NSString	*featureName = self.featureMappings[@(logMessage->logFlag)];
		if (featureName) {
			//	Don't use the dereference that DDLog only allows for setting, since the memory management will get screwed up EVEN UNDER ARC
			NSString	*newString = [NSString stringWithFormat:@"[%@]: %@", featureName, logMessage->logMsg];
			[logMessage setValue:newString forKey:@"logMsg"];
		}
	}
	
	return [super formatLogMessage:logMessage];
}


@end

@implementation MCC_PREFIXED_NAME(LumberJack) (FeatureFormatter)

+ (void)addLogFeature:(int)newFeature {
	MCC_PREFIXED_NAME(DDLogFeatures) = (MCC_PREFIXED_NAME(DDLogFeatures) | newFeature);
}

@end
