//
//  MCCEmailValidTransformer.m
//  Tealeaves
//
//  Created by Little Known on 21/04/15.
//  Copyright (c) 2015 Little Known Software. All rights reserved.
//

#import "MCCEmailValidTransformer.h"

@implementation MCC_PREFIXED_NAME(EmailValidTransformer)

+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
	if (!value || ([value length] < 1)) {
		return @NO;
	}
	NSError				*error = nil;
	NSString			*regExString = @"^[A-Za-z0-9._%+-]+@(?:[A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
	NSRegularExpression	*regEx = [NSRegularExpression regularExpressionWithPattern:regExString options:NSRegularExpressionCaseInsensitive error:&error];
	
	if ([regEx numberOfMatchesInString:value options:0 range:NSMakeRange(0, [value length])] == 1) {
		return @YES;
	}
	
	return @NO;
}

@end

