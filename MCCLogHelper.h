/*!
	File:	MCCLogHelper.h
 */

#import <Cocoa/Cocoa.h>


/*****
 *
 *	Without handling this as a sharedInstance, you wouldn't be able to share the class and use the
 *		simple function calls, which fit better with logging.
 *
 *  Functions to allow for simple management of the logging by the
 *		developer and by the end user if the code is in a beta state
 *		of course these logs should always be set to off for deployment
 *		releases.
 *
 *  Set DEBUG_OUTPUT_OFF to stop all logging when building.
 *	Set MCC_INSECURE_LOGS to have potentially personal contents displayed in logs (i.e. should not be set for Release builds)
 *	Set BUNDLE_ID (as the app/plugin's identifier) in it's pch file before the import for this file.
 *  Set MCC_PREFIXED_NAME(CurrentDebugLogLevel) in the applications preferences file
 *		to change the level at runtime
 *
 *	Call [[MCC_PREFIXED_NAME(LogHelper) sharedInstance] setLogsActive:(BOOL) andLogLevel:(NSInteger) forID:(NSString *)] as soon as possible to init
 *
 *****/

#include "MCCCommonHeader.h"

void MCC_PREFIXED_NAME(FormatLog)(NSString *aBundleID, NSInteger level, BOOL isSecure, const char *file, int lineNum, const char *method, NSString *prefix, NSString *format, ...);

//  default level used when calling from MCC_PREFIXED_NAME(Log) (will almost always log)
#define kDefaultLevel	9
#define kIgnoreLevel	-1
#define	kNotInited	-2
#define kConfiguredLogLevelKey	MCC_NSSTRING(MCC_PLUGIN_PREFIX, CurrentDebugLogLevel)
#define kConfiguredDebuggingKey	MCC_NSSTRING(MCC_PLUGIN_PREFIX, DebuggingIsOn)

#define kBundleKeyUndefined		@"not-set"

//	then set the define if it isn't yet defined
#ifndef BUNDLE_ID
#define BUNDLE_ID kBundleKeyUndefined
#endif

//	If another Log is defined, undef it
#ifdef	MCCLog
#undef	MCCLog
#endif

//	these defines hide the actual calls that include the correct local BUNDLE_ID
//		if the logging is turned off make this more efficient, by doing nothing
#ifndef DEBUG_OUTPUT_OFF
#define kDebugEnabled			YES
#define	MCCZLog(i, s, ...)		MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, i, YES, __FILE__, __LINE__, __PRETTY_FUNCTION__, @"[DEBUG:%d]:", s, ## __VA_ARGS__)
#define	MCCLog(s, ...)			MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, NO, NULL, 0, __PRETTY_FUNCTION__, @"[DEBUG]:", s, ## __VA_ARGS__)
#else
#define kDebugEnabled			NO
#define MCCZLog(i, s, ...)
#define MCCLog(s, ...)
#endif

#define MCCSecureLog(s, ...)	MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, YES, __FILE__, __LINE__, __PRETTY_FUNCTION__, @"[DEBUG]:", s, ## __VA_ARGS__)
#define	MCCInfo(s, ...)		MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, NO, NULL, 0, NULL,  @"[INFO]:", s, ## __VA_ARGS__)
#define	MCCInfoSecure(s, ...)	MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, YES, NULL, 0, NULL,  @"[INFO]:", s, ## __VA_ARGS__)

#ifndef WARN_OUTPUT_OFF
#define	MCCWarn(s, ...)			MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, NO, NULL, 0, __PRETTY_FUNCTION__,  @"[WARNING]:", s, ## __VA_ARGS__)
#define	MCCWarnSecure(s, ...)	MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, YES, NULL, 0, __PRETTY_FUNCTION__,  @"[WARNING]:", s, ## __VA_ARGS__)
#else
#define	MCCWarn(s, ...)
#define	MCCWarnSecure(s, ...)
#endif

#ifndef ERROR_OUTPUT_OFF
#define	MCCErr(s, ...)			MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, NO, NULL, 0, __PRETTY_FUNCTION__,  @"[ERROR]:", s, ## __VA_ARGS__)
#define	MCCErrorSecure(s, ...)	MCC_PREFIXED_NAME(FormatLog)(BUNDLE_ID, kIgnoreLevel, YES, NULL, 0, __PRETTY_FUNCTION__,  @"[ERROR]:", s, ## __VA_ARGS__)
#else
#define	MCCErr(s, ...)
#define	MCCErrorSecure(s, ...)
#endif

@interface MCC_PREFIXED_NAME(LogHelper) : NSObject {
}

+ (MCC_PREFIXED_NAME(LogHelper) *)sharedInstance;

- (BOOL)debuggingOnForBundleID:(NSString *)aBundleID;
- (NSInteger)logLevelForBundleID:(NSString *)aBundleID;

- (void)setLogsActive:(BOOL)active andLogLevel:(NSInteger)level forID:(NSString *)bundleID;

@end
