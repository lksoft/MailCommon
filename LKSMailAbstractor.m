//
//  LKSMailAbstractor.m
//  Tealeaves
//
//  Created by Scott Little on 14/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "LKSMailAbstractor.h"

NSInteger osMinorVersion(void);

@interface PREFIXED_FUNCTION_NAME(MailAbstractor) : NSObject {
	NSDictionary	*_mappings;
}

@property	(retain)	NSDictionary	*mappings;

+ (NSString *)actualClassNameForClassName:(NSString *)aClassName;
+ (Class)actualClassForClassName:(NSString *)aClassName;
+ (PREFIXED_FUNCTION_NAME(MailAbstractor)*)sharedInstance;

@end

@implementation PREFIXED_FUNCTION_NAME(MailAbstractor)

@synthesize mappings = _mappings;

- (id)init {
	self = [super init];
	if (self) {
		//	This array could be a plist file that we read in
		NSArray	*translationArray = @[
			@{@"10.7": @"MailAccount", @"10.8": @"MailAccount", @"10.9": @"MFMailAccount"},
			@{@"10.7": @"Message", @"10.8": @"Message", @"10.9": @"MCMessage"},
		];
		[self buildCompleteMappingsFromArray:translationArray];
	}
	return self;
}

- (void)buildCompleteMappingsFromArray:(NSArray *)translationArray {
	NSMutableDictionary	*newMappings = [NSMutableDictionary dictionary];
	
	for (NSDictionary *aDict in translationArray) {
		for (NSString *className in [aDict allValues]) {
			[newMappings setObject:aDict forKey:className];
		}
	}
	
	self.mappings = [NSDictionary dictionaryWithDictionary:newMappings];
}

+ (NSString *)actualClassNameForClassName:(NSString *)aClassName {
	NSString	*nameFound = nil;
	
	//	If the class exists, just use that
	if (NSClassFromString(aClassName)) {
		return aClassName;
	}
	
	//	Try to find a mapping, if none, return original
	PREFIXED_FUNCTION_NAME(MailAbstractor)	*abstractor = [PREFIXED_FUNCTION_NAME(MailAbstractor) sharedInstance];
	NSDictionary	*mappingDict = [abstractor.mappings objectForKey:aClassName];
	if (mappingDict == nil) {
		return aClassName;
	}

	//	Try to get the mapping for this OS version and use that as the return value
	NSString	*osName = [NSString stringWithFormat:@"10.%d", osMinorVersion()];
	nameFound = [mappingDict valueForKey:osName];
	
	return nameFound;
}

+ (Class)actualClassForClassName:(NSString *)aClassName {
	return NSClassFromString([self actualClassNameForClassName:aClassName]);
}


+ (PREFIXED_FUNCTION_NAME(MailAbstractor)*)sharedInstance {
	static	PREFIXED_FUNCTION_NAME(MailAbstractor)	*myAbstractor = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		myAbstractor = [[[self class] alloc] init];
	});
	return myAbstractor;
}

@end

Class PREFIXED_FUNCTION_NAME(ClassForMailObject)(NSString *aClassName) {
	return [PREFIXED_FUNCTION_NAME(MailAbstractor) actualClassForClassName:aClassName];
}

NSInteger osMinorVersion(void) {
	// use a static because we only really need to get the version once.
	static NSInteger minVersion = 0;  // 0 == notSet
	if (minVersion == 0) {
		SInt32 version = 0;
		OSErr err = Gestalt(gestaltSystemVersionMinor, &version);
		if (!err) {
			minVersion = (NSInteger)version;
		}
	}
	return minVersion;
}

