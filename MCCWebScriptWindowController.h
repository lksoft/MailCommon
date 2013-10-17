//
//  MCCWebScriptWindowController.h
//  MailCommon
//
//  Created by smorr on 2013-09-24.
//  Copyright (c) 2013 Indev Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include "MCCCommonHeader.h"

@interface MCC_PREFIXED_NAME(WebScriptWindowController) : NSWindowController

@property (retain) id pageController;

- (void)showWindowAndLoadURL:(NSURL*)url;
- (void)openURL:(NSString*)urlString;
- (void)log:(id)logString;

- (void)showEmbeddedPage:(NSString *)pageName;
- (void)closeWindow;

- (NSString *)nibName;

+ (instancetype)sharedInstance;

@end

