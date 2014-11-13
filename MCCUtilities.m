//
//  MCCUtilities.m
//  MCCMailCommon
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCUtilities.h"
#import "MCCDebugReasonSheet.h"


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
	
	if (!IS_EMPTY([[self sharedInstance] scriptPathComponent])) {
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
	
	NSAssert(targetView != nil, @"You must pass a view to runDebugInfoScriptUsingView:");
	
	MCCDebugReasonSheet	*reasonSheet = [[MCCDebugReasonSheet alloc] init];
	[reasonSheet showSheetInWindow:[targetView window]];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:MCCDebugReasonGivenNotification object:reasonSheet queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		
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
		
		[reasonSheet release];
	}];
	
	
}

+ (BOOL)debugInfoScriptIsAvailable {
	return [[self debugInfoScriptURL] checkResourceIsReachableAndReturnError:nil];
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
