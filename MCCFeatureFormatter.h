//
//  MCCFeatureFormatter.h
//  Tealeaves
//
//  Created by Scott Little on 30/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCCommonHeader.h"
//#import "DDFileLogger.h"
#import "MCCLumberJack.h"


@interface MCC_PREFIXED_NAME(FeatureFormatter) : NSObject <DDLogFormatter>
@property (strong) NSDateFormatter	*dateFormatter;
@property (strong) NSDictionary *featureMappings;
@end


@interface MCC_PREFIXED_NAME(LumberJack) (FeatureFormatter)
+ (void)addLogFeature:(int)newFeature;
@end

