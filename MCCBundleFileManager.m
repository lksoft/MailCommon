//
//  MCCBundleFileManager.m
//  Tealeaves
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCBundleFileManager.h"

@implementation MCC_PREFIXED_NAME(BundleFileManager)

- (NSString *)applicationName {
    static NSString *_appName;
    static dispatch_once_t onceToken;
	
    dispatch_once(&onceToken, ^{
        _appName = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
		
        if (! _appName) {
            _appName = [[NSProcessInfo processInfo] processName];
        }
		
        if (! _appName) {
            _appName = @"";
        }
    });
	
    return _appName;
}


@end
