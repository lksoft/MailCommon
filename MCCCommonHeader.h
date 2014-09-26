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
#define	MCC_PREFIXED_NAME(symbol)		_MCC_CONCAT(MCC_PLUGIN_PREFIX,symbol)
#define	MCC_PREFIXED_CONSTANT(symbol)	_MCC_CONCAT(_MCC_CONCAT(k, MCC_PLUGIN_PREFIX),symbol)
#define	MCC_SUFFIXED_NAME(symbol)		_MCC_CONCAT(symbol, _MCC_CONCAT(_, MCC_PLUGIN_PREFIX) )
#else
#define	MCC_PREFIXED_NAME(symbol)		_MCC_CONCAT(MCC,symbol)
#define	MCC_PREFIXED_CONSTANT(symbol)	_MCC_CONCAT(kMCC,symbol)
#define	MCC_SUFFIXED_NAME(symbol)		_MCC_CONCAT(symbol,_MCC)
#endif	//	MCC_PLUGIN_PREFIX

#define _MCC_AS_STR(a)				#a
#define _MCC_CONCAT_AS_STR(a, b)	_MCC_AS_STR( a ## b )
#define _MCC_NS_STR(a)				@a
#define MCC_NSSTRING(a, b)			_MCC_NS_STR(_MCC_CONCAT_AS_STR(a, b))

//	ARC compatibility
#if __has_feature(objc_arc)
#define MCC_RETAIN(x) (x)
#define MCC_RELEASE(x)
#define MCC_AUTORELEASE(x) (x)
#define MCC_DEALLOC(x) (x)
#else
#define MCC_RETAIN(x) ([(x) retain])
#define MCC_RELEASE(x) ([(x) release])
#define MCC_AUTORELEASE(x) ([(x) autorelease])
#define MCC_DEALLOC(x) ([(x) dealloc])
#endif

#define MCCLogMailVersion() \
do { \
	SEL commonMailInfoKey = NSSelectorFromString(@"CommonMailInfoKey"); \
	NSString	*mailVersionInfo = objc_getAssociatedObject(NSApp,commonMailInfoKey); \
	if (!mailVersionInfo) { \
		NSDictionary	*OSVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"]; \
		NSString		*OSBuild = [OSVersionDictionary objectForKey:@"ProductBuildVersion"]; \
		NSString		*OSVersion = [OSVersionDictionary objectForKey:@"ProductVersion"]; \
		NSMutableString	*mailVersionInformation = [NSMutableString stringWithFormat:@"\n\t\tLoaded Mail Version %@ (%@)\n\t\tOS X Version %@ (%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], OSVersion,OSBuild]; \
		[mailVersionInformation appendFormat:@"\n\t\tInstalled Bundles:"]; \
		NSArray			*pathsToSearch = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask|NSLocalDomainMask|NSSystemDomainMask, YES); \
		NSFileManager	*fm = [NSFileManager defaultManager]; \
		for (NSString *pathToSeach in pathsToSearch) { \
			NSString	*mailLibraryPath =[pathToSeach stringByAppendingPathComponent:@"Mail"]; \
			NSString	*bundles = [mailLibraryPath stringByAppendingPathComponent:@"Bundles"]; \
			NSError		*fmError = nil; \
			NSArray		*dirContents = [fm contentsOfDirectoryAtPath:bundles error:&fmError]; \
			for (NSString *bundlePath in dirContents) { \
				if ([bundlePath hasSuffix:@"mailbundle"]) { \
					NSString		*fullPath = [[bundles stringByAppendingPathComponent:bundlePath] stringByResolvingSymlinksInPath]; \
					NSString		*infoPlistPath = [fullPath stringByAppendingPathComponent:@"Contents/info.plist"]; \
					NSDictionary	*infoDict = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath]; \
					[mailVersionInformation appendFormat:@"\n\t\t\t%@ [%@ (%@)]", fullPath, [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]]; \
				} \
			} \
		} \
		NSLog (@"%@", mailVersionInformation); \
NSLog(@"This is here"); \
		objc_setAssociatedObject(NSApp, commonMailInfoKey, mailVersionInformation, OBJC_ASSOCIATION_RETAIN); \
	} \
} while (NO);


