//
//  MCCMailAbstractor+MCCTesting.h
//  MCCMailCommon
//
//  Created by Scott Little on 15/6/13.
//  Copyright (c) 2013 Little Known Software, Inc. All rights reserved.
//

#import "MCCCommonHeader.h"

@interface MCC_PREFIXED_NAME(MailAbstractor) : NSObject {
	NSDictionary	*_mappings;
	NSInteger		_testVersionOS;
}

@property	(strong)	NSDictionary	*mappings;

+ (NSString *)actualClassNameForClassName:(NSString *)aClassName;
+ (Class)actualClassForClassName:(NSString *)aClassName;
+ (MCC_PREFIXED_NAME(MailAbstractor)*)sharedInstance;

@end


@interface TSTMailAbstractor (MCCTesting)

@property	(assign)	NSInteger		testOSVersion;

@end
