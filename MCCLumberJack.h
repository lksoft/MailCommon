//
//  MCCLumberJack.h
//  Logging Framework enabler
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#include "MCCCommonHeader.h"

//	From DDLog.h
//	Classes
#define	DDLog								MCC_PREFIXED_NAME(DDLog)
#define	DDLogMessage						MCC_PREFIXED_NAME(DDLogMessage)
#define	DDAbstractLogger					MCC_PREFIXED_NAME(DDAbstractLogger)

//	Protocols
#define	DDLogger							MCC_PREFIXED_NAME(DDLogger)
#define	DDLogFormatter						MCC_PREFIXED_CONSTANT(DDLogFormatter)
#define	DDRegisteredDynamicLogging			MCC_PREFIXED_CONSTANT(DDRegisteredDynamicLogging)

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
#define	CLIColor			MCC_PREFIXED_NAME(CLIColor)
