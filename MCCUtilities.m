//
//  MCCUtilities.m
//  MCCMailCommon
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCUtilities.h"


@implementation MCC_PREFIXED_NAME(Utilities)

+ (BOOL)notifyUserAboutSnitchesForPluginName:(NSString *)pluginName domainList:(NSArray *)domains usingIcon:(NSImage *)iconImage {
	BOOL	foundSnitcher = NO;
	
	//	Return if we don't have the required info
	if ((pluginName == nil) || ([pluginName length] < 1) || (domains == nil) || ([domains count] < 1))  {
		return foundSnitcher;
	}
	
#ifdef TEST_SNITCHING
	NSDictionary	*snitchers = @{@"com.metakine.handsoff": @"Hands Off!", @"com.radiosilenceapp.client": @"Radio Silence", @"at.obdev.LittleSnitchConfiguration": @"Little Snitch", @"com.littleknownsoftware.SnitchTester": @"Network Watcher"};
#else
	NSDictionary	*snitchers = @{@"com.metakine.handsoff": @"Hands Off!", @"com.radiosilenceapp.client": @"Radio Silence", @"at.obdev.LittleSnitchConfiguration": @"Little Snitch"};
#endif

	NSMutableString	*formattedDomains = [NSMutableString string];
	for (NSString *aDomain in domains) {
		if ([formattedDomains length] > 0) {
			[formattedDomains appendString:@"\n"];
		}
		[formattedDomains appendFormat:@"%@", aDomain];
	}

	
	NSString		*infoFormat = LOCALIZED_TABLE(@"ALLOW_CONNECTIONS_TO_DOMAIN_LIST_SINGULAR", @"MCCUtilities");
	if ([domains count] > 1) {
		infoFormat = LOCALIZED_TABLE(@"ALLOW_CONNECTIONS_TO_DOMAIN_LIST_PLURAL", @"MCCUtilities");
	}

	for (NSString *aSnitcherID in [snitchers allKeys]) {
		
		NSString	*aSnitcherName = snitchers[aSnitcherID];
		NSString	*messageText = LOCALIZED_TABLE_FORMAT(@"MCCUtilities", @"SNITCHER_FOUND", pluginName, aSnitcherName);
		NSString	*informationalText = [NSString stringWithFormat:infoFormat, aSnitcherName, formattedDomains];
		
		if ([[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:aSnitcherID]) {

			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = messageText;
			alert.informativeText = informationalText;
			alert.alertStyle = NSWarningAlertStyle;
			alert.icon = iconImage;
			
			[alert runModal];
			MCC_RELEASE(alert);

			foundSnitcher = YES;
			
			//	Only do for first app found
			break;
		}
	}
	
	return foundSnitcher;
}

+ (NSURL *)debugInfoScriptURL {
	NSArray	*applicationScripts = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationScriptsDirectory inDomains:NSUserDomainMask];
	NSURL	*scriptURL = nil;
	if ([applicationScripts count] > 0) {
		scriptURL = [applicationScripts objectAtIndex:0];
	}
	scriptURL = [scriptURL URLByAppendingPathComponent:@"LKS"];
	scriptURL = [[scriptURL URLByAppendingPathComponent:@"GetCompleteDebugInfo"] URLByAppendingPathExtension:@"scpt"];
	return [scriptURL filePathURL];
}

+ (void)runDebugInfoScript {
	NSError				*scriptError = nil;
	NSURL				*scriptURL = [self debugInfoScriptURL];
	NSUserScriptTask	*scriptTask = [[NSUserAppleScriptTask alloc] initWithURL:scriptURL error:&scriptError];
	[scriptTask executeWithCompletionHandler:^(NSError *error) {
		if (error != nil) {
			NSLog(@"There was an error:%@", error);
		}
		else {
			NSLog(@"Completed OK");
		}
	}];
}

+ (BOOL)debugInfoScriptIsAvailable {
	return [[self debugInfoScriptURL] checkResourceIsReachableAndReturnError:nil];
}


#pragma Singleton

+ (instancetype)sharedInstance {
	
	static MCC_PREFIXED_NAME(Utilities)	*mccInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mccInstance = [[MCC_PREFIXED_NAME(Utilities) alloc] init];
	});
	
	return mccInstance;
}

@end
