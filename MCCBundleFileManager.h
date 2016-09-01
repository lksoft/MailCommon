//
//  MCCBundleFileManager.h
//  Tealeaves
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCCommonHeader.h"
#import "DDFileLogger.h"


@interface MCC_PREFIXED_NAME(BundleFileManager) : DDLogFileManagerDefault
- (instancetype)initWithBundleId:(NSString *)aBundleId;
@end
