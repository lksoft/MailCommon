//
//  MCCSparklePrefsController.h
//  MailCommon
//
//  Created by Scott Little on 1/7/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

@interface MCC_PREFIXED_NAME(SparklePrefsController) : NSObject

@property	(assign)	NSTimeInterval	checkInterval;
@property	(assign)			BOOL	enableAutomaticChecks;
@property	(assign)			BOOL	hasLaunchedBefore;
@property	(assign)			BOOL	sendProfileInfo;
@property	(strong, readonly)	NSDate	*lastCheckTime;

+ (MCC_PREFIXED_NAME(SparklePrefsController) *)sharedController;
- (void)ensureScriptInstallationAtPath:(NSString *)aScriptPath;

- (void)resetAll;
- (void)resetExceptInterval;
- (void)loadValues;
- (void)storeValues;

@end
