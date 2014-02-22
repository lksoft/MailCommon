//
//  TSTMailAbstractor.h
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCMailAbstractor.h"

@interface TSTMailAbstractor
@property	(strong)	NSDictionary	*mappings;
@property	(assign)	NSInteger		testVersionOS;
- (void)rebuildCurrentMappings;
- (instancetype)sharedInstance;
@end

