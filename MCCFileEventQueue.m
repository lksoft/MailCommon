//
//  MCCFileEventQueue.m
//  MCCMailCommon
//
//  Created by Scott Little on 23/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCFileEventQueue.h"

#include <sys/event.h>
//#import <unistd.h>
//#import <fcntl.h>
//#include <sys/stat.h>


NSString	*MCC_PREFIXED_NAME(FileEventRenameNotification) = @"MCCFileEventRenameNotification";
NSString	*MCC_PREFIXED_NAME(FileEventWriteNotification) = @"MCCFileEventWriteNotification";
NSString	*MCC_PREFIXED_NAME(FileEventDeleteNotification) = @"MCCFileEventDeleteNotification";
NSString	*MCC_PREFIXED_NAME(FileEventAttributeChangeNotification) = @"MCCFileEventAttributeChangeNotification";
NSString	*MCC_PREFIXED_NAME(FileEventSizeIncreaseNotification) = @"MCCFileEventSizeIncreaseNotification";
NSString	*MCC_PREFIXED_NAME(FileEventLinkCountChangeNotification) = @"MCCFileEventLinkCountChangeNotification";
NSString	*MCC_PREFIXED_NAME(FileEventAccessRevocationNotification) = @"MCCFileEventAccessRevocationNotification";


//  This is a simple model class used to hold info about each path we watch.
@interface MCC_PREFIXED_NAME(PathEntry) : NSObject

@property (atomic, strong) NSString				*path;
@property (atomic, assign) BOOL					handleAtomically;
@property (atomic, assign) int					watchedFD;
@property (atomic, assign) NSUInteger			subscriptionFlags;
@property (strong) MCC_PREFIXED_NAME(PathBlock)	block;

- (id)initWithPath:(NSString *)aPath block:(MCC_PREFIXED_NAME(PathBlock))aBlock subscriptionFlags:(NSUInteger)flags atomically:(BOOL)isAtomic;

@end


@interface MCC_PREFIXED_NAME(ProcessEntry) : NSObject

@property (strong)	NSString									*name;
@property (strong)	NSString									*bundleID;
@property (assign)	pid_t										processID;
@property (strong)	MCC_PREFIXED_NAME(ProcessNotificationBlock)	block;

- (id)initWithBundleID:(NSString *)bundleIdentifier block:(MCC_PREFIXED_NAME(ProcessNotificationBlock))aBlock;
- (id)initWithProcessID:(pid_t)processIdentifier block:(MCC_PREFIXED_NAME(ProcessNotificationBlock))aBlock;

@end


@interface MCC_PREFIXED_NAME(FileEventQueue) ()
@property (strong) NSMutableDictionary	*watchedPathEntries;
@property (strong) NSMutableArray		*watchedAtomicEntries;
@property (strong) NSMutableArray		*watchedProcessEntries;
@property (assign) dispatch_queue_t		modifyEventQueue;
@property (assign) int					coreQueueFD;
@property (assign) BOOL					keepWatcherThreadRunning;
@end


@implementation MCC_PREFIXED_NAME(FileEventQueue)


#pragma mark Public Methods

- (void)executeBlock:(MCC_PREFIXED_NAME(ProcessNotificationBlock))processBlock forProcessIDOnExit:(pid_t)processID {
	[self watchForExitOfProcessEntry:AUTORELEASE([[MCC_PREFIXED_NAME(ProcessEntry) alloc] initWithProcessID:processID block:processBlock])];
}

- (void)executeBlock:(MCC_PREFIXED_NAME(ProcessNotificationBlock))processBlock forBundleIDOnExit:(NSString *)bundleID {
	[self watchForExitOfProcessEntry:AUTORELEASE([[MCC_PREFIXED_NAME(ProcessEntry) alloc] initWithBundleID:bundleID block:processBlock])];
}


- (void)addPath:(NSString *)aPath {
    if (!aPath) return;
	[self addPath:aPath withBlock:nil notifyingAbout:MCCNotifyFileDefault];
}


- (void)addPath:(NSString *)aPath notifyingAbout:(NSUInteger)flags {
    if (!aPath) return;
	[self addPath:aPath withBlock:nil notifyingAbout:flags];
    
}

- (void)addPath:(NSString *)aPath withBlock:(MCC_PREFIXED_NAME(PathBlock))aBlock notifyingAbout:(NSUInteger)flags; {
    if (!aPath) return;
	if ([self addPathToQueue:aPath block:aBlock notifyingAbout:flags atomically:NO] == nil) {
		NSLog(@"%@ tried to add the path %@ to watchedPathEntries, but the PathEntry was nil. \nIt's possible that the host process has hit its max open file descriptors limit.", [self className], aPath);
	}
    
}

- (void)readdPath:(NSString *)aPath {
	MCC_PREFIXED_NAME(PathEntry) *pathEntry = [self.watchedPathEntries objectForKey:aPath];
    dispatch_sync(self.modifyEventQueue, ^{
		[self synchronouslyRemovePath:aPath];
		[self synchronouslyAddPath:aPath withBlock:pathEntry.block notifyingAbout:pathEntry.subscriptionFlags atomically:pathEntry.handleAtomically];
	});
}

- (void)addAtomicPath:(NSString *)aPath {
    if (!aPath) return;
	[self addAtomicPath:aPath withBlock:nil notifyingAbout:MCCNotifyFileDefault];
}


- (void)addAtomicPath:(NSString *)aPath notifyingAbout:(NSUInteger)flags {
    if (!aPath) return;
	[self addAtomicPath:aPath withBlock:nil notifyingAbout:flags];
    
}

- (void)addAtomicPath:(NSString *)aPath withBlock:(MCC_PREFIXED_NAME(PathBlock))aBlock notifyingAbout:(NSUInteger)flags; {
    if (!aPath) return;
	if ([self addPathToQueue:aPath block:aBlock notifyingAbout:flags atomically:YES] == nil) {
		NSLog(@"%@ tried to add the path %@ to watchedPathEntries, but the PathEntry was nil. \nIt's possible that the host process has hit its max open file descriptors limit.", [self className], aPath);
	}
    
}

- (void)removePath:(NSString *)aPath {
    if (!aPath) return;
    dispatch_sync(self.modifyEventQueue, ^{
		[self synchronouslyRemovePath:aPath];
	});
}


- (void)removeAllPaths {
	NSMutableDictionary	*pathEntries = self.watchedPathEntries;
	dispatch_sync(self.modifyEventQueue, ^{
        for (id pathKey in [pathEntries allKeys]) {
			[self synchronouslyRemovePath:pathKey];
		}
		
		[pathEntries removeAllObjects];
	});
}


- (NSUInteger)numberOfWatchedPaths {
    NSUInteger __block count;
    
	NSMutableDictionary	*pathEntries = self.watchedPathEntries;
	dispatch_sync(self.modifyEventQueue, ^{
        count = [pathEntries count];
	});
    
    return count;
}


#pragma mark Private Methods

- (MCC_PREFIXED_NAME(PathEntry) *)addPathToQueue:(NSString *)aPath block:(MCC_PREFIXED_NAME(PathBlock))aBlock notifyingAbout:(NSUInteger)flags atomically:(BOOL)isAtomic {
	
	MCC_PREFIXED_NAME(PathEntry) __block *pathEntry = nil;
	dispatch_sync(self.modifyEventQueue, ^{
		pathEntry = [self synchronouslyAddPath:aPath withBlock:aBlock notifyingAbout:flags atomically:isAtomic];
	});
	
	// Start the thread that fetches and processes our events if it's not already running.
	if (pathEntry && !self.keepWatcherThreadRunning) {
		self.keepWatcherThreadRunning = YES;
		[NSThread detachNewThreadSelector:@selector(watcherThread:) toTarget:self withObject:nil];
	}
	return pathEntry;
	
}

- (MCC_PREFIXED_NAME(PathEntry) *)synchronouslyAddPath:(NSString *)aPath withBlock:(id)aBlock notifyingAbout:(NSUInteger)blockFlags atomically:(BOOL)isAtomic {
	// Are we already watching this path?
	MCC_PREFIXED_NAME(PathEntry)	*pathEntry = [self.watchedPathEntries objectForKey:aPath];
	
	if (pathEntry) {
		// All flags already set?
		if(([pathEntry subscriptionFlags] & blockFlags) == blockFlags) {
			return pathEntry;
		}
		
		blockFlags |= [pathEntry subscriptionFlags];
	}
	
	if (!pathEntry) {
		pathEntry = [[MCC_PREFIXED_NAME(PathEntry) alloc] initWithPath:aPath block:aBlock subscriptionFlags:blockFlags atomically:isAtomic];
		AUTORELEASE(pathEntry);
	}
	
	if (pathEntry) {
		
		struct timespec		nullts = { 0, 0 };
		struct kevent		ev;
		
		EV_SET(&ev, [pathEntry watchedFD], EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_CLEAR, blockFlags, 0, (__bridge void *)(pathEntry));
		
		[pathEntry setSubscriptionFlags:blockFlags];
		
		[self.watchedPathEntries setObject:pathEntry forKey:aPath];
		kevent(self.coreQueueFD, &ev, 1, NULL, 0, &nullts);
        
		if (isAtomic) {
			[self.watchedAtomicEntries addObject:aPath];
		}
	}
	
	return pathEntry;
}

- (void)synchronouslyRemovePath:(NSString *)aPath {
	MCC_PREFIXED_NAME(PathEntry) *entry = [self.watchedPathEntries objectForKey:aPath];
	// Remove it only if we're watching it.
	if (entry) {
		//	Remove the kevent for this path
		struct timespec		nullts = { 0, 0 };
		struct kevent		ev;
		
		EV_SET(&ev, entry.watchedFD, EVFILT_VNODE, EV_DELETE, entry.subscriptionFlags, 0, NULL);
		kevent(self.coreQueueFD, &ev, 1, NULL, 0, &nullts);
		
		//	Remove from our list
		[self.watchedPathEntries removeObjectForKey:aPath];
		
	}
}

//
//  WARNING: This thread has no active autorelease pool, so if you make changes, you must manually manage
//           memory without relying on autorelease. Otherwise, you will leak!
//
- (void) watcherThread:(id)sender {
    int					n;
    struct kevent		ev;
    struct timespec     timeout = { 1, 0 };     // 1 second timeout. Should be longer, but we need this thread to exit when a kqueue is dealloced, so 1 second timeout is quite a while to wait.
	int					theFD = self.coreQueueFD;	// So we don't have to risk accessing iVars when the thread is terminated.
    NSMutableArray      *notesToPost = [NSMutableArray arrayWithCapacity:5];
    
#if DEBUG_LOG_THREAD_LIFETIME
	NSLog(@"watcherThread started.");
#endif
	
    while(self.keepWatcherThreadRunning) {
        @try {
            n = kevent(theFD, NULL, 0, &ev, 1, &timeout);
            if (n > 0) {
                //NSLog( @"KEVENT returned %d", n );
                if (ev.filter == EVFILT_VNODE) {
                    //NSLog( @"KEVENT filter is EVFILT_VNODE" );
                    if (ev.fflags) {
                        //NSLog( @"KEVENT flags are set" );
                        
                        id pe = (__bridge id)(ev.udata);
                        if (pe && [pe respondsToSelector:@selector(path)]) {
							MCC_PREFIXED_NAME(PathEntry)	*pathEntry = (MCC_PREFIXED_NAME(PathEntry) *)pe;
                            NSString *fpath = pathEntry.path;
                            if (!fpath) continue;
							if (![self.watchedPathEntries valueForKey:fpath]) continue;
                            
                            [[NSWorkspace sharedWorkspace] noteFileSystemChanged:fpath];
                            
                            // Clear any old notifications
                            [notesToPost removeAllObjects];
                            
                            // Figure out which notifications we need to issue
                            if ((ev.fflags & NOTE_RENAME) == NOTE_RENAME) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventRenameNotification)];
                            }
                            if ((ev.fflags & NOTE_WRITE) == NOTE_WRITE) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventWriteNotification)];
                            }
                            if ((ev.fflags & NOTE_DELETE) == NOTE_DELETE) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventDeleteNotification)];
                            }
                            if ((ev.fflags & NOTE_ATTRIB) == NOTE_ATTRIB) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventAttributeChangeNotification)];
                            }
                            if ((ev.fflags & NOTE_EXTEND) == NOTE_EXTEND) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventSizeIncreaseNotification)];
                            }
                            if ((ev.fflags & NOTE_LINK) == NOTE_LINK) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventLinkCountChangeNotification)];
                            }
                            if ((ev.fflags & NOTE_REVOKE) == NOTE_REVOKE) {
                                [notesToPost addObject:MCC_PREFIXED_NAME(FileEventAccessRevocationNotification)];
                            }
                            
                            NSArray *notes = [[NSArray alloc] initWithArray:notesToPost];   // notesToPost will be changed in the next loop iteration, which will likely occur before the block below runs.
							
                            // Post the notifications (or call the delegate method) on the main thread.
							MCC_PREFIXED_NAME(FileEventQueue)				__block	*blockSelf = self;
							id<MCC_PREFIXED_NAME(FileEventDelegate)>	__block	myDelegate = self.delegate;
							BOOL	forceNotifications = self.shouldAlwaysPostNotifications;
                            dispatch_async(dispatch_get_main_queue(),^{
								for (NSString *note in notes) {
									[myDelegate fileEvent:blockSelf receivedNotification:note forPath:fpath];
									
									if (pathEntry.block) {
										pathEntry.block(blockSelf, note, pathEntry.path);
									}
									
									if ((!myDelegate && !pathEntry.block) || forceNotifications) {
										[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:note object:blockSelf userInfo:@{@"path": fpath}];
									}
									
									//	If the path is marked as always being done atomically, readd the path to the queue.
									if (pathEntry.handleAtomically) {
										[self readdPath:pathEntry.path];
									}
								}
							});
                        }
                    }
                }
				else if (ev.filter == EVFILT_PROC) {
					id pe = (__bridge id)(ev.udata);
					if (pe && [pe respondsToSelector:@selector(bundleID)]) {
						MCC_PREFIXED_NAME(FileEventQueue)	__block	*blockSelf = self;
						MCC_PREFIXED_NAME(ProcessEntry)			*processEntry = (MCC_PREFIXED_NAME(ProcessEntry) *)pe;
						if (processEntry.block) {
							dispatch_async(dispatch_get_main_queue(), ^{
								processEntry.block(blockSelf, processEntry.name, processEntry.bundleID, processEntry.processID);
							});
						}
						
						int	theFileDescriptor = self.coreQueueFD;
						NSMutableArray	__block	*processEntries = self.watchedProcessEntries;
						dispatch_async(self.modifyEventQueue, ^{
							//	Remove the event from the queue
							//	Remove the kevent for this path
							struct timespec		nullts = { 0, 0 };
							struct kevent		removeEvent;
							
							EV_SET(&removeEvent, processEntry.processID, EVFILT_PROC, EV_DELETE, NOTE_EXIT, 0, NULL);
							kevent(theFileDescriptor, &removeEvent, 1, NULL, 0, &nullts);
							
							//	Remove the entry from our list
							[processEntries removeObject:processEntry];
						});
					}
				}
            }
        }
        @catch (NSException *localException) {
            NSLog(@"Error in %@ watcherThread: %@", [self className], localException);
        }
    }
    
	// Close our kqueue's file descriptor
	if (close(theFD) == -1) {
		NSLog(@"%@ watcherThread: Couldn't close main kqueue (%d)", [self className], errno);
    }
    
#if DEBUG_LOG_THREAD_LIFETIME
	NSLog(@"watcherThread finished.");
#endif
	
}

- (void)watchForExitOfProcessEntry:(MCC_PREFIXED_NAME(ProcessEntry) *)processEntry {
	
	if (processEntry == nil) {
		return;
	}
	
	int	theFileDescriptor = self.coreQueueFD;
	NSMutableArray	__block	*processEntries = self.watchedProcessEntries;
	dispatch_async(self.modifyEventQueue, ^{
		//	Add the kevent for this process
		struct timespec		nullts = { 0, 0 };
		struct kevent		ev;
		
		EV_SET(&ev, processEntry.processID, EVFILT_PROC, EV_ADD, NOTE_EXIT, 0, (__bridge void *)processEntry);
		if (kevent(theFileDescriptor, &ev, 1, NULL, 0, &nullts) != -1) {
			[processEntries addObject:processEntry];
		}
	});
	
}


#pragma mark - Memory Management

- (id) init {
	self = [super init];
	if (self) {
		self.coreQueueFD = kqueue();
		if (self.coreQueueFD == -1) {
			return nil;
		}
		
        self.shouldAlwaysPostNotifications = NO;
		self.watchedPathEntries = [NSMutableDictionary dictionary];
		self.watchedAtomicEntries = [NSMutableArray array];
		self.watchedProcessEntries = [NSMutableArray array];
		NSString	*queueName = [NSString stringWithFormat:@"%@.modifyEventQueue", [self className]];
		self.modifyEventQueue = dispatch_queue_create([queueName UTF8String], 0);
	}
	return self;
}

- (void) dealloc {
    // Shut down the thread that's scanning for kQueue events
    self.keepWatcherThreadRunning = NO;
    
    // Do this to close all the open file descriptors for files we're watching
    [self removeAllPaths];
    
    self.watchedPathEntries = nil;
	self.watchedProcessEntries = nil;
	dispatch_release(self.modifyEventQueue);
	
	DEALLOC();
    
}


@end


#pragma mark - PathEntry


@implementation MCC_PREFIXED_NAME(PathEntry)

- (instancetype)initWithPath:(NSString *)aPath block:(MCC_PREFIXED_NAME(PathBlock))aBlock subscriptionFlags:(NSUInteger)flags atomically:(BOOL)isAtomic {
    self = [super init];
	if (self) {
		self.watchedFD = open([aPath fileSystemRepresentation], O_EVTONLY, 0);
		if (self.watchedFD < 0) {
			RELEASE(self);
			return nil;
		}
		self.path = aPath;
		self.subscriptionFlags = flags;
		self.block = aBlock;
		self.handleAtomically = isAtomic;
	}
	return self;
}

- (void)dealloc {
	self.path = nil;
	self.block = nil;
    
	if (self.watchedFD >= 0) close((int)self.watchedFD);
	self.watchedFD = -1;
	
	DEALLOC();
}

@end


#pragma mark - ProcessEntry


@interface MCC_PREFIXED_NAME(ProcessEntry) ()

- (id)initWithRunningApplication:(NSRunningApplication *)runningApp block:(MCC_PREFIXED_NAME(ProcessNotificationBlock))aBlock;

@end


@implementation MCC_PREFIXED_NAME(ProcessEntry)

- (id)initWithRunningApplication:(NSRunningApplication *)runningApp block:(MCC_PREFIXED_NAME(ProcessNotificationBlock))aBlock {
	self = [super init];
	if (runningApp == nil) {
		RELEASE(self);
		return nil;
	}
	if (self) {
		self.name = runningApp.localizedName;
		self.bundleID = runningApp.bundleIdentifier;
		self.processID = runningApp.processIdentifier;
		self.block = aBlock;
	}
	return self;
}

- (id)initWithBundleID:(NSString *)bundleIdentifier block:(MCC_PREFIXED_NAME(ProcessNotificationBlock))aBlock {
	return [self initWithRunningApplication:[[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier] lastObject] block:aBlock];
}

- (id)initWithProcessID:(pid_t)processIdentifier block:(MCC_PREFIXED_NAME(ProcessNotificationBlock))aBlock {
	return [self initWithRunningApplication:[NSRunningApplication runningApplicationWithProcessIdentifier:processIdentifier] block:aBlock];
}

@end


