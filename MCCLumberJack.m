//
//  MCCLumberJack.m
//  MailCommon
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCLumberJack.h"
#import "DDFileLogger.h"

#ifdef DEBUG
	int	MCC_PREFIXED_NAME(DDDebugLevel) = ((int)LOG_LEVEL_VERBOSE);
#else
	int	MCC_PREFIXED_NAME(DDDebugLevel) = ((int)LOG_LEVEL_INFO);
#endif
int	MCC_PREFIXED_NAME(DDDebugTypes) = 0;

int	MCC_PREFIXED_NAME(LumberJackDebugLevel)(void) {
	return MCC_PREFIXED_NAME(DDDebugLevel);
}

void MCC_PREFIXED_NAME(SetLumberJackDebugLevel)(int newLevel) {
	MCC_PREFIXED_NAME(DDDebugLevel) = newLevel;
}

void MCC_PREFIXED_NAME(AddLumberJackDebugType)(int newType) {
	MCC_PREFIXED_NAME(DDDebugTypes) = (MCC_PREFIXED_NAME(DDDebugTypes) | newType);
}
