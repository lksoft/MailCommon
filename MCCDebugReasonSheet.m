//
//  MCCDebugReasonSheet.m
//  MailCommon
//
//  Created by Little Known on 13/11/14.
//
//

#import "MCCDebugReasonSheet.h"

NSString * const MCCDebugReasonGivenNotification = @"MCCDebugReasonGivenNotification";


@implementation MCCDebugReasonSheet

- (void)showSheetInWindow:(NSWindow *)aWindow {
	
	if (!self.sheet) {
		//Check the myCustomSheet instance variable to make sure the custom sheet does not already exist.
		[NSBundle loadNibNamed:@"MCCDebugReasonSheet" owner:self];
	}
 
	[NSApp beginSheet:self.sheet modalForWindow:aWindow modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

- (void)closeSheet:(id)sender {
	[NSApp endSheet:self.sheet];
	
	if ([sender tag] == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MCCDebugReasonGivenNotification object:self];
	}
}

@end
