//
//  MCCDebugReasonSheet.m
//  MailCommon
//
//  Created by Little Known on 13/11/14.
//
//

#import "MCCDebugReasonSheet.h"

NSString * const MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification) = MCC_NSSTRING(MCC_PLUGIN_PREFIX, DebugReasonGivenNotification);
//@"MCCDebugReasonGivenNotification";


@implementation MCC_PREFIXED_NAME(DebugReasonSheet)

- (void)showSheetInWindow:(NSWindow *)aWindow {
	
	if (!self.sheet) {
		//Check the myCustomSheet instance variable to make sure the custom sheet does not already exist.
		[[NSBundle bundleForClass:[MCC_PREFIXED_NAME(DebugReasonSheet) class]] loadNibNamed:@"MCCDebugReasonSheet" owner:self topLevelObjects:NULL];
	}
	
	[aWindow beginSheet:self.sheet completionHandler:nil];
 
}

- (void)closeSheet:(id)sender {
	[self.sheet orderOut:nil];

	if ([sender tag] == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification) object:self];
	}
}

- (void)dealloc {
	self.problemText = nil;
	self.sheet = nil;
	MCC_DEALLOC();
}

@end
