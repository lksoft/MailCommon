//
//  MCCMailAbstractor.h
//  MailCommonCode
//
//  Created by Scott Little on 14/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

// This requires a few levels of rewriting to get the desired results.
#define _MCC_CONCAT_2(c,d)			c ## d
#define _MCC_CONCAT(a,b)			_MCC_CONCAT_2(a,b)

#ifdef    MCC_PLUGIN_PREFIX
#define	MCC_PREFIXED_NAME(symbol)	_MCC_CONCAT(MCC_PLUGIN_PREFIX,symbol)
#define	MCC_SUFFIXED_NAME(symbol)	_MCC_CONCAT(symbol, _MCC_CONCAT(_, MCC_PLUGIN_PREFIX) )
#else
#define	MCC_PREFIXED_NAME(symbol)	_MCC_CONCAT(MCC,symbol)
#define	MCC_SUFFIXED_NAME(symbol)	_MCC_CONCAT(symbol,_MCC)
#endif	//	MCC_PLUGIN_PREFIX

#define _MCC_AS_STR(a)				#a
#define _MCC_CONCAT_AS_STR(a, b)	_MCC_AS_STR( a ## b )
#define _MCC_NS_STR(a)				@a
#define MCC_NSSTRING(a, b)			_MCC_NS_STR(_MCC_CONCAT_AS_STR(a, b))
