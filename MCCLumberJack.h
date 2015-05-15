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
extern int	MCC_PREFIXED_NAME(DDLogBugs);


@interface MCC_PREFIXED_NAME(LumberJack) : NSObject

+ (void)addStandardLoggersWithFeatureDict:(NSDictionary *)featureDict;
+ (void)addStandardLoggersWithFeatureDict:(NSDictionary *)featureDict forBundleId:(NSString *)aBundleId;
+ (void)addBugLoggerWithDict:(NSDictionary *)bugDict forBundleId:(NSString *)aBundleId;
+ (int)debugLevel;
+ (void)setDebugLevel:(int)newLevel;
+ (void)addLogFeature:(int)newFeature;
+ (void)addLogBug:(int)newBug;

@end


#pragma mark - MCC Macros

#define MCCSecureFormattingContext	(1 << 1)
#define MCCFeatureFormattingContext	(1 << 2)
#define MCCBugFormattingContext	(1 << 3)

#define MCCErr(frmt, ...)						LOG_OBJC_MAYBE(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, 0, frmt, ##__VA_ARGS__)
#define MCCErrC(frmt, ...)						LOG_C_MAYBE(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, 0, frmt, ##__VA_ARGS__)
#define MCCWarn(frmt, ...)						LOG_OBJC_MAYBE(LOG_ASYNC_WARN, LOG_LEVEL_DEF, LOG_FLAG_WARN, 0, frmt, ##__VA_ARGS__)
#define MCCInfo(frmt, ...)						LOG_OBJC_MAYBE(LOG_ASYNC_INFO, LOG_LEVEL_DEF, LOG_FLAG_INFO, 0, frmt, ##__VA_ARGS__)
#define MCCDebug(frmt, ...)						LOG_OBJC_MAYBE(LOG_ASYNC_DEBUG, LOG_LEVEL_DEF, LOG_FLAG_DEBUG, 0, frmt, ##__VA_ARGS__)
#define MCCLogC(frmt, ...)						LOG_C_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)
#define MCCLog(frmt, ...)						LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)
#define MCCLogFeature(featureFlag, frmt, ...)	LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, MCC_PREFIXED_NAME(DDLogFeatures), featureFlag, MCCFeatureFormattingContext, frmt, ##__VA_ARGS__)
#define MCCLogBug(bugFlag, frmt, ...)			LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, MCC_PREFIXED_NAME(DDLogBugs), bugFlag, MCCBugFormattingContext, frmt, ##__VA_ARGS__)


#ifdef MCC_INSECURE_LOGS
	#define DEFAULT_CONTEXT	0
#else
	#define DEFAULT_CONTEXT	MCCSecureFormattingContext
#endif

#define LOG_MACRO_SEC(isAsynchronous, lvl, flg, ctx, fnct, frmt, ...) \
	[DDLog secureLog:isAsynchronous level:lvl flag:flg context:ctx file:__FILE__ function:fnct line:__LINE__ tag:nil format:(frmt), ##__VA_ARGS__]

#define LOG_MAYBE_SEC(async, lvl, flg, ctx, fnct, frmt, ...) \
	do { if(lvl & flg) LOG_MACRO_SEC(async, lvl, flg, ctx, fnct, frmt, ##__VA_ARGS__); } while(0)

#define LOG_OBJC_MAYBE_SEC(async, lvl, flg, ctx, frmt, ...) \
	LOG_MAYBE_SEC(async, lvl, flg, ctx, sel_getName(_cmd), frmt, ##__VA_ARGS__)

#define LOG_C_MAYBE_SEC(async, lvl, flg, ctx, frmt, ...) \
	LOG_MAYBE_SEC(async, lvl, flg, ctx, __FUNCTION__, frmt, ##__VA_ARGS__)

#define FEATURE_LOGGED(flg) \
	(MCC_PREFIXED_NAME(DDLogFeatures) & flg)

#define BUG_LOGGED(flg) \
	(MCC_PREFIXED_NAME(DDLogBugs) & flg)

#define MCCErrS(frmt, ...)						LOG_OBJC_MAYBE_SEC(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, DEFAULT_CONTEXT, frmt, ##__VA_ARGS__)
#define MCCErrCS(frmt, ...)						LOG_C_MAYBE_SEC(LOG_ASYNC_ERROR, LOG_LEVEL_DEF, LOG_FLAG_ERROR, DEFAULT_CONTEXT, frmt, ##__VA_ARGS__)
#define MCCWarnS(frmt, ...)						LOG_OBJC_MAYBE_SEC(LOG_ASYNC_WARN, LOG_LEVEL_DEF, LOG_FLAG_WARN, DEFAULT_CONTEXT, frmt, ##__VA_ARGS__)
#define MCCInfoS(frmt, ...)						LOG_OBJC_MAYBE_SEC(LOG_ASYNC_INFO, LOG_LEVEL_DEF, LOG_FLAG_INFO, DEFAULT_CONTEXT, frmt, ##__VA_ARGS__)
#define MCCDebugS(frmt, ...)					LOG_OBJC_MAYBE_SEC(LOG_ASYNC_DEBUG, LOG_LEVEL_DEF, LOG_FLAG_DEBUG, DEFAULT_CONTEXT, frmt, ##__VA_ARGS__)
#define MCCLogS(frmt, ...)						LOG_OBJC_MAYBE_SEC(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, DEFAULT_CONTEXT, frmt, ##__VA_ARGS__)
#define MCCLogFeatureS(featureFlag, frmt, ...)	LOG_OBJC_MAYBE_SEC(LOG_ASYNC_VERBOSE, MCC_PREFIXED_NAME(DDLogFeatures), featureFlag, (DEFAULT_CONTEXT | MCCFeatureFormattingContext), frmt, ##__VA_ARGS__)
#define MCCLogBugS(bugFlag, frmt, ...)			LOG_OBJC_MAYBE_SEC(LOG_ASYNC_VERBOSE, MCC_PREFIXED_NAME(DDLogBugs), bugFlag, (DEFAULT_CONTEXT | MCCBugFormattingContext), frmt, ##__VA_ARGS__)



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


@interface DDLog (MCCLumberJack)
+ (void)secureLog:(BOOL)asynchronous level:(int)level flag:(int)flag context:(int)context file:(const char *)file function:(const char *)function line:(int)line tag:(id)tag format:(NSString *)format, ...;
@end
