//
//  MCCWebScriptPageController.m
//  MailCommon
//
//  Created by smorr on 2013-09-24.
//  Copyright (c) 2013 Indev Software. All rights reserved.
//

#import "MCCWebScriptPageController.h"


/*
 * Each method of this controller works handler for a javascript function call by the webpage.
 *
 * The webpage should in the name of the class for handling the javascript
 *
 * The Window controller will instantiate the controller object when the page loads
 * eg
 *  <script>
 *      // set the objective-c page controller class for this web page.
 *      windowController.setPageControllerClassName("WelcomePageController");
 *
 *  </script>
 *
 *  Calling each method is a simple javascript.function evocation to the pageController object
 *  eg
 *      <button type="button" onclick="pageController.buyOnline()">Buy Online</button>
 *
 *  Naming Convention
 *
 *     OBJC Functions with 0  parameters will have JS names identical to obj-c names
 *          eg -(void)buyOnline                pageController.buyOnline();
 *
 *     OBJC Functions with 1  parameters will drop the final : in the JS function name
 *          eg -(void)setAValue:                pageController.setAValue(1);
 *
 *     OBJC Functions with 2+ parameters will drop the final : in the JS function name
 *             and convert remaining : to _
 *          eg -(void)setValue:forKey:          pageController.setValue_forKey(1,"test");
 *
 *
 *  Elements contents
 *
 *  The pageController can access and set the text of html elements by ID with the following methods
 *      - (void)setContentsOfPageElement:(NSString*) pageObjectID toString:(NSString*)string;
 *      - (NSString*)contentsOfPageElement:(NSString*) pageObjectID;
 *
 *
 */


@implementation MCC_PREFIXED_NAME(WebScriptPageController)

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel {
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel {
    NSString *selectorString = NSStringFromSelector(sel);
    if ([selectorString hasSuffix:@":"]){
        selectorString = [selectorString substringToIndex:[selectorString length]-1];
    }
    NSString *result= [selectorString stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    return result;
}

+ (NSString *)webScriptNameForKey:(const char *)name {
 	return nil;
}


#pragma mark - Getting/Setting Page Content

- (NSString*)contentOfElementId:(NSString*)pageObjectID {
    WebScriptObject	*scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
		if (result) {
			if ([result respondsToSelector:@selector(value)]) {
				return [result performSelector:@selector(value)];
			}
			else if ([result isKindOfClass:[DOMHTMLElement class]]){
				return [result innerText];
			}
		}
    }
    return nil;
    
}

- (void)setContentOfElementId:(NSString*)pageObjectID toString:(NSString*)string {
    WebScriptObject* scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
		if (result) {
			if ([result respondsToSelector:@selector(value)]) {
				[result performSelector:@selector(setValue:) withObject:string];
			}
			else if ([result isKindOfClass:[DOMHTMLElement class]]){
				[result setInnerText:string];
			}
		}
    }
}

- (NSString*)imagePathOnElementId:(NSString*)pageObjectID {
    WebScriptObject	*scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
		if (result) {
			if ([result respondsToSelector:@selector(src)]) {
				return [result performSelector:@selector(src)];
			}
		}
    }
    return nil;
    
}

- (void)setImagePath:(NSString*)path onElementId:(NSString*)pageObjectID {
    WebScriptObject* scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
		if (result) {
			if ([result respondsToSelector:@selector(src)]) {
				[result performSelector:@selector(setSrc:) withObject:path];
			}
		}
    }
}

- (NSString*)htmlOfElementId:(NSString*)pageObjectID {
    WebScriptObject	*scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
        if (result  && [result isKindOfClass:[DOMHTMLElement class]]){
            return [result innerHTML];
        }
    }
    return nil;
    
}

- (void)setHtmlOfElementId:(NSString*)pageObjectID toString:(NSString*)string {
    WebScriptObject* scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
        if (result  && [result isKindOfClass:[DOMHTMLElement class]]){
            [result setInnerHTML:string];
        }
    }
}

- (void)setHtmlOfElementId:(NSString*)pageObjectID toNode:(DOMHTMLElement*)element {
    WebScriptObject* scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
        if (result  && [result isKindOfClass:[DOMHTMLElement class]]){
            [result setInnerHTML:[element outerHTML]];
        }
    }
}


#pragma mark - Attributes

- (void)setAttributeValue:(NSString *)attrValue forName:(NSString *)attrName onElementId:(NSString *)pageObjectID {
    WebScriptObject* scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
		if (result && [result isKindOfClass:[DOMHTMLElement class]]) {
			NSString	*setDisabledScript = [NSString stringWithFormat:@"document.getElementById('%@').%@ = %@", pageObjectID, attrName, attrValue];
			[scriptObject evaluateWebScript:setDisabledScript];
		}
    }
}

- (BOOL)attributeValueForName:(NSString *)attrName onElementId:(NSString *)pageObjectID {
    WebScriptObject* scriptObject = [self.webView windowScriptObject];
    if (scriptObject) {
		id result = [scriptObject valueForKey:pageObjectID];
		if (result && [result isKindOfClass:[DOMHTMLElement class]]) {
			NSString	*setDisabledScript = [NSString stringWithFormat:@"document.getElementById('%@').%@", pageObjectID, attrName];
			id disabledValue = [scriptObject evaluateWebScript:setDisabledScript];
			return [disabledValue boolValue];
		}
    }
	return NO;
}


- (void)setDisabled:(BOOL)disabled onElementId:(NSString *)pageObjectID {
	[self setAttributeValue:(disabled?@"true":@"false") forName:@"disabled" onElementId:pageObjectID];
}

- (BOOL)disabledOnElementId:(NSString *)pageObjectID {
	return [self attributeValueForName:@"disabled" onElementId:pageObjectID];
}

- (void)setHidden:(BOOL)hidden onElementId:(NSString *)pageObjectID {
	[self setAttributeValue:(hidden?@"true":@"false") forName:@"hidden" onElementId:pageObjectID];
}

- (BOOL)hiddenOnElementId:(NSString *)pageObjectID {
	return [self attributeValueForName:@"hidden" onElementId:pageObjectID];
}




@end
