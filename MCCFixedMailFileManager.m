//
//  MCCFixedMailFileManager.m
//  SignatureProfiler
//
//  Created by Test LKS on 27/01/16.
//
//

#import "MCCFixedMailFileManager.h"

@implementation MCC_PREFIXED_NAME(FixedMailFileManager)


- (NSString *)defaultLogsDirectory {
	NSArray		*paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString	*basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
	NSString	*mailLibrary = [[[[basePath stringByAppendingPathComponent:@"Containers"] stringByAppendingPathComponent:@"com.apple.mail"] stringByAppendingPathComponent:@"Data"] stringByAppendingPathComponent:@"Library"];
	NSString	*logsDirectory = [[mailLibrary stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:@"Mail"];
	return logsDirectory;
}


@end
