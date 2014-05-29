//
//  MCCSecuredFormatter.h
//  Tealeaves
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCCommonHeader.h"
#import "DDFileLogger.h"
#import "MCCLumberJack.h"


@interface MCCSecuredFormatter : DDLogFileFormatterDefault
- (NSString *)secureFormat:(NSString *)format;
@end

