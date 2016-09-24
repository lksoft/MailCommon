//
//  MCCDebugReasonSheet.m
//  MailCommon
//
//  Created by Little Known on 13/11/14.
//
//

#import "MCCDebugReasonSheet.h"

NSString * const MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification) = MCC_NSSTRING(MCC_PLUGIN_PREFIX, DebugReasonGivenNotification);


@interface MCC_PREFIXED_NAME(DebugReasonSheet) ()
@property (MCC_WEAK) NSWindow * parentWindow;
@end

@implementation MCC_PREFIXED_NAME(DebugReasonSheet)

- (void)showSheetInWindow:(NSWindow *)aWindow {
	
	if (!self.sheet) {
		//Check the myCustomSheet instance variable to make sure the custom sheet does not already exist.
		[[NSBundle bundleForClass:[MCC_PREFIXED_NAME(DebugReasonSheet) class]] loadNibNamed:@"MCCDebugReasonSheet" owner:self topLevelObjects:NULL];
	}
	
	self.parentWindow = aWindow;
	
	[aWindow beginSheet:self.sheet completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification) object:self];
		}
	}];
 
}

- (void)closeSheet:(NSButton *)sender {
	[self.parentWindow endSheet:self.sheet returnCode:sender.tag];
}

- (void)dealloc {
	self.problemText = nil;
	self.sheet = nil;
	MCC_DEALLOC();
}

@end
