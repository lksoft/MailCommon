//
//  MCCLumberJackBase.h
//  MCCMailCommon
//
//  Created by Scott Little on 31/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface MCCLumberJackBase : XCTestCase

@property (strong) NSFileManager	*manager;
@property (strong) NSDateFormatter	*dateFormatter;

- (NSArray *)logMessages;
- (NSURL *)logTestFolderURL;

@end

