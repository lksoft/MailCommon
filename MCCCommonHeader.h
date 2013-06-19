//
//  MCCMailAbstractor.h
//  MailCommonCode
//
//  Created by Scott Little on 14/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

// This requires a few levels of rewriting to get the desired results.
#define _MCC_CONCAT_2(c,d)	c ## d
#define _MCC_CONCAT(a,b)	_MCC_CONCAT_2(a,b)

//#define MCC_PLUGIN_PREFIX	SJL

#ifdef    MCC_PLUGIN_PREFIX
#define	MCC_PREFIXED_NAME(function)	_MCC_CONCAT(MCC_PLUGIN_PREFIX,function)
#else
#define	MCC_PREFIXED_NAME(function)	_MCC_CONCAT(MCC,function)
#endif	//	MCC_PLUGIN_PREFIX
