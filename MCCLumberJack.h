//
//  MCCLumberJack.h
//  Logging Framework enabler
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCCommonHeader.h"

#ifdef LOG_LEVEL_DEF
	#undef LOG_LEVEL_DEF
#endif
extern int	MCC_PREFIXED_NAME(DDDebugLevel);
#define	LOG_LEVEL_DEF	MCC_PREFIXED_NAME(DDDebugLevel)
extern int	MCC_PREFIXED_NAME(DDLogFeatures);


@interface MCC_PREFIXED_NAME(LumberJack) : NSObject

+ (void)addStandardLoggersWithFeatureDict:(NSDictionary *)featureDict;
+ (int)debugLevel;
+ (void)setDebugLevel:(int)newLevel;

@end

#pragma mark - MCC Macros

#define MCCSecureFormattingContext	(1 << 1)
#define MCCFeatureFormattingContext	(1 << 2)

//#ifdef LOG_MACRO
//	#undef LOG_MACRO
//#endif
//#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
//	[DDLog log:isAsynchronous level:lvl flag:flg context:ctx file:__FILE__ function:fnct line:__LINE__ tag:atag format:(frmt), ##__VA_ARGS__]
//
//#define MCCSecErr(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
//#define MCCSecErrC(frmt, ...)	LOG_C_TAG_MAYBE(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
//#define MCCSecWarn(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN, LOG_LEVEL_DEF, LOG_FLAG_WARN, MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
//#define MCCSecInfo(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO, LOG_LEVEL_DEF, LOG_FLAG_INFO, MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)
//#define MCCSecDebug(frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG, LOG_LEVEL_DEF, LOG_FLAG_DEBUG, MCCSecureFormattingContext, frmt, frmt, ##__VA_ARGS__)

#ifdef MCC_INSECURE_LOGS
	#define DEFAULT_CONTEXT	0
#else
	#define DEFAULT_CONTEXT	MCCSecureFormattingContext
#endif

#define MCCErr(frmt, ...)					LOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, 0, frmt, frmt, ##__VA_ARGS__)
#define MCCErrC(frmt, ...)					LOG_C_TAG_MAYBE(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, 0, frmt, frmt, ##__VA_ARGS__)
#define MCCWarn(frmt, ...)					LOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN, LOG_LEVEL_DEF, LOG_FLAG_WARN, 0, frmt, frmt, ##__VA_ARGS__)
#define MCCInfo(frmt, ...)					LOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO, LOG_LEVEL_DEF, LOG_FLAG_INFO, 0, frmt, frmt, ##__VA_ARGS__)
#define MCCDebug(frmt, ...)					LOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG, LOG_LEVEL_DEF, LOG_FLAG_DEBUG, 0, frmt, frmt, ##__VA_ARGS__)
#define MCCLog(frmt, ...)					LOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, DEFAULT_CONTEXT, frmt, frmt, ##__VA_ARGS__)

#define MCCLogFeature(featureFlag, frmt, ...)		LOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE, MCC_PREFIXED_NAME(DDLogFeatures), featureFlag, MCCFeatureFormattingContext, frmt, frmt, ##__VA_ARGS__)
//#define MCCLogSecFeature(featureFlag, frmt, ...)	LOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE, MCC_PREFIXED_NAME(DDLogFeatures), featureFlag, (MCCSecureFormattingContext & MCCFeatureFormattingContext), frmt, frmt, ##__VA_ARGS__)



#pragma mark - LumberJack Mappings

//	From DDLog.h
//	Classes
#define	DDLog								MCC_PREFIXED_NAME(DDLog)
#define	DDLogMessage						MCC_PREFIXED_NAME(DDLogMessage)
#define	DDAbstractLogger					MCC_PREFIXED_NAME(DDAbstractLogger)
#define	DDLoggerNode						MCC_PREFIXED_NAME(DDLoggerNode)

//	Protocols
#define	DDLogger							MCC_PREFIXED_NAME(DDLogger)
#define	DDLogFormatter						MCC_PREFIXED_NAME(DDLogFormatter)
#define	DDRegisteredDynamicLogging			MCC_PREFIXED_NAME(DDRegisteredDynamicLogging)

//	Other Symbols
#define	DDExtractFileNameWithoutExtension	MCC_PREFIXED_NAME(DDExtractFileNameWithoutExtension)
#define	DDLogMessageOptions					MCC_PREFIXED_NAME(DDLogMessageOptions)
#define	DDLogMessageCopyFile				MCC_PREFIXED_NAME(DDLogMessageCopyFile)
#define	DDLogMessageCopyFunction			MCC_PREFIXED_NAME(DDLogMessageCopyFunction)


//	From DDFileLogger
//	Classes
#define	DDLogFileManagerDefault				MCC_PREFIXED_NAME(DDLogFileManagerDefault)
#define	DDLogFileFormatterDefault			MCC_PREFIXED_NAME(DDLogFileFormatterDefault)
#define	DDFileLogger						MCC_PREFIXED_NAME(DDFileLogger)
#define	DDLogFileInfo						MCC_PREFIXED_NAME(DDLogFileInfo)

//	Protocols
#define	DDLogFileManager					MCC_PREFIXED_NAME(DDLogFileManager)


//	From DDTTYLogger
//	Classes
#define	DDTTYLogger							MCC_PREFIXED_NAME(DDTTYLogger)
#define	DDTTYLoggerColorProfile				MCC_PREFIXED_NAME(DDTTYLoggerColorProfile)


//	From DDASLLogger
//	Classes
#define	DDASLLogger							MCC_PREFIXED_NAME(DDASLLogger)


//	From DDASLLogCapture
//	Classes
#define	DDASLLogCapture						MCC_PREFIXED_NAME(DDASLLogCapture)


//	From DDAbstractDatabaseLogger
//	Classes
#define	DDAbstractDatabaseLogger			MCC_PREFIXED_NAME(DDAbstractDatabaseLogger)


//	From CLIColor (support file)
//	Classes
#define	CLIColor							MCC_PREFIXED_NAME(CLIColor)

//	Needs to go here to ensure that the defines above are loaded first
#include "DDLog.h"
