//
//  MCCFileEventQueue.h
//  MCCMailCommon
//
//  Created by Scott Little on 23/2/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

//
//  Based almost entirely on VDKQueue by Bryan D K Jones & UKKQueue by Uli Kusterer
//
//
//  IMPORTANT NOTE ABOUT ATOMIC OPERATIONS (Copied from VDKQueue's header file)
//
//      There are two ways of saving a file on OS X: Atomic and Non-Atomic. In a non-atomic operation, a file is saved by directly overwriting it with new data.
//      In an Atomic save, a temporary file is first written to a different location on disk. When that completes successfully, the original file is deleted and the
//      temporary one is renamed and moved into place where the original file existed.
//
//      This matters a great deal. If you tell MCCFileEvent to watch file X, then you save file X ATOMICALLY, you'll receive a notification about that event. HOWEVER, you will
//      NOT receive any additional notifications for file X from then on. This is because the atomic operation has essentially created a new file that replaced the one you
//      told MCCFileEvent to watch. (This is not an issue for non-atomic operations.)
//
//      To handle this, any time you receive a change notification from MCCFileEvent, you should call -removePath: followed by -addPath: on the file's path, even if the path
//      has not changed. This will ensure that if the event that triggered the notification was an atomic operation, MCCFileEvent will start watching the "new" file that took
//      the place of the old one.
//
//      Other frameworks out there try to work around this issue by immediately attempting to re-open the file descriptor to the path. This is not bulletproof and may fail;
//      it all depends on the timing of disk I/O. Bottom line: you could not rely on it and might miss future changes to the file path you're supposedly watching. That's why
//      MCCFileEvent does not take this approach, but favors the "manual" method of "stop-watching-then-rewatch".
//


#import "MCCCommonHeader.h"

#include <sys/types.h>
#include <sys/event.h>

//
//  Logical OR these values into the u_int that you pass in the -addPath:notifyingAbout: method
//  to specify the types of notifications you're interested in. Pass the default value to receive all of them.
//
#define MCCNotifyAboutFileRename			NOTE_RENAME		// Item was renamed.
#define MCCNotifyAboutFileWrite				NOTE_WRITE		// Item contents changed (also folder contents changed).
#define MCCNotifyAboutFileDelete			NOTE_DELETE		// item was removed.
#define MCCNotifyAboutFileAttributeChange	NOTE_ATTRIB		// Item attributes changed.
#define MCCNotifyAboutFileSizeIncrease		NOTE_EXTEND		// Item size increased.
#define MCCNotifyAboutFileLinkCountChanged	NOTE_LINK		// Item's link count changed.
#define MCCNotifyAboutFileAccessRevocation	NOTE_REVOKE		// Access to item was revoked.

#define MCCNotifyFileDefault		(MCCNotifyAboutFileRename | MCCNotifyAboutFileWrite \
	| MCCNotifyAboutFileDelete | MCCNotifyAboutFileAttributeChange \
	| MCCNotifyAboutFileSizeIncrease | MCCNotifyAboutFileLinkCountChanged \
	| MCCNotifyAboutFileAccessRevocation)

//
//  The Actual Notifications that this class sends to the NSWORKSPACE notification center.
//      Object          =   the instance of VDKQueue that was watching for changes
//      userInfo.path   =   the file path where the change was observed
//
extern NSString	*MCC_PREFIXED_NAME(FileEventRenameNotification);
extern NSString *MCC_PREFIXED_NAME(FileEventWriteNotification);
extern NSString *MCC_PREFIXED_NAME(FileEventDeleteNotification);
extern NSString *MCC_PREFIXED_NAME(FileEventAttributeChangeNotification);
extern NSString *MCC_PREFIXED_NAME(FileEventSizeIncreaseNotification);
extern NSString *MCC_PREFIXED_NAME(FileEventLinkCountChangeNotification);
extern NSString *MCC_PREFIXED_NAME(FileEventAccessRevocationNotification);


@class MCC_PREFIXED_NAME(FileEventQueue);
@protocol MCC_PREFIXED_NAME(FileEventDelegate) <NSObject>
@required
- (void)fileEvent:(MCC_PREFIXED_NAME(FileEventQueue) *)anEvent receivedNotification:(NSString *)aNote forPath:(NSString *)aPath;
@end

typedef void (^MCC_PREFIXED_NAME(PathBlock))(MCC_PREFIXED_NAME(FileEventQueue) *anEventQueue, NSString *aNote, NSString *anAffectedPath);
typedef void (^MCC_PREFIXED_NAME(ProcessQuitBlock))(MCC_PREFIXED_NAME(FileEventQueue) *anEvent, NSString *processName, NSString *processBundleID, pid_t processID);


@interface MCC_PREFIXED_NAME(FileEventQueue) : NSObject

@property (weak) id<MCC_PREFIXED_NAME(FileEventDelegate)> delegate;
@property (assign) BOOL shouldAlwaysPostNotifications;

//
//	Execute the block when the process indicated (either by process id or bundle ID) quits
//
//	Does nothing if that process is not currently runnning. Will remove the event when it is triggered
//		as it means that the process is no longer valid.
//
- (void)executeBlock:(MCC_PREFIXED_NAME(ProcessQuitBlock))processBlock forProcessIDOnExit:(pid_t)processID;
- (void)executeBlock:(MCC_PREFIXED_NAME(ProcessQuitBlock))processBlock forBundleIDOnExit:(NSString *)bundleID;

//
//  Note: there is no need to ask whether a path is already being watched. Just add it or remove it and this class
//        will take action only if appropriate. (I.e., add only if we're not already watching it, remove only if we are.)
//
//  Warning: You must pass full, root-relative paths. Do not pass tilde-abbreviated paths or file URLs.
//
- (void)addPath:(NSString *)aPath;
// See note above for values to pass in "flags"
- (void)addPath:(NSString *)aPath notifyingAbout:(NSUInteger)flags;
- (void)addPath:(NSString *)aPath withBlock:(MCC_PREFIXED_NAME(PathBlock))aBlock notifyingAbout:(NSUInteger)flags;

//	This method finds the path that is already being watched and will remove and re add the path using the same values.
- (void)readdPath:(NSString *)aPath;

- (void)addAtomicPath:(NSString *)aPath;
// See note above for values to pass in "flags"
- (void)addAtomicPath:(NSString *)aPath notifyingAbout:(NSUInteger)flags;
- (void)addAtomicPath:(NSString *)aPath withBlock:(MCC_PREFIXED_NAME(PathBlock))aBlock notifyingAbout:(NSUInteger)flags;

- (void)removePath:(NSString *)aPath;
- (void)removeAllPaths;

//  Returns the number of paths that this VDKQueue instance is actively watching.
- (NSUInteger)numberOfWatchedPaths;

@end
