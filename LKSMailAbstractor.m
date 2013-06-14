//
//  LKSMailAbstractor.m
//  Tealeaves
//
//  Created by Scott Little on 14/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "LKSMailAbstractor.h"

@implementation LKSMailAbstractor

@end


Class LKSClassForMailObject(NSString *aClassName) {
	Class	theClass = NSClassFromString(aClassName);
	
	return theClass;
}
