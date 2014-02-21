//
//  SNTAppDelegate.m
//  SnitchTester
//
//  Created by Scott Little on 21/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "SNTAppDelegate.h"
#import "MCCUtilities.h"

@implementation SNTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	SNTUtilities	*utils = [SNTUtilities sharedInstance];
	utils.bundle = [NSBundle mainBundle];
	
	NSImage	*anImage = [NSImage imageNamed:@"Mail_Large"];
	
	[SNTUtilities notifyUserAboutSnitchesForPluginName:@"Snitch Tester" domainList:@[@"littleknownsoftware.com", @"tea-leav.es"] usingIcon:anImage];
	
	[SNTUtilities notifyUserAboutSnitchesForPluginName:@"SignatureProfiler" domainList:@[@"littleknownsoftware.com"] usingIcon:anImage];
	
}

@end
