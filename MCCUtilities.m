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
NSString *const MCC_PREFIXED_CONSTANT(NetworkInteractionRequiredNotification) = MCC_NSSTRING(MCC_PLUGIN_PREFIX, _NETWORK_STATUS_INTERACTION_REQUIRED);

typedef NS_ENUM(NSUInteger, MCC_PREFIXED_CONSTANT(ConnectionState)) {
	ConnectionStateUnknown,
	ConnectionStateNone,
	ConnectionStateInteractionRequired,
	ConnectionStateValid
};

@interface MCC_PREFIXED_NAME(Utilities) ()
@property (assign) MCC_PREFIXED_CONSTANT(ConnectionState) internetConnectionState;
@end


@implementation MCC_PREFIXED_NAME(Utilities)


- (void)dealloc {
#if !__has_feature(objc_arc)
	self.bundle = nil;
	self.scriptPathComponent = nil;
#endif
	MCC_DEALLOC();
}

#pragma Class Methods

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
			alert.alertStyle = NSAlertStyleWarning;
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
	static NSURL	*scriptURL = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		NSArray	*applicationScripts = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationScriptsDirectory inDomains:NSUserDomainMask];
		if ([applicationScripts count] > 0) {
			scriptURL = [applicationScripts objectAtIndex:0];
		}
#ifdef DEBUG
		if ([[scriptURL lastPathComponent] isEqualToString:@"com.apple.xctest"]) {
			scriptURL = [[scriptURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"com.apple.mail"];
		}
#endif
		
		if (IS_NOT_EMPTY([[self sharedInstance] scriptPathComponent])) {
			scriptURL = [scriptURL URLByAppendingPathComponent:[[self sharedInstance] scriptPathComponent]];
		}
		MCC_RETAIN(scriptURL);
	});
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

+ (void)runHelperScriptWithArguments:(NSArray <NSString *> *)arguments completionHandler:(NSUserUnixTaskCompletionHandler)handler {
	NSURL * pathURL = [self helperScriptURL];
	if (pathURL) {
		NSError * myError = nil;
		NSUserUnixTask * aTask = [[NSUserUnixTask alloc] initWithURL:pathURL error:&myError];
		
		[aTask executeWithArguments:arguments completionHandler:^(NSError *error) {
			if (error) {
				MCCErr(@"Error executing script:%@", error);
			}
			if (handler) {
				handler(error);
			}
		}];
	}
	else {
		MCCErr(@"HelperScript was not found!!!");
	}
}

+ (BOOL)debugInfoScriptIsAvailable {
	return ([[self debugInfoScriptURL] checkResourceIsReachableAndReturnError:nil] && [[self helperScriptURL] checkResourceIsReachableAndReturnError:nil]);
}

+ (BOOL)helperScriptIsAvailable {
	return [[self helperScriptURL] checkResourceIsReachableAndReturnError:nil];
}

+ (void)addPluginMenu:(NSArray <NSDictionary <NSString*, NSString*> *> *)menuInfo toMailMenuWithTitle:(NSString *)pluginName target:(id)target {
	
	NSMenu * mailMenu = [[[[[NSApplication sharedApplication] mainMenu] itemArray] objectAtIndex:0] submenu];
	NSMenu * pluginSubMenu = [[NSMenu alloc] init];
	MCC_AUTORELEASE(pluginSubMenu);
	
	[menuInfo enumerateObjectsUsingBlock:^(NSDictionary <NSString *, NSString*> * _Nonnull menuDesc, NSUInteger idx, BOOL * _Nonnull stop) {
		
		NSString * selectorString = menuDesc[@"action"];
		if ([selectorString isEqualToString:@"-"]) {
			[pluginSubMenu addItem:[NSMenuItem separatorItem]];
		}
		else {
			MCCLog(@"Localization for title [%@] is: %@", menuDesc[@"title_key"], LOCALIZED(menuDesc[@"title_key"]));
			NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:LOCALIZED(menuDesc[@"title_key"]) action:NSSelectorFromString(selectorString) keyEquivalent:@""];
			MCC_AUTORELEASE(menuItem);
			[menuItem setTarget:target];
			[pluginSubMenu addItem:menuItem];
		}
		
	}];
	
	NSMenuItem * pluginMenu = [mailMenu itemWithTitle:pluginName];
	if (!pluginMenu) {
		pluginMenu = [[NSMenuItem alloc] initWithTitle:LOCALIZED(pluginName) action:nil keyEquivalent:@""];
		MCC_AUTORELEASE(pluginMenu);
		[pluginMenu setSubmenu:pluginSubMenu];
	}
	[mailMenu insertItem:pluginMenu atIndex:1];
	
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


#pragma mark - External Code Links

#ifndef MCC_NO_EXTERNAL_OBJECTS

+ (BOOL)networkReachable {
	return [[self sharedInstance] hasInternetConnection];
}

+ (BOOL)reachabilityForInternetConnection {
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [@"google.com" UTF8String]);

	BOOL isReachable = NO;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		//	Just test for reachability
		if (flags & kSCNetworkReachabilityFlagsReachable) {
			isReachable = YES;
		}
	}
	CFRelease(reachabilityRef);
	return isReachable;
}

+ (void)checkForNetworkConnection:(NSTimer *)connectionTimer {
	MCC_PREFIXED_NAME(Utilities) * utils = [self sharedInstance];
	NSString * hostName = connectionTimer.userInfo[@"host"];
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String]);
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		MCC_PREFIXED_CONSTANT(ConnectionState) previousState = utils.internetConnectionState;

		NSString * networkNotificationName = nil;
		
		//	Test to see if we need intervention
		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
			(flags & kSCNetworkReachabilityFlagsInterventionRequired)) {
			utils.internetConnectionState = ConnectionStateInteractionRequired;
			networkNotificationName = MCC_PREFIXED_CONSTANT(NetworkInteractionRequiredNotification);
		}
		//	Otherwise test for reachability
		else if (flags & kSCNetworkReachabilityFlagsReachable) {
			utils.internetConnectionState = ConnectionStateValid;
			networkNotificationName = MCC_PREFIXED_CONSTANT(NetworkAvailableNotification);
		}
		else {
			utils.internetConnectionState = ConnectionStateNone;
			networkNotificationName = MCC_PREFIXED_CONSTANT(NetworkUnavailableNotification);
		}

		utils.hasInternetConnection = (utils.internetConnectionState == ConnectionStateValid);
		if (previousState != utils.internetConnectionState) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:networkNotificationName object:nil];
			});
		}
	}
	CFRelease(reachabilityRef);
}

+ (void)startTrackingReachabilityUsingHostName:(NSString *)hostName {
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkForNetworkConnection:) userInfo:@{@"host": hostName} repeats:YES];
}

+ (void)runDebugInfoScriptUsingView:(NSView *)targetView {
	
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
}

#endif


@end

static CGFloat static_osVersionMinAndPoint = 0.0f;

MCC_PREFIXED_NAME(OSVersionValue) MCC_PREFIXED_NAME(OSVersion)(void) {
	
	static MCC_PREFIXED_NAME(OSVersionValue) static_osVersion = MCC_PREFIXED_NAME(OSVersionUnknown);
	if (static_osVersion == MCC_PREFIXED_NAME(OSVersionUnknown)) {
		NSDictionary	*version = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
		NSString		*productVersion = [version objectForKey:@"ProductVersion"];
		NSArray			*versionItems =  [productVersion componentsSeparatedByString:@"."];
		if ([versionItems count] >= 2) {
			static_osVersion = [versionItems[1] integerValue];
		}
		if ([versionItems count] >= 3) {
			static_osVersionMinAndPoint = (CGFloat)[versionItems[1] integerValue];
			static_osVersionMinAndPoint += ([versionItems[2] integerValue] / 10.0);
		}
	}
	return static_osVersion;
}

CGFloat MCC_PREFIXED_NAME(OSVersionFull)(void) {
	if (static_osVersionMinAndPoint < 0.9) {
		MCC_PREFIXED_NAME(OSVersion)();
	}
	return static_osVersionMinAndPoint;
}

