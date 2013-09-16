//
//  TSTObject.h
//  MCCMailCommon
//
//  Created by Scott Little on 15/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSTObject : NSObject
@property	NSString	*testProp;
- (NSString *)foo;
- (NSString *)bar;
- (NSString *)additive;
- (NSString *)methodWithSuper;
@end
