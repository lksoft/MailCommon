//
//  MCCDefaults.m
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCDefaults.h"
#import "MCCFileEventQueue.h"

#define PREF_FILE_NOTIFICATIONS	(MCCNotifyAboutFileDelete | MCCNotifyAboutFileWrite)


@interface MCC_PREFIXED_NAME(Defaults) ()
@property (assign) BOOL delegateWantsBackups;
@property (strong, atomic) NSDictionary * defaultDictionary;
@property (strong) NSURL * defaultsURL;
@property (strong) NSOperationQueue * prefsAccessQueue;
@property (assign) id<MCC_PREFIXED_NAME(DefaultsDelegate)> delegate;
@property (strong) MCC_PREFIXED_NAME(FileEventQueue) * fileEventQueue;
@property (strong) MCC_PREFIXED_NAME(PathBlock) prefsChangeBlock;
@end


@implementation MCC_PREFIXED_NAME(Defaults)

- (instancetype)initWithDelegate:(id)aDelegate {
	self = [super init];
	if (self) {

		self.delegate = aDelegate;
		self.delegateWantsBackups = [aDelegate respondsToSelector:@selector(backupCurrentDefaultsBeforeWriteAtURL:)];
		
		NSBundle * bundle = [NSBundle bundleForClass:[self class]];
		
		NSFileManager * manager = [NSFileManager defaultManager];
		NSArray * libraryURLs = [manager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
		if ([libraryURLs count]) {
			NSURL * tempURL = [[libraryURLs lastObject] URLByAppendingPathComponent:@"Preferences"];
			self.defaultsURL = [[tempURL URLByAppendingPathComponent:[bundle bundleIdentifier]] URLByAppendingPathExtension:@"plist"];
		}
		
		//	Load up initial values and current ones
		NSMutableDictionary * defaults = nil;
		NSURL * initialDefaultsURL = [bundle URLForResource:@"InitialDefaults" withExtension:@"plist"];
		if ([manager fileExistsAtPath:initialDefaultsURL.path]) {
			defaults = [[NSDictionary dictionaryWithContentsOfURL:initialDefaultsURL] mutableCopy];
		}
		else {
			defaults = [[NSMutableDictionary alloc] init];
		}
		NSDictionary * storedDefaults = [self readFromFile];
		if (storedDefaults) {
			[defaults addEntriesFromDictionary:storedDefaults];
		}
		
		//	Allow a subclass to adjust defaults
		if ([self.delegate respondsToSelector:@selector(finishPreparingDefaultsWithDictionary:)]) {
			[self.delegate finishPreparingDefaultsWithDictionary:defaults];
		}
		
		//	Set values and the read time
		self.defaultDictionary = [NSDictionary dictionaryWithDictionary:defaults];
		
		if (![self.defaultDictionary isEqualToDictionary:storedDefaults]){
			[self writeToFile];
		}
		MCC_RELEASE(defaults);
		
		self.fileEventQueue = MCC_AUTORELEASE([[MCC_PREFIXED_NAME(FileEventQueue) alloc] init]);
		MCC_PREFIXED_NAME(Defaults) * blockSelf = self;
		self.prefsChangeBlock = ^(MCC_PREFIXED_NAME(FileEventQueue) *anEventQueue, NSString * aNote, NSString * anAffectedPath) {
			if ([anAffectedPath isEqualToString:initialDefaultsURL.path]) {
				[blockSelf updateFromFileEvent];
			}
		};
		[self.fileEventQueue addAtomicPath:initialDefaultsURL.path withBlock:self.prefsChangeBlock notifyingAbout:PREF_FILE_NOTIFICATIONS];
		
		//	Create a serial queue to use
		self.prefsAccessQueue = MCC_AUTORELEASE([[NSOperationQueue alloc] init]);
		[self.prefsAccessQueue setMaxConcurrentOperationCount:1];

	}
	return self;
}

- (NSDictionary *)allDefaults {
	return MCC_AUTORELEASE([self.defaultDictionary copy]);
}


#pragma mark - Public Accessors

+ (id)defaultForKey:(NSString *)key {
    return [[self sharedDefaults] _defaultForKey:key];
}

+ (id)objectForKey:(NSString *)key {
    return [[self sharedDefaults] _defaultForKey:key];
}

+ (BOOL)boolForKey:(NSString *)key {
    return [[[self sharedDefaults] _defaultForKey:key] boolValue];
}

+ (NSInteger)integerForKey:(NSString *)key {
	return [[[self sharedDefaults] _defaultForKey:key] integerValue];
}

+ (CGFloat)floatForKey:(NSString *)key {
	return [[[self sharedDefaults] _defaultForKey:key] floatValue];
}

+ (NSDictionary *)defaultsForKeys:(NSArray *)keys {
    return [[self sharedDefaults] _defaultsForKeys:keys];
}

+ (void)setDefault:(id)value forKey:(NSString *)key {
    if (!value) {
		[[self sharedDefaults] removeDefaultForKeyOnMainThread:key];
	}
	else {
        [[self sharedDefaults] setDefaultsWithDictionaryOnMainThread:@{key: value}];
	}
}

+ (void)setObject:(id)value forKey:(NSString *)key {
	[self setDefault:value forKey:key];
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
	[self setDefault:@(value) forKey:key];
}

+ (void)setInteger:(NSInteger)value forKey:(NSString *)key {
	[self setDefault:@(value) forKey:key];
}

+ (void)setFloat:(CGFloat)value forKey:(NSString *)key {
	[self setDefault:@(value) forKey:key];
}

+ (void)setDefaultsForDictionary:(NSDictionary *)newValues {
	[[self sharedDefaults] setDefaultsWithDictionaryOnMainThread:newValues];
}


#pragma mark - Internal Methods

- (NSDictionary *)readFromFile {
    NSDictionary * storedDefaults = nil;
    if (self.defaultsURL) {
        storedDefaults = [NSDictionary dictionaryWithContentsOfURL:self.defaultsURL];
    }
    return storedDefaults;
}

- (void)updateFromFileEvent {

	//	Read the file using our queue
	MCC_PREFIXED_NAME(Defaults) * blockSelf = self;
	NSDictionary __block * fileDefaults = nil;
	[self.prefsAccessQueue addOperations:@[[NSBlockOperation blockOperationWithBlock:^{
		fileDefaults = [blockSelf readFromFile];
	}]] waitUntilFinished:YES];

	//	Then set the value using the main queue for the KVO stuff
	NSDictionary * currentDefaults = [self.defaultDictionary copy];
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		NSMutableArray * changedKeys = [NSMutableArray array];
		
		NSSet * allKeySet = [[NSSet setWithArray:[fileDefaults allKeys]] setByAddingObjectsFromArray:[currentDefaults allKeys]];
		for (id key in allKeySet) {
			id value = [fileDefaults objectForKey:key];
			
			if (value == nil) {
				[self willChangeValueForKey:key];
				[changedKeys addObject:key];
			}
			else if (![[currentDefaults objectForKey:key] isEqualTo:value]) {
				[self willChangeValueForKey:key];
				[changedKeys addObject:key];
			}
		}

		self.defaultDictionary = fileDefaults;
		[self writeToFile];
		for (id key in changedKeys){
			[self didChangeValueForKey:key];
		}
	}];

}

- (void)writeToFile {
    if (self.defaultsURL && self.defaultDictionary) {
		BOOL wantsBackups = self.delegateWantsBackups;
		id<MCC_PREFIXED_NAME(DefaultsDelegate)> theDelegate = self.delegate;
		NSURL * theURL = self.defaultsURL;
		NSDictionary * theDict = self.defaultDictionary;
		MCC_PREFIXED_NAME(FileEventQueue) * eventQueue = self.fileEventQueue;
		[self.prefsAccessQueue addOperationWithBlock:^{
			if (wantsBackups) {
				[theDelegate backupCurrentDefaultsBeforeWriteAtURL:theURL];
			}
			//	Remove any file event notification to not get it from ourselves
			[eventQueue removePath:theURL.path];
			[theDict writeToURL:theURL atomically:YES];
			[eventQueue addAtomicPath:theURL.path withBlock:self.prefsChangeBlock notifyingAbout:PREF_FILE_NOTIFICATIONS];
		}];
    }
}

- (void)removeDefaultForKeyOnMainThread:(NSString*)key {
	if (![NSThread isMainThread]){
		[self performSelectorOnMainThread:_cmd withObject:key waitUntilDone:NO];
		return;
	}
	
	NSMutableDictionary * plugInDefaults = MCC_AUTORELEASE([self.defaultDictionary mutableCopy]);
	if (!plugInDefaults) {
		NSLog(@"Defaults is empty -- this should not happen");
		// do not register these defaults -- just return.
		return;
	}
	
	if (key && [plugInDefaults objectForKey:key]) {
		[self willChangeValueForKey:key];
		[plugInDefaults removeObjectForKey:key];
		[self didChangeValueForKey:key];
	}
	else {
		return;
	}
	
	self.defaultDictionary = [NSDictionary dictionaryWithDictionary:plugInDefaults];
	[self writeToFile];
}


- (void)setDefaultsWithDictionaryOnMainThread:(NSDictionary *)dictionary {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:dictionary waitUntilDone:NO];
		return;
	}
	
	NSMutableDictionary * plugInDefaults = MCC_AUTORELEASE([self.defaultDictionary mutableCopy]);
	if (!plugInDefaults) {
		NSLog(@"Defaults is empty -- this should not happen");
		// do not register these defaults -- just return.
		return;
	}
	
	NSMutableArray * changedKeys = [NSMutableArray array];
	for (id key in [dictionary allKeys]) {
		id value = [dictionary objectForKey:key];
		
		if (value && key) {
			if (![[plugInDefaults objectForKey:key] isEqualTo:value]) {
				[self willChangeValueForKey:key];
				[plugInDefaults setObject:value forKey:key];
				[changedKeys addObject:key];
			}
		}
	}
	
	//	Don't bother if nothing is different
	if ([changedKeys count] == 0) {
		return;
	}
	
	self.defaultDictionary = plugInDefaults;
	[self writeToFile];
	for (id key in changedKeys){
		[self didChangeValueForKey:key];
	}
}

- (NSDictionary *)_defaultsForKeys:(NSArray *)keys {
    NSMutableDictionary __block * result = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
	NSDictionary * blockDefaults = self.defaultDictionary;
	NSOperation * theReadBlock = [NSBlockOperation blockOperationWithBlock:^{
		for (id aKey in keys){
			id value = [blockDefaults objectForKey:aKey];
			if (value) {
				[result setValue:value forKey:aKey];
			}
		}
	}];

	//	Throw on our queue and wait for the result
	[self.prefsAccessQueue addOperations:@[theReadBlock] waitUntilFinished:YES];
	
	return result;
}


- (id)_defaultForKey:(NSString *)key {
	id	__block result = nil;
	NSDictionary * blockDefaults = self.defaultDictionary;
	NSOperation * theReadBlock = [NSBlockOperation blockOperationWithBlock:^{
		result = [blockDefaults objectForKey:key];
	}];
	
	//	Throw on our queue and wait for the result
	[self.prefsAccessQueue addOperations:@[theReadBlock] waitUntilFinished:YES];
	
    return result;
}


#pragma mark - Class Management

+ (instancetype)sharedDefaults {
	return [self makeSharedDefaultsWithDelegate:nil];
}

+ (instancetype)makeSharedDefaultsWithDelegate:(id<MCC_PREFIXED_NAME(DefaultsDelegate)>)aDelegate {
	static MCC_PREFIXED_NAME(Defaults) * theDefaults = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theDefaults = MCC_RETAIN([[self alloc] initWithDelegate:aDelegate]);
	});
	return theDefaults;
}


@end
