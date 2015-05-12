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
 
	[NSApp beginSheet:self.sheet modalForWindow:aWindow modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

- (void)closeSheet:(id)sender {
	[NSApp endSheet:self.sheet];
	
	if ([sender tag] == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification) object:self];
	}
}

@end
