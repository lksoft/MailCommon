//
//  MCCSecuredFormatter.h
//  Tealeaves
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCCommonHeader.h"
#import "DDFileLogger.h"

#define MCCSecureFormattingContext	1


@interface MCCSecuredFormatter : DDLogFileFormatterDefault
- (NSString *)secureFormat:(NSString *)format;
@end

#ifdef LOG_MACRO
#undef LOG_MACRO
#endif
#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
	[DDLog log:isAsynchronous level:lvl flag:flg context:ctx file:__FILE__ function:fnct line:__LINE__ tag:atag format:(frmt), ##__VA_ARGS__]

#define MCCSecErr(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
#define MCCSecErrC(frmt, ...)	LOG_C_TAG_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
#define MCCSecWarn(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_FLAG_WARN,    MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
#define MCCSecInfo(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
#define MCCSecDebug(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_FLAG_DEBUG,   MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
#define MCCSecLog(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)

#ifdef MCC_INSECURE_LOGS
	#define DEFAULT_CONTEXT	0
#else
	#define DEFAULT_CONTEXT	MCCSecureFormattingContext
#endif

#define MCCErr(frmt, ...)		LOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)
#define MCCErrC(frmt, ...)		LOG_C_TAG_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)
#define MCCWarn(frmt, ...)		LOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_FLAG_WARN,    DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)
#define MCCInfo(frmt, ...)		LOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)
#define MCCDebug(frmt, ...)		LOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_FLAG_DEBUG,   DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)
#define MCCLog(frmt, ...)		LOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)

