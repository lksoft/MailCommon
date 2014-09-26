//
//  MCCUserNotification.m
//  Tealeaves
//
//  Created by Scott Little on 28/11/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "MCCUserNotification.h"

#define WINDOW_HEIGHT	60.0f
#define WINDOW_WIDTH	300.0f
#define TOP_PADDING		40.0f
#define RIGHT_PADDING	20.0f


@implementation MCC_PREFIXED_NAME(UserNotification)


@end

@interface MCC_PREFIXED_NAME(UserNotificationCenter) ()
@property	(strong)	NSWindow			*window;
@property	(strong)	NSTextField			*textField;
@property	(strong)	NSTextField			*subtextField;
@property	(strong)	NSOperationQueue	*notificationQueue;
@end

@implementation MCC_PREFIXED_NAME(UserNotificationCenter)

#pragma mark Main Methods

- (void)deliverNotification:(MCC_PREFIXED_NAME(UserNotification) *)notification {
	if (notification == nil) {
		return;
	}
	
	MCC_PREFIXED_NAME(UserNoteOperation)	*myOp = MCC_AUTORELEASE([[MCC_PREFIXED_NAME(UserNoteOperation) alloc] initWithUserNotification:notification notificationCenter:self]);
	[self.notificationQueue addOperation:myOp];
	
}

#pragma mark - Creation

- (id)init {
	self = [super init];
	if (self) {
		NSRect		windowRect = [[[NSScreen screens] objectAtIndex:0] frame];
		windowRect = NSMakeRect(windowRect.size.width - (WINDOW_WIDTH + RIGHT_PADDING), windowRect.size.height - (WINDOW_HEIGHT + TOP_PADDING), WINDOW_WIDTH, WINDOW_HEIGHT);
		self.window = MCC_AUTORELEASE([[NSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES]);
		self.textField = MCC_AUTORELEASE([[NSTextField alloc] initWithFrame:NSMakeRect(60.0f, 30.0f, 230.0f, 20.0f)]);
		[self.textField setEditable:NO];
		[self.textField setEnabled:NO];
		[self.textField setTextColor:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
		[self.textField setDrawsBackground:NO];
		[self.textField setBordered:NO];
		self.subtextField = MCC_AUTORELEASE([[NSTextField alloc] initWithFrame:NSMakeRect(60.0f, 10.0f, 230.0f, 20.0f)]);
		[self.subtextField setEditable:NO];
		[self.subtextField setEnabled:NO];
		[self.subtextField setTextColor:[NSColor colorWithCalibratedWhite:0.35 alpha:1.0]];
		[self.subtextField setDrawsBackground:NO];
		[self.subtextField setBordered:NO];
		NSImageView	*iconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(10.0f, 10.0f, 40.0f, 40.0f)] autorelease];
		iconView.image = [[NSBundle bundleForClass:[self class]] imageForResource:@"notification-icon"];
		[[self.window contentView] addSubview:self.textField];
		[[self.window contentView] addSubview:self.subtextField];
		[[self.window contentView] addSubview:iconView];
		[self.window setBackgroundColor:[NSColor colorWithCalibratedWhite:0.75f alpha:1.0f]];
		[self.window setHasShadow:YES];

		self.notificationQueue = [[[NSOperationQueue alloc] init] autorelease];
		self.notificationQueue.name = @"com.littleknownsoftware.Tealeaves.UserNotificationQueue";
		self.notificationQueue.maxConcurrentOperationCount = 1;
		[self.notificationQueue setSuspended:NO];
	}
	return self;
}

- (void)dealloc {
	self.textField = nil;
	self.subtextField = nil;
	[self.notificationQueue cancelAllOperations];
	self.notificationQueue = nil;
	self.window = nil;
	[super dealloc];
}

#pragma mark - Class Methods

+ (instancetype)defaultUserNotificationCenter {
	static id	myNotificationCenter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (myNotificationCenter == nil) {
			myNotificationCenter = [[self alloc] init];
		}
	});
	return myNotificationCenter;
}

@end

@interface MCC_PREFIXED_NAME(UserNoteOperation) ()
@property	(strong, atomic)	MCC_PREFIXED_NAME(UserNotification) *notification;
@property	(assign, atomic)	MCC_PREFIXED_NAME(UserNotificationCenter) *center;
@property	(assign, atomic)	BOOL	done;
@end

@implementation MCC_PREFIXED_NAME(UserNoteOperation)

- (instancetype)initWithUserNotification:(MCC_PREFIXED_NAME(UserNotification) *)aNotification notificationCenter:(MCC_PREFIXED_NAME(UserNotificationCenter) *)aCenter {
	self = [super init];
	if (self) {
		self.notification = aNotification;
		self.center = aCenter;
	}
	return self;
}

- (void)allDone {
	[self willChangeValueForKey:@"isFinished"];
	self.done = YES;
	[self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished {
	return self.done;
}

- (void)main {
	
	MCC_PREFIXED_NAME(UserNotificationCenter) *theCenter = self.center;
	MCC_PREFIXED_NAME(UserNoteOperation) *blockSelf = self;

	self.center.textField.stringValue = self.notification.title;
	self.center.subtextField.stringValue = self.notification.subtitle;

	dispatch_sync(dispatch_get_main_queue(), ^{
		[theCenter.window setAlphaValue:0.0f];
		[theCenter.window makeKeyAndOrderFront:self];
		
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.25f];
		[[theCenter.window animator] setAlphaValue:1.0];
		[NSAnimationContext endGrouping];
	});
	
	double delayInSeconds = 4.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.25f];
		[[NSAnimationContext currentContext] setCompletionHandler:^{
			[theCenter.window orderOut:theCenter];
			[blockSelf allDone];
		}];
		[[theCenter.window animator] setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	});
}

@end
