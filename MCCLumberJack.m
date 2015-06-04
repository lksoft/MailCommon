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
#import "MCCFeatureFormatter.h"
#import "MCCBugFormatter.h"
#import "MCCBundleFileManager.h"

#ifdef DEBUG
#define MCC_LOG_VERBOSE
#endif
#ifdef BUG_LOGGING
#define MCC_LOG_VERBOSE
#endif

#ifdef MCC_LOG_VERBOSE
	int	MCC_PREFIXED_NAME(DDDebugLevel) = ((int)LOG_LEVEL_VERBOSE);
#else
	int	MCC_PREFIXED_NAME(DDDebugLevel) = ((int)LOG_LEVEL_INFO);
#endif

int	MCC_PREFIXED_NAME(DDLogFeatures) = 0;
int	MCC_PREFIXED_NAME(DDLogBugs) = 0;


@interface MCC_PREFIXED_NAME(LumberJack) ()
@property (strong) MCC_PREFIXED_NAME(FeatureFormatter) *featureFormatter;
@property (strong) MCC_PREFIXED_NAME(BugFormatter) *bugFormatter;
@end

@implementation MCC_PREFIXED_NAME(LumberJack)


#pragma mark - Helper Creation

+ (void)addStandardLoggersWithFeatureDict:(NSDictionary *)featureDict {
	[self addStandardLoggersWithFeatureDict:featureDict forBundleId:nil];
}

+ (void)addStandardLoggersWithFeatureDict:(NSDictionary *)featureDict forBundleId:(NSString *)aBundleId {
	
	//	Set up the logging
	MCC_PREFIXED_NAME(BundleFileManager)	*bundleFileManager = [[MCC_PREFIXED_NAME(BundleFileManager) alloc] initWithBundleId:aBundleId];
	DDFileLogger		*fileLogger = [[DDFileLogger alloc] initWithLogFileManager:bundleFileManager];
	MCC_PREFIXED_NAME(LumberJack)	*jack = [self defaultInstance];
	jack.featureFormatter.featureMappings = featureDict;
	[fileLogger setLogFormatter:jack.featureFormatter];
	[DDLog addLogger:fileLogger withLogLevel:INT32_MAX];
#ifdef DEBUG
	//	Will log everything to Xcode console
	[DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:INT32_MAX];
#endif

}

+ (void)addBugLoggerWithDict:(NSDictionary *)bugDict forBundleId:(NSString *)aBundleId {
	
	NSString	*bundleId = [@"bugs." stringByAppendingString:aBundleId];
	//	Set up the logging
	MCC_PREFIXED_NAME(BundleFileManager)	*bundleFileManager = [[MCC_PREFIXED_NAME(BundleFileManager) alloc] initWithBundleId:bundleId];
	DDFileLogger		*fileLogger = [[DDFileLogger alloc] initWithLogFileManager:bundleFileManager];
	MCC_PREFIXED_NAME(LumberJack)	*jack = [self defaultInstance];
	jack.bugFormatter = [[MCC_PREFIXED_NAME(BugFormatter) alloc] init];
	jack.bugFormatter.featureMappings = bugDict;
	[fileLogger setLogFormatter:jack.bugFormatter];
	[DDLog addLogger:fileLogger withLogLevel:INT32_MAX];
}

+ (instancetype)defaultInstance {
	static MCC_PREFIXED_NAME(LumberJack) *defaultLumberJack = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		defaultLumberJack = [[self alloc] init];
		defaultLumberJack.featureFormatter = [[MCC_PREFIXED_NAME(FeatureFormatter) alloc] init];
		defaultLumberJack.bugFormatter = nil;
	});
	
	return defaultLumberJack;
}


#pragma mark - Level Settings

+ (int)debugLevel {
	return MCC_PREFIXED_NAME(DDDebugLevel);
}

+ (void)setDebugLevel:(int)newLevel {
	MCC_PREFIXED_NAME(DDDebugLevel) = newLevel;
}


#pragma mark - Feature Settings

+ (void)addLogFeature:(int)newFeature {
	MCC_PREFIXED_NAME(DDLogFeatures) = (MCC_PREFIXED_NAME(DDLogFeatures) | newFeature);
}

+ (void)resetLogFeature {
	MCC_PREFIXED_NAME(DDLogFeatures) = 0;
}

+ (void)addLogBug:(int)newBug {
	MCC_PREFIXED_NAME(DDLogBugs) = (MCC_PREFIXED_NAME(DDLogBugs) | newBug);
}

+ (void)resetLogBug {
	MCC_PREFIXED_NAME(DDLogBugs) = 0;
}

@end


@interface DDLog (MCCLumberJackInternal)
+ (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag;
@end


@implementation DDLog (MCCLumberJack)

+ (void)secureLog:(BOOL)asynchronous level:(int)level flag:(int)flag context:(int)context file:(const char *)file function:(const char *)function line:(int)line tag:(id)tag format:(NSString *)format, ... {
	
    va_list args;
    if (format) {
        va_start(args, format);
        
		NSString	*logMsg = nil;
		if (context & MCCSecureFormattingContext) {
			NSString	*preMarkedFormat = [self preMarkedSecureFormat:format];
			preMarkedFormat = [[NSString alloc] initWithFormat:preMarkedFormat arguments:args];
			logMsg = [[NSString alloc] initWithString:[self replaceMarkedFormat:preMarkedFormat]];
		}
		else {
			logMsg = [[NSString alloc] initWithFormat:format arguments:args];
		}
        DDLogMessage *logMessage = [[DDLogMessage alloc] initWithLogMsg:logMsg
                                                                  level:level
                                                                   flag:flag
                                                                context:context
                                                                   file:file
                                                               function:function
                                                                   line:line
                                                                    tag:tag
                                                                options:0];
        
        [self queueLogMessage:logMessage asynchronously:asynchronous];
        
        va_end(args);
    }
}

+ (NSString *)preMarkedSecureFormat:(NSString *)format {
	
	//	the text to pre mark the secured output with
	NSString	*addBefore = @"<[*";
	NSString	*addAfter = @"*]>";
	
	
	//	the string format set, including the %
	NSCharacterSet	*stringFormatSet = [NSCharacterSet characterSetWithCharactersInString:@"@dDiuUxXoOfeEgGcCsSphq"];
	
	//	scan the string for an asterisk & percent (*%)
	//		if the next is '%' ignore
	//		then scan for one of the following:
	//			@ d D i u U x X o O f e E g G c C s S p h q
	//		if found delete from the % to the char inclusive
	//		unless one of the last two then add another character to delete
	NSScanner		*myScan = [NSScanner scannerWithString:format];
	NSMutableString	*newFormat = [NSMutableString string];
	NSString		*holder = nil;
	
	//	ensure that it doesn't skip any whitespace
	[myScan setCharactersToBeSkipped:nil];
	
	//	If the format string starts with a '%', set a flag
	BOOL	startsWithPercent = [format hasPrefix:@"*%"];
	//	look for those '%'s
	while ([myScan scanUpToString:@"*%" intoString:&holder] || startsWithPercent) {
		//	Immediately switch off that flag
		startsWithPercent = NO;
		
		//	add holder to the newFormat
		if (holder) {
			[newFormat appendString:holder];
		}
		
		//	if we are the end, leave
		if ([myScan isAtEnd]) {
			break;
		}
		
		//	Advance the scanner position 1 to skip the asterisk
		[myScan setScanLocation:([myScan scanLocation] + 1)];
		
		//	scan for the potentials
		if ([myScan scanUpToCharactersFromSet:stringFormatSet
								   intoString:&holder]) {
			
			//	if current position is '%', reappend '%%' and continue
			if ([format characterAtIndex:[myScan scanLocation]] == '%') {
				[newFormat appendString:@"*%%"];
				[myScan setScanLocation:([myScan scanLocation] + 1)];
				continue;
			}
			
			[newFormat appendString:addBefore];
			[newFormat appendString:holder];
			
			//	and if the last character is either 'h' or 'q',
			//		advance the pointer one more position to skip that
			unichar	lastChar = [format characterAtIndex:[myScan scanLocation]];
			if ((lastChar == 'h') || (lastChar == 'q')) {
				[myScan setScanLocation:([myScan scanLocation] + 1)];
				[newFormat appendString:[NSString stringWithCharacters:&lastChar length:1]];
			}
			
			//	always advance the scan position past the last matched character
			lastChar = [format characterAtIndex:[myScan scanLocation]];
			[newFormat appendString:[NSString stringWithCharacters:&lastChar length:1]];
			[myScan setScanLocation:([myScan scanLocation] + 1)];
			
			//	stick the replace string into the outgoing string
			[newFormat appendString:addAfter];
		}
		else {
			//	bad formatting, give warning and reset the format completely to ensure security
			NSLog(@"Bad format during Secure Scan Reformat: original format is:%@", format);
			return @"Bad format for Secure Logging";
		}
		
	}
	
	//	return the string
	return [NSString stringWithString:newFormat];
}

+ (NSString *)replaceMarkedFormat:(NSString *)format {
	
	//	Pre Marked bookends
	NSString	*markerBefore = @"<[*";
	NSString	*markerAfter = @"*]>";
	
	//	the text to replace the hidden output with
	NSString		*replaceWith = @"<****>";
	
	NSScanner		*myScan = [NSScanner scannerWithString:format];
	NSMutableString	*newFormat = [NSMutableString string];
	NSString		*holder = nil;
	
	//	ensure that it doesn't skip any whitespace
	[myScan setCharactersToBeSkipped:nil];
	
	//	look for the beginning marker
	while ([myScan scanUpToString:markerBefore intoString:&holder]) {
		
		//	add holder to the newFormat
		if (holder) {
			[newFormat appendString:holder];
		}
		
		//	if we are the end, leave
		if ([myScan isAtEnd]) {
			break;
		}
		
		//	scan for the potentials
		if ([myScan scanUpToString:markerAfter intoString:&holder]) {
			
			//	always advance the scan position past the matched string
			[myScan setScanLocation:([myScan scanLocation] + [markerAfter length])];
			
			//	stick the replace string into the outgoing string
			[newFormat appendString:replaceWith];
		}
		else {
			//	bad formatting, give warning and reset the format completely to ensure security
			NSLog(@"Bad format during Secure Scan Reformat: original format is:%@", format);
			return @"Bad format for Secure Logging";
		}
		
	}
	
	//	return the string
	return [NSString stringWithString:newFormat];
}

@end
