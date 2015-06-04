//
//  MCCUtilities.m
//  MCCMailCommon
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCUtilities.h"
#ifndef MCC_NO_EXTERNAL_OBJECTS
#import "MCCDebugReasonSheet.h"
#endif


NSString *const MCC_PREFIXED_CONSTANT(NetworkAvailableNotification) = MCC_NSSTRING(MCC_PLUGIN_PREFIX, _NETWORK_STATUS_AVAILABLE);
NSString *const MCC_PREFIXED_CONSTANT(NetworkUnavailableNotification) = MCC_NSSTRING(MCC_PLUGIN_PREFIX, _NETWORK_STATUS_UNAVAILABLE);

@implementation MCC_PREFIXED_NAME(Utilities)


#pragma Class Methods

+ (BOOL)networkReachable {
	return [[self sharedInstance] hasInternetConnection];
}

+ (void)startTrackingReachabilityUsingHostName:(NSString *)hostName {
	MCC_PREFIXED_NAME(Utilities)	*utils = [self sharedInstance];
	
	//	Set up the Reachability stuff
	// allocate a reachability object
	Reachability	*reach = [Reachability reachabilityWithHostname:hostName];
	// set the blocks
	reach.reachableBlock = ^(Reachability	*theReach) {
		utils.hasInternetConnection = YES;
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(NetworkAvailableNotification) object:nil];
		});
	};
	
	reach.unreachableBlock = ^(Reachability	*theReach) {
		if (utils.hasInternetConnection) {
			utils.hasInternetConnection = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(NetworkUnavailableNotification) object:nil];
			});
		}
	};
	// start the notifier which will cause the reachability object to retain itself!
	[reach startNotifier];
	utils.reachability = reach;
}

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

+ (NSURL *)applicationScriptsURL {
	NSURL	*scriptURL = nil;
	
	if (OSVERSION >= MCC_PREFIXED_NAME(OSVersionMountainLion)) {
		NSArray	*applicationScripts = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationScriptsDirectory inDomains:NSUserDomainMask];
		if ([applicationScripts count] > 0) {
			scriptURL = [applicationScripts objectAtIndex:0];
		}
	}
	else {
		scriptURL = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
		scriptURL = [scriptURL URLByAppendingPathComponent:@"Application Scripts"];
		scriptURL = [scriptURL URLByAppendingPathComponent:@"com.apple.mail"];
	}
	
	if (IS_NOT_EMPTY([[self sharedInstance] scriptPathComponent])) {
		scriptURL = [scriptURL URLByAppendingPathComponent:[[self sharedInstance] scriptPathComponent]];
	}
	return scriptURL;
}

+ (NSURL *)debugInfoScriptURL {
	NSURL	*scriptURL = [self applicationScriptsURL];
	scriptURL = [[scriptURL URLByAppendingPathComponent:@"GetCompleteDebugInfo"] URLByAppendingPathExtension:@"applescript"];
	return [scriptURL filePathURL];
}

+ (NSURL *)helperScriptURL {
	NSURL	*scriptURL = [MCC_PREFIXED_NAME(Utilities) applicationScriptsURL];
	scriptURL = [[scriptURL URLByAppendingPathComponent:@"HelperScript"] URLByAppendingPathExtension:@"sh"];
	return [scriptURL filePathURL];
}

+ (void)runDebugInfoScriptUsingView:(NSView *)targetView {
	
#ifndef MCC_NO_EXTERNAL_OBJECTS
	NSAssert(targetView != nil, @"You must pass a view to runDebugInfoScriptUsingView:");
	
	MCC_PREFIXED_NAME(DebugReasonSheet)	*reasonSheet = [[MCC_PREFIXED_NAME(DebugReasonSheet) alloc] init];
	[reasonSheet showSheetInWindow:[targetView window]];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification) object:reasonSheet queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		
		NSString	*messageSubject = [NSString stringWithFormat:@"Debug information for %@", [[[[self sharedInstance] bundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey]];
		NSString	*messageProblem = [reasonSheet.problemText string];
		
		NSURL	*pathURL = [MCC_PREFIXED_NAME(Utilities) helperScriptURL];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[pathURL path]]) {
			NSArray	*scriptArguments = @[@"-debug", messageSubject, messageProblem];
			
			NSError			*scriptError = nil;
			NSUserUnixTask	*scriptTask = [[NSUserUnixTask alloc] initWithURL:pathURL error:&scriptError];
			[scriptTask executeWithArguments:scriptArguments completionHandler:^(NSError *executeError) {
				if (executeError) {
					[targetView presentError:executeError modalForWindow:[targetView window] delegate:nil didPresentSelector:nil contextInfo:NULL];
					NSLog(@"Error executing uninstall script:%@", executeError);
				}
			}];
			
		}
		
		MCC_RELEASE(reasonSheet);
	}];
#else
	NSAssert(NO, @"You have called runDebugInfoScriptUsingView while designating MCC_NO_EXTERNAL_OBJECTS!");
#endif
	
}

+ (BOOL)debugInfoScriptIsAvailable {
	return ([[self debugInfoScriptURL] checkResourceIsReachableAndReturnError:nil] && [[self helperScriptURL] checkResourceIsReachableAndReturnError:nil]);
}

+ (BOOL)helperScriptIsAvailable {
	return [[self helperScriptURL] checkResourceIsReachableAndReturnError:nil];
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

#ifndef NSAppKitVersionNumber10_7
#define NSAppKitVersionNumber10_7 1138
#endif
#ifndef NSAppKitVersionNumber10_8
#define NSAppKitVersionNumber10_8 1187
#endif
#ifndef NSAppKitVersionNumber10_9
#define NSAppKitVersionNumber10_9 1265
#endif

MCC_PREFIXED_NAME(OSVersionValue) MCC_PREFIXED_NAME(OSVersion)(void) {
	
	static MCC_PREFIXED_NAME(OSVersionValue) static_osVersion = MCC_PREFIXED_NAME(OSVersionUnknown);
	if (static_osVersion == MCC_PREFIXED_NAME(OSVersionUnknown)) {
		
		if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_5) {
			static_osVersion  = MCC_PREFIXED_NAME(OSVersionLeopard);
		}
		else if ( floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
			static_osVersion  = MCC_PREFIXED_NAME(OSVersionSnowLeopard);
		}
		else if ( floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7) {
			static_osVersion  = MCC_PREFIXED_NAME(OSVersionLion);
		}
		else if ( floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
			static_osVersion = MCC_PREFIXED_NAME(OSVersionMountainLion);
		}
		else if ( floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
			static_osVersion = MCC_PREFIXED_NAME(OSVersionMavericks);
		}
		else {
			static_osVersion = MCC_PREFIXED_NAME(OSVersionYosemite);
		}
		
	}
	return static_osVersion;
}

