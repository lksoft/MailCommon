//
//  MCCBundleFileManager.m
//  Tealeaves
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCBundleFileManager.h"


@interface MCC_PREFIXED_NAME(BundleFileManager) ()
@property (strong) NSString *bundleName;
@end


@implementation MCC_PREFIXED_NAME(BundleFileManager)

- (instancetype)initWithBundleId:(NSString *)aBundleId {
	self = [super init];
	if (self) {
		if (aBundleId && ([aBundleId length] > 0)) {
			self.bundleName = aBundleId;
		}
		else {
			self.bundleName = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
			
			if (self.bundleName == nil) {
				self.bundleName = [[NSProcessInfo processInfo] processName];
			}
			
			if (self.bundleName == nil) {
				self.bundleName = @"";
			}
		}
	}
	return self;
}

- (NSString *)applicationName {
	return self.bundleName;
}


@end
