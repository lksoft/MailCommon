//
//  MCCDefaults.m
//  MCCMailCommon
//
//  Created by Scott Little on 22/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCDefaults.h"

#define MCC_DEFAULT_READ_INTERVAL	5

@interface MCC_PREFIXED_NAME(Defaults) ()
@property (strong, atomic) NSDictionary	*defaultDictionary;
@property (strong) NSURL				*defaultsURL;
@property (assign) NSTimeInterval		lastDiskReadTime;
@property (assign) id					delegate;
@end


@implementation MCC_PREFIXED_NAME(Defaults)

- (instancetype)initWithDelegate:(id)aDelegate {
	self = [super init];
	if (self) {

		self.delegate = aDelegate;
		self.readInterval = MCC_DEFAULT_READ_INTERVAL;
		
		NSBundle	*bundle = [NSBundle bundleForClass:[self class]];
		
		NSFileManager	*manager = [NSFileManager defaultManager];
		NSArray	*libraryURLs = [manager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
		if ([libraryURLs count]) {
			NSURL	*tempURL = [[libraryURLs lastObject] URLByAppendingPathComponent:@"Preferences"];
			self.defaultsURL = [[tempURL URLByAppendingPathComponent:[bundle bundleIdentifier]] URLByAppendingPathExtension:@"plist"];
		}
		
		//	Load up initial values and current ones
		NSMutableDictionary *defaults = nil;
		NSURL	*initialDefaultsURL = [bundle URLForResource:@"InitialDefaults" withExtension:@"plist"];
		if ([manager fileExistsAtPath:[initialDefaultsURL path]]) {
			defaults = [[NSDictionary dictionaryWithContentsOfURL:initialDefaultsURL] mutableCopy];
		}
		else {
			defaults = [[NSMutableDictionary alloc] init];
		}
		NSDictionary	*storedDefaults = [self readFromFile];
		if (storedDefaults) {
			[defaults addEntriesFromDictionary:storedDefaults];
		}
		
		//	Allow a subclass to adjust defaults
		if ([self.delegate respondsToSelector:@selector(finishPreparingDefaultsWithDictionary:)]) {
			[self.delegate finishPreparingDefaultsWithDictionary:defaults];
		}
		
		//	Set values and the read time
		self.defaultDictionary = [NSDictionary dictionaryWithDictionary:defaults];
		self.lastDiskReadTime = [[NSDate date] timeIntervalSinceReferenceDate];
		
		if (![self.defaultDictionary isEqualToDictionary:storedDefaults]){
			[self writeToFile];
		}
		RELEASE(defaults);

	}
	return self;
}

- (NSDictionary *)allDefaults {
	return AUTORELEASE([self.defaultDictionary copy]);
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
    NSDictionary	*storedDefaults = nil;
    if (self.defaultsURL) {
        storedDefaults = [NSDictionary dictionaryWithContentsOfURL:self.defaultsURL];
    }
    return storedDefaults;
}

- (void)writeToFile {
    if (self.defaultsURL && self.defaultDictionary) {
		if ([self.delegate respondsToSelector:@selector(backupCurrentDefaultsBeforeWriteAtURL:)]) {
			[self.delegate backupCurrentDefaultsBeforeWriteAtURL:self.defaultsURL];
		}
        [self.defaultDictionary writeToURL:self.defaultsURL atomically:YES];
		self.lastDiskReadTime = [NSDate timeIntervalSinceReferenceDate];
    }
}

- (void)removeDefaultForKeyOnMainThread:(NSString*)key {
	if (![NSThread isMainThread]){
		[self performSelectorOnMainThread:_cmd withObject:key waitUntilDone:NO];
		return;
	}
	
	NSMutableDictionary *plugInDefaults = [[self readFromFile] mutableCopy];
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
	
	self.defaultDictionary = [NSDictionary dictionaryWithDictionary:plugInDefaults];
	[self writeToFile];
	RELEASE(plugInDefaults);
}


- (void)setDefaultsWithDictionaryOnMainThread:(NSDictionary *)dictionary {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:dictionary waitUntilDone:NO];
		return;
	}
	
	NSMutableDictionary *plugInDefaults = [[self readFromFile] mutableCopy];
	if (!plugInDefaults) {
		NSLog(@"Defaults is empty -- this should not happen");
		// do not register these defaults -- just return.
		return;
	}
	
	NSMutableArray	*changedKeys = [NSMutableArray array];
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
	
	self.defaultDictionary = plugInDefaults;
	[self writeToFile];
	for (id key in changedKeys){
		[self didChangeValueForKey:key];
	}
	RELEASE(plugInDefaults);
}

- (void)checkCache {
    if (([NSDate timeIntervalSinceReferenceDate] - self.lastDiskReadTime) > self.readInterval) {
        self.defaultDictionary = [self readFromFile];
        self.lastDiskReadTime = [NSDate timeIntervalSinceReferenceDate];
    }
}

- (NSDictionary *)_defaultsForKeys:(NSArray *)keys {
	[self checkCache];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
    for (id aKey in keys){
        id value = [self.defaultDictionary objectForKey:aKey];
        if (value) {
			[result setValue:value forKey:aKey];
		}
    }
	return result;
}


- (id)_defaultForKey:(NSString *)key {
	[self checkCache];
    return [self.defaultDictionary objectForKey:key];
}


#pragma mark - Class Management

+ (instancetype)sharedDefaults {
	return [self makeSharedDefaultsWithDelegate:nil];
}

+ (instancetype)makeSharedDefaultsWithDelegate:(id)aDelegate {
	static	MCC_PREFIXED_NAME(Defaults)	*theDefaults = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theDefaults = RETAIN([[self alloc] initWithDelegate:aDelegate]);
	});
	return theDefaults;
}

+ (void)resetCache {
	MCC_PREFIXED_NAME(Defaults)	*defaults = [self sharedDefaults];
	defaults.lastDiskReadTime = 0;
}


@end
