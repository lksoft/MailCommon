//
//  MCCLumberJack.m
//  MailCommon
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCLumberJack.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"
#import "MCCSecuredFormatter.h"
#import "MCCBundleFileManager.h"

#ifdef DEBUG
	int	MCC_PREFIXED_NAME(DDDebugLevel) = ((int)LOG_LEVEL_VERBOSE);
#else
	int	MCC_PREFIXED_NAME(DDDebugLevel) = ((int)LOG_LEVEL_INFO);
#endif


@implementation MCC_PREFIXED_NAME(LumberJack)


#pragma mark - Helper Creation

+ (void)addStandardLoggersWithFeatureDict:(NSDictionary *)featureDict {

	//	Set up the logging
	MCC_PREFIXED_NAME(BundleFileManager)	*bundleFileManager = [[MCC_PREFIXED_NAME(BundleFileManager) alloc] init];
	DDFileLogger		*fileLogger = [[DDFileLogger alloc] initWithLogFileManager:bundleFileManager];
	MCC_PREFIXED_NAME(SecuredFormatter)	*secureFormatter = [[MCC_PREFIXED_NAME(SecuredFormatter) alloc] init];
	secureFormatter.featureMappings = featureDict;
	[fileLogger setLogFormatter:secureFormatter];
	[DDLog addLogger:fileLogger withLogLevel:INT32_MAX];
#ifdef DEBUG
	//	Will log everything to Xcode console
	[DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:INT32_MAX];
#endif

}


#pragma mark - Level Settings

+ (int)debugLevel {
	return MCC_PREFIXED_NAME(DDDebugLevel);
}

+ (void)setDebugLevel:(int)newLevel {
	MCC_PREFIXED_NAME(DDDebugLevel) = newLevel;
}

@end
