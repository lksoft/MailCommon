//
//  MCCWebScriptPageController.h
//  MailCommon
//
//  Created by smorr on 2013-09-24.
//  Copyright (c) 2013 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#include "MCCCommonHeader.h"

@interface MCC_PREFIXED_NAME(WebScriptPageController) : NSObject

@property	(retain)	WebView	*webView;

- (NSString*)contentsOfPageElementID:(NSString*)pageObjectID;
- (void)setContentsOfPageElementID:(NSString*)pageObjectID toString:(NSString*)string;

- (NSString*)htmlOfPageElementID:(NSString*)pageObjectID;
- (void)setHtmlOfPageElementID:(NSString*)pageObjectID toString:(NSString*)string;
- (void)setHtmlOfPageElementID:(NSString*)pageObjectID toNode:(DOMHTMLElement*)element;

@end



