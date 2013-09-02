//
// MCCMailAbstractor.m
//  MailCommonCode
//
//  Created by Scott Little on 14/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "MCCMailAbstractor.h"


@interface MCC_PREFIXED_NAME(MailAbstractor) : NSObject {
	NSDictionary	*_mappings;
	NSInteger		_testVersionOS;
}

@property	(strong)	NSDictionary	*mappings;

+ (NSString *)actualClassNameForClassName:(NSString *)aClassName;
+ (Class)actualClassForClassName:(NSString *)aClassName;
+ (MCC_PREFIXED_NAME(MailAbstractor)*)sharedInstance;

@end

@implementation MCC_PREFIXED_NAME(MailAbstractor)

@synthesize mappings = _mappings;

- (id)init {
	self = [super init];
	if (self) {
		//	This array could be a plist file that we read in
		NSFileManager	*manager = [NSFileManager defaultManager];
		NSString		*resourcePlistPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MailVersionClassMappings" ofType:@"plist"];
		NSArray			*translationArray = [NSArray array];
		if ([manager fileExistsAtPath:resourcePlistPath]) {
			translationArray = [translationArray arrayByAddingObjectsFromArray:[NSArray arrayWithContentsOfFile:resourcePlistPath]];
		}
		resourcePlistPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"PluginClassMappings" ofType:@"plist"];
		if ([manager fileExistsAtPath:resourcePlistPath]) {
			translationArray = [translationArray arrayByAddingObjectsFromArray:[NSArray arrayWithContentsOfFile:resourcePlistPath]];
		}
		[self buildCompleteMappingsFromArray:translationArray];
		_testVersionOS = -1;
	}
	return self;
}

- (NSInteger)osMinorVersion {
	
	if (_testVersionOS > 0) {
		return _testVersionOS;
	}
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
	MCC_PREFIXED_NAME(MailAbstractor)	*abstractor = [MCC_PREFIXED_NAME(MailAbstractor) sharedInstance];
	NSDictionary	*mappingDict = [abstractor.mappings objectForKey:aClassName];
	if (mappingDict == nil) {
		return aClassName;
	}

	//	Try to get the mapping for this OS version and use that as the return value
	NSString	*osName = [NSString stringWithFormat:@"10.%ld", (long)[[self sharedInstance] osMinorVersion]];
	nameFound = [mappingDict valueForKey:osName];
	
	return nameFound;
}

+ (Class)actualClassForClassName:(NSString *)aClassName {
	return NSClassFromString([self actualClassNameForClassName:aClassName]);
}


+ (MCC_PREFIXED_NAME(MailAbstractor)*)sharedInstance {
	static	MCC_PREFIXED_NAME(MailAbstractor)	*myAbstractor = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		myAbstractor = [[[self class] alloc] init];
	});
	return myAbstractor;
}

@end


Class MCC_PREFIXED_NAME(ClassFromString)(NSString *aClassName) {
	
	static NSMutableDictionary	*classNameLookup = nil;
	static dispatch_queue_t		classNameDictAccessQueue = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString	*queueName = [NSString stringWithFormat:@"com.mailPlugins.dictAccessQueue.%@", NSStringFromClass([MCC_PREFIXED_NAME(MailAbstractor) class])];
		classNameDictAccessQueue = dispatch_queue_create([queueName UTF8String], NULL);
	});
	
	
	Class __block resultClass =nil;
	
	dispatch_sync(classNameDictAccessQueue, ^{
		resultClass = [classNameLookup objectForKey:aClassName];
	});
	
	if (resultClass){
		return resultClass;
	}
	else{
		resultClass = NSClassFromString(aClassName);
		if (!resultClass){
			resultClass = NSClassFromString([@"MF" stringByAppendingString:aClassName]);
		}
		if (!resultClass){
			resultClass = NSClassFromString([@"MC" stringByAppendingString:aClassName]);
		}
		if (!resultClass){
			resultClass = [MCC_PREFIXED_NAME(MailAbstractor) actualClassForClassName:aClassName];
		}
		if (!resultClass) {
			return nil;
		}
		else {
			dispatch_async(classNameDictAccessQueue, ^{
				[classNameLookup setObject:resultClass forKey:aClassName];
			});
		}
		// NSLog(@"found class %@ -->%@",className,resultClass);
		return resultClass;
		
	}
	return nil;
	
}

