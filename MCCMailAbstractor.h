//
//  MCCMailAbstractor.h
//  MailCommonCode
//
//  Created by Scott Little on 14/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

Class MCC_PREFIXED_NAME(ClassFromString)(NSString *aClassName);

#define CLS(className) MCC_PREFIXED_NAME(ClassFromString)([NSString stringWithFormat:@"%s",#className])
#define PREFIXED_CLS(className)	MCC_PREFIXED_NAME(ClassFromString)([NSString stringWithFormat:@"%@",MCC_NSSTRING(MCC_PLUGIN_PREFIX, className)])
