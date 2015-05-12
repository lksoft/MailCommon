//
//  MCCDebugReasonSheet.h
//  MailCommon
//
//  Created by Little Known on 13/11/14.
//
//

#include "MCCCommonHeader.h"

extern NSString * const MCC_PREFIXED_CONSTANT(DebugReasonGivenNotification);

@interface MCC_PREFIXED_NAME(DebugReasonSheet) : NSObject

@property (strong) NSAttributedString *problemText;

@property (strong) IBOutlet NSWindow *sheet;

- (void)showSheetInWindow:(NSWindow *)aWindow;
- (IBAction)closeSheet:(id)sender;

@end
