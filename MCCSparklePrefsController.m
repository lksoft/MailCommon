//
//  MCCSparklePrefsController.m
//  MailCommon
//
//  Created by Scott Little on 1/7/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "MCCSparklePrefsController.h"
#import	"MPTPluginMacros.h"

#define SCRIPT_FOLDER	@"Application Scripts"
#define SCRIPT_NAME		@"SparklePrefs"
#define SCRIPT_EXT		@"scpt"

#define FORMAT			@"%@ = %@; "
#define QUOTED_FORMAT	@"%@ = '%@'; "

#define SPARKLE_ENABLE_KEY			@"SUEnableAutomaticChecks"
#define SPARKLE_HAS_LAUNCHED_KEY	@"SUHasLaunchedBefore"
#define SPARKLE_SEND_PROFILE_KEY	@"SUSendProfileInfo"
#define SPARKLE_LAST_CHECK_TIME_KEY	@"SULastCheckTime"
#define SPARKLE_CHECK_INTERVAL_KEY	@"SUScheduledCheckInterval"

#define HOURLY_CHECK_INTERVAL	(60*60)
#define DAILY_CHECK_INTERVAL	(HOURLY_CHECK_INTERVAL*24)
#define WEEKLY_CHECK_INTERVAL	(DAILY_CHECK_INTERVAL*7)

@interface MCC_PREFIXED_NAME(SparklePrefsController) ()
@property	(strong)	NSString	*scriptPath;
@property	(strong)	NSString	*lastCheckAsString;

- (NSString *)defaultsStringRepresentation;
@end

@implementation MCC_PREFIXED_NAME(SparklePrefsController)

- (id)init {
	self = [super init];
	if (self) {
		[self resetAll];
		self.scriptPath = nil;
	}
	
	return self;
}

+ (MCC_PREFIXED_NAME(SparklePrefsController) *)sharedController {
	static	MCC_PREFIXED_NAME(SparklePrefsController)	*theController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theController = [[self alloc] init];
	});
	return theController;
}

- (void)ensureScriptInstallationAtPath:(NSString *)aScriptPath {

	//	If it is not a full path, get base script location
	NSAssert([aScriptPath hasPrefix:@"/"] == NO, @"Script path passed to ensureScriptInstallationAtPath:('%@') should be relative.", aScriptPath);
	NSAssert((aScriptPath != nil), @"The partial path passed to ensureScriptInstallationAtPath: cannot be nil");
	
	NSString		*scriptFileName = [SCRIPT_NAME stringByAppendingPathExtension:SCRIPT_EXT];
	self.scriptPath = [[[[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SCRIPT_FOLDER] stringByAppendingPathComponent:@"com.apple.mail"] stringByExpandingTildeInPath] stringByAppendingPathComponent:aScriptPath] stringByAppendingPathComponent:scriptFileName];

	NSFileManager	*fileManager = [[[NSFileManager alloc] init] autorelease];
	if (![fileManager fileExistsAtPath:self.scriptPath]) {
		//	Ask MPT to install the script and run it
		NSString *internalScriptPath = [[[self class] bundle] pathForResource:SCRIPT_NAME ofType:SCRIPT_EXT];
		MPTInstallScript([[self class] bundle], internalScriptPath, aScriptPath);
	}
}

- (void)resetAll {
	self.checkInterval = WEEKLY_CHECK_INTERVAL;
	self.enableAutomaticChecks = YES;
	self.hasLaunchedBefore = NO;
	self.sendProfileInfo = YES;
	self.lastCheckAsString = nil;
}

- (void)resetExceptInterval {
	NSTimeInterval	previousInterval = self.checkInterval;
	[self resetAll];
	if (previousInterval >= HOURLY_CHECK_INTERVAL) {
		self.checkInterval = previousInterval;
	}
}

- (void)loadValues {
	
}

- (void)storeValues {

}

- (NSString *)defaultsStringRepresentation {
	NSMutableString	*newString = [NSMutableString string];
	[newString appendString:@"{ "];
	
	[newString appendFormat:FORMAT, SPARKLE_ENABLE_KEY, @(self.enableAutomaticChecks)];
	[newString appendFormat:FORMAT, SPARKLE_SEND_PROFILE_KEY, @(self.sendProfileInfo)];
	[newString appendFormat:FORMAT, SPARKLE_CHECK_INTERVAL_KEY, @(self.checkInterval)];
	
	if (self.hasLaunchedBefore) {
		[newString appendFormat:FORMAT, SPARKLE_HAS_LAUNCHED_KEY, @1];
	}
	
	if (self.lastCheckAsString) {
		[newString appendFormat:QUOTED_FORMAT, SPARKLE_LAST_CHECK_TIME_KEY, self.lastCheckAsString];
	}
	
	[newString appendString:@" }"];
	
	return [NSString stringWithString:newString];
}

@end
