//
//  MCCDebugReasonSheet.h
//  MailCommon
//
//  Created by Little Known on 13/11/14.
//
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

extern NSString * const MCCDebugReasonGivenNotification;

@interface MCCDebugReasonSheet : NSObject

@property (strong) NSAttributedString *problemText;

@property (strong) IBOutlet NSWindow *sheet;

- (void)showSheetInWindow:(NSWindow *)aWindow;
- (IBAction)closeSheet:(id)sender;

@end
