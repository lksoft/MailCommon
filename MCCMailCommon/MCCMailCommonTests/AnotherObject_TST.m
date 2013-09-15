//
//  AnotherObject_TST.m
//  MCCMailCommon
//
//  Created by Scott Little on 15/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//


#import "AnotherObject_TST.h"
#import "MCCSwizzle.h"

@interface AnotherObject__TST : TSTSwizzle

@end

@interface AnotherObject (InternalSwizzle)
- (NSString *)TSTadditive;
@end

@implementation AnotherObject__TST

+ (void)load {
	[self swizzle];
}

#define myself	((AnotherObject *)self)

- (NSString *)additive {
	return [NSString stringWithFormat:@"%@ - and some more", [myself TSTadditive]];
}

#undef myself

@end
