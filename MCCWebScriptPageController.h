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
#import "MCCWebScriptWindowController.h"

@interface MCC_PREFIXED_NAME(WebScriptPageController) : NSObject

@property	(retain)	WebView	*webView;
@property (readonly) MCC_PREFIXED_NAME(WebScriptWindowController)* windowController;
@property (readonly) NSWindow * window;


- (NSString*)contentOfElementId:(NSString*)pageObjectID;
- (void)setContentOfElementId:(NSString*)pageObjectID toString:(NSString*)string;

- (NSString*)imagePathOnElementId:(NSString*)pageObjectID;
- (void)setImagePath:(NSString*)path onElementId:(NSString*)pageObjectID;

- (NSString*)htmlOfElementId:(NSString*)pageObjectID;
- (void)setHtmlOfElementId:(NSString*)pageObjectID toString:(NSString*)string;
- (void)setHtmlOfElementId:(NSString*)pageObjectID toNode:(DOMHTMLElement*)element;

- (void)setDisabled:(BOOL)enabled onElementId:(NSString *)pageObjectID;
- (BOOL)disabledOnElementId:(NSString *)pageObjectID;

- (void)setHidden:(BOOL)hidden onElementId:(NSString *)pageObjectID;
- (BOOL)hiddenOnElementId:(NSString *)pageObjectID;

- (void)setAttributeValue:(NSString *)attrValue forName:(NSString *)attrName onElementId:(NSString *)pageObjectID;
- (BOOL)attributeValueForName:(NSString *)attrName onElementId:(NSString *)pageObjectID;
-(void)initPage;
@end


