//
//  NSData+hexDigits.h
//  AquaticPrime Developer
//
//  Created by Geode on 07/09/2012.
//
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

@interface NSData (hexDigits)
+ (NSData*)MCC_PREFIXED_NAME(dataWithHexDigitRepresentation):(NSString*)hexDigitString;
- (NSString*)MCC_PREFIXED_NAME(hexDigitRepresentation);
@end
