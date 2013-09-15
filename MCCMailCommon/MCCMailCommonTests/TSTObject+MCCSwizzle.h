//
//  TSTObject+MCCSwizzle.h
//  MCCMailCommon
//
//  Created by Scott Little on 15/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TSTObject.h"

@interface TSTObject (Swizzle)
@property				NSString	*addedProp;
@property				NSString	*getterProp;
@property	(readonly)	NSString	*readOnlyProp;
@property	(readonly)	NSString	*readOnlyExternalProp;
@end
