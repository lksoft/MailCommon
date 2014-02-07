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
@property	(assign)	NSInteger		testVersionOS;
@end

@implementation MCC_PREFIXED_NAME(MailAbstractor)

@synthesize mappings = _mappings;
@synthesize testVersionOS = _testVersionOS;

- (id)init {
	self = [super init];
	if (self) {
		self.testVersionOS = -1;
		[self rebuildCurrentMappings];
	}
	return self;
}

- (void)rebuildCurrentMappings {

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

	NSMutableDictionary	*newMappings = [NSMutableDictionary dictionary];
	
	//	Extract all possible mappings
	for (NSDictionary *aDict in translationArray) {
		for (NSString *className in [aDict allValues]) {
			[newMappings setObject:aDict forKey:className];
		}
	}

	//	Trim them down to ones that are relevant on this OS version
	NSString	*osName = [[[NSString alloc] initWithFormat:@"10.%ld", (long)[self osMinorVersion]] autorelease];
	NSMutableDictionary	*trimmedMappings = [NSMutableDictionary dictionary];
	for (NSString *mappingKey in [newMappings allKeys]) {
		//	Get the mapping for this OS version
		NSString	*mappedClassName = [[newMappings objectForKey:mappingKey] objectForKey:osName];
		if (![mappingKey isEqualToString:mappedClassName]) {
			[trimmedMappings setObject:mappedClassName forKey:mappingKey];
		}
	}
	
	self.mappings = [NSDictionary dictionaryWithDictionary:trimmedMappings];
}

//	Method is used only once and could be included in-line, HOWEVER, having it here allows for testing the abstractor by setting the
//		testVersionOS value via KVO (i.e. [[MailAbstractor sharedInstance] setValue:@(7) forKey:@"testVersionOS"])
//	Though be sure to call -[rebuildCurrentMappings] after setthing the version
- (NSInteger)osMinorVersion {
	
	if (self.testVersionOS > 0) {
		return self.testVersionOS;
	}
	// use a static because we only really need to get the version once.
	static NSInteger minVersion = 0;  // 0 == notSet
	if (minVersion == 0) {
		/*
		 
		 Using this method after reading this SO post:
		 http://stackoverflow.com/questions/11072804/mac-os-x-10-8-replacement-for-gestalt-for-testing-os-version-at-runtime
		 
		 */
		NSDictionary	*sv = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
		NSString		*versionString = [sv objectForKey:@"ProductVersion"];
		NSArray			*versionParts = [versionString componentsSeparatedByString:@"."];
		if ([versionParts count] > 1) {
			minVersion = [[versionParts objectAtIndex:1] integerValue];
		}
	}
	
	
	return minVersion;
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
		classNameDictAccessQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
		classNameLookup = [[NSMutableDictionary alloc] init];
	});
	
	//	Using a concurrent queue with a barrier for the reads will avoid any contention, it does
	//		mean that we might get a miss or two on the first time to find a class, but that is not a big deal
	//	Comes from https://mikeash.com/pyblog/friday-qa-2011-10-14-whats-new-in-gcd.html
	Class __block resultClass = nil;
	dispatch_sync(classNameDictAccessQueue, ^{
		resultClass = [classNameLookup objectForKey:aClassName];
	});
	
	if (resultClass){
		return resultClass;
	}
	else{
		resultClass = NSClassFromString(aClassName);
		if (!resultClass) {
			resultClass = NSClassFromString([@"MF" stringByAppendingString:aClassName]);
			
			if (!resultClass) {
				resultClass = NSClassFromString([@"MC" stringByAppendingString:aClassName]);
				
				if (!resultClass) {
					MCC_PREFIXED_NAME(MailAbstractor)	*abstractor = [MCC_PREFIXED_NAME(MailAbstractor) sharedInstance];
					NSString	*nameFound = [abstractor.mappings objectForKey:aClassName];
					if (nameFound) {
						resultClass = NSClassFromString(nameFound);
					}
				}
			}
		}
		if (resultClass) {
			//	Stupid hack to ensure that the +initialize has been called on the class
			//		to avoid a deadlock seen occaisionally (at least on Mountain Lion)
			[resultClass class];
			dispatch_barrier_async(classNameDictAccessQueue, ^{
				[classNameLookup setObject:resultClass forKey:aClassName];
			});
		}
		// NSLog(@"found class %@ -->%@",className,resultClass);
		
	}
	return resultClass;
	
}

