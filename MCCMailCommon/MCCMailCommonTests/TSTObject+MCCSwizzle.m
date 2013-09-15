//
//  TSTObject+MCCSwizzle.m
//  MCCMailCommon
//
//  Created by Scott Little on 15/9/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import "TSTObject+MCCSwizzle.h"
#import "MCCSwizzle.h"

@interface TSTObject_TST : TSTSwizzle
@property				NSString	*addedProp;
@property				NSString	*getterProp;
@property	(readonly)	NSString	*readOnlyProp;
@property	(readwrite)	NSString	*readOnlyExternalProp;
@end

@interface TSTObject (SwizzleInternal)
- (id)TST_init;
- (NSString *)TST_additive;
@end


@implementation TSTObject_TST

@dynamic addedProp;
@dynamic getterProp;
@dynamic readOnlyProp;
@dynamic readOnlyExternalProp;

+ (void)load {
	[self swizzle];
}

#define myself ((TSTObject *)self)

- (id)init {
	self = [myself TST_init];
	if (self) {
		self.addedProp = @"One More PropValue";
		self.readOnlyExternalProp = @"Can Do";
	}
	return self;
}

- (NSString *)foo {
	return @"A New Foo";
}

- (NSString *)additive {
	NSString	*original = [myself TST_additive];
	return [NSString stringWithFormat:@"%@%@", original, @" - this was added"];
}

- (NSString *)getterProp {
	return @"This getter has a method";
}

- (NSString *)readOnlyProp {
	return @"Read Only Property";
}

#undef myself

@end
