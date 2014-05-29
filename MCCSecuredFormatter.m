//
//  MCCSecuredFormatter.m
//  Tealeaves
//
//  Created by Scott Little on 29/5/14.
//  Copyright (c) 2014 Little Known Software. All rights reserved.
//

#import "MCCSecuredFormatter.h"

@implementation MCCSecuredFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
	
	//	If the  context is a secure formatting, then get the original message format from the tag and bleep stuff
	if (logMessage->logContext == MCCSecureFormattingContext) {
		//	Don't use the dereference that DDLog only allows, since the memory management will get screwed up
		[logMessage setValue:[self secureFormat:logMessage->tag] forKey:@"logMsg"];
	}
	
	return [super formatLogMessage:logMessage];
}

- (NSString *)secureFormat:(NSString *)format {
	
	//	the text to replace the hidden output with
	NSString		*replaceWith = @"<****>";
	
	
	//	the string format set, including the %
	NSCharacterSet	*stringFormatSet = [NSCharacterSet characterSetWithCharactersInString:@"@dDiuUxXoOfeEgGcCsSphq"];
	
	//	scan the string for a percent
	//		if the next is '%' ignore
	//		then scan for one of the following:
	//			@ d D i u U x X o O f e E g G c C s S p h q
	//		if found delete from the % to the char inclusive
	//		unless one of the last two then add another character to delete
	NSScanner		*myScan = [NSScanner scannerWithString:format];
	NSMutableString	*newFormat = [NSMutableString string];
	NSString		*holder = nil;
	
	//	ensure that it doesn't skip any whitespace
	[myScan setCharactersToBeSkipped:nil];
	
	//	If the format string starts with a '%', set a flag
	BOOL	startsWithPercent = [format hasPrefix:@"%"];
	//	look for those '%'s
	while ([myScan scanUpToString:@"%" intoString:&holder] || startsWithPercent) {
		//	Immediately switch off that flag
		startsWithPercent = NO;
		
		//	add holder to the newFormat
		if (holder) {
			[newFormat appendString:holder];
		}
		
		//	if we are the end, leave
		if ([myScan isAtEnd]) {
			break;
		}
		
		//	scan for the potentials
		if ([myScan scanUpToCharactersFromSet:stringFormatSet
								   intoString:&holder]) {
			
			//	if current position is '%', reappend '%%' and continue
			if ([format characterAtIndex:[myScan scanLocation]] == '%') {
				[newFormat appendString:@"%%"];
				[myScan setScanLocation:([myScan scanLocation] + 1)];
				continue;
			}
			
			//	and if the last character is either 'h' or 'q',
			//		advance the pointer one more position to skip that
			unichar	lastChar = [format characterAtIndex:[myScan scanLocation]];
			if ((lastChar == 'h') || (lastChar == 'q')) {
				[myScan setScanLocation:([myScan scanLocation] + 1)];
			}
			
			//	always advance the scan position past the matched character
			[myScan setScanLocation:([myScan scanLocation] + 1)];
			
			//	stick the replace string into the outgoing string
			[newFormat appendString:replaceWith];
		}
		else {
			//	bad formatting, give warning and reset the format completely to ensure security
			NSLog(@"Bad format during Secure Scan Reformat: original format is:%@", format);
			return @"Bad format for Secure Logging";
		}
		
	}
	
	//	return the string
	return [NSString stringWithString:newFormat];
}


@end
