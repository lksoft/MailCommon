//
//  MCCOptionalViewController.m
//  Tealeaves
//
//  Created by Scott Little on 25/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "MCCOptionalViewController.h"

static	NSMutableArray			*MCC_PREFIXED_NAME(_ovc_keys);
static	NSMutableDictionary		*MCC_PREFIXED_NAME(_ovc_controllers);
static	NSMutableDictionary		*MCC_PREFIXED_NAME(_ovc_optionalViewNibs);

//	constants for stored views
#define	kMCCOptionalViewKey			@"MCCOptionalViewKey"
#define kMCCHeaderViewObjectKey		@"MCCHeaderViewObjectKey"
#define kMCCBackEndViewObjectKey	@"MCCBackEndViewObjectKey"

//	constants for the keys
#define kMCCControllerEditorKey		@"MCCControllerEditorKey"
#define kMCCControllerBackEndKey	@"MCCControllerBackEndKey"
#define kMCCControllerHeaderViewKey	@"MCCControllerHeaderViewKey"

#define _XXX_CONCAT_3(e)				#e
#define _XXX_CONCAT_2(c,d)				_XXX_CONCAT_3(c ## d)
#define	_XXX_CONCAT(a,b)				_XXX_CONCAT_2(a,b)
#define PREFIXED_CLASS_STRING(className) ([NSString stringWithFormat:@"%s", _XXX_CONCAT(MCC_PLUGIN_PREFIX,className)])


@interface MCC_PREFIXED_NAME(OptionalViewController) ()

+ (DocumentEditor *)editorFromKeyType:(NSString *)keyType withObject:(id)keyObject;
+ (void)addKeySetForEditor:(DocumentEditor *)editor;
+ (void)removeKeySetForEditor:(DocumentEditor *)editor;

@end


@implementation MCC_PREFIXED_NAME(OptionalViewController)

#pragma mark - Memory Management

- (id)init {
	self = [super init];
	if (self) {
		_visible = YES;
		_doingHeaderCustomization = NO;
		_savedIsVisible = YES;
	}
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}


#pragma mark - Class Methods

+ (void)load {
	//	Initialize the static variables if this is the base class
	if ([[self className] isEqualToString:PREFIXED_CLASS_STRING(OptionalViewController)]) {
		MCC_PREFIXED_NAME(_ovc_keys) = [[NSMutableArray alloc] init];
		MCC_PREFIXED_NAME(_ovc_controllers) = [[NSMutableDictionary alloc] init];
		MCC_PREFIXED_NAME(_ovc_optionalViewNibs) = [[NSMutableDictionary alloc] init];
	}
}

+ (NSString *)optionalViewNibName {
	NSAssert(NO, @"+optionalViewNibName should be overridden by subclasses and/or %@ should be subclassed.", NSStringFromClass(self));
	return nil;
}

+ (NSNib *)optionalViewNib {
	
	NSString	*nibKey = [self optionalViewNibName];
	NSNib		*aNib = [MCC_PREFIXED_NAME(_ovc_optionalViewNibs) valueForKey:nibKey];
	
	//	first see if we need to load the NIB template into memory
	if (aNib == nil) {
		NSNib		*newNib = [[[NSNib alloc] initWithNibNamed:nibKey
												   bundle:[NSBundle bundleForClass:self]] autorelease];
		
		//	if we did not succeed give error message and return nil
		if (newNib == nil) {
			NSLog(@"Could not init the NSNib in %@ for nib %@", NSStringFromClass(self), nibKey);
			return nil;
		}
		
		//	store the nib
		[MCC_PREFIXED_NAME(_ovc_optionalViewNibs) setValue:newNib forKey:nibKey];
		aNib = newNib;
	}
	
	return aNib;
}


#pragma mark **Internal Controller Methods**

+ (MCC_PREFIXED_NAME(OptionalViewController) *)controllerWithID:(id)identifier {
	
	MCC_PREFIXED_NAME(OptionalViewController)	*result = nil;
	NSNumber	*keyNumber = [NSNumber numberWithInteger:[identifier hash]];
	
	//	ensure that a proper identifier was passed
	if (identifier == nil) {
		return nil;
	}
	
	//	now look to see if the view already exists
	NSDictionary	*optionalViewDict = [MCC_PREFIXED_NAME(_ovc_controllers) objectForKey:keyNumber];
	
	//	if the type of keyObject is DocumentEditor, ensure that the controller doesn't
	//		exist already for the composeHeaderView, and redo it if so
	if ((optionalViewDict == nil) && [identifier isKindOfClass:MCC_PREFIXED_NAME(ClassFromString)(@"DocumentEditor")]) {
		
		//	try to get composeHeaderView controller
		NSNumber		*headerViewNumber = [NSNumber numberWithInteger:[[identifier valueForKey:@"composeHeaderView"] hash]];
		NSDictionary	*justHeader = [MCC_PREFIXED_NAME(_ovc_controllers) objectForKey:headerViewNumber];
		//	if succeeded, remove that controller, reinsert it using the DocumentEditor
		//		key and then build the keys as well.
		if (justHeader != nil) {
			[MCC_PREFIXED_NAME(_ovc_controllers) removeObjectForKey:headerViewNumber];
			[MCC_PREFIXED_NAME(_ovc_controllers) setObject:[justHeader objectForKey:kMCCOptionalViewKey]
									forKey:keyNumber];
			[self addKeySetForEditor:identifier];
			
			//	then set the optionalViewDict to our object to be done
			optionalViewDict = justHeader;
		}
	}
	
	//	if so, just return that
	if (optionalViewDict != nil) {
		result = [optionalViewDict objectForKey:kMCCOptionalViewKey];
	}
	else {	//	otherwise
		
		//	create the owner first
		MCC_PREFIXED_NAME(OptionalViewController)	*owningController = [[[[self class] alloc] init] autorelease];
		
		//	initialize its default values
		//		visibility
		[owningController setVisible:YES];
		
		//	Call the method to load the optionalViewNib
		NSNib	*aNib = [self optionalViewNib];
		
		//	if successful in instantiating a new one...
		if ([aNib instantiateNibWithOwner:owningController
						  topLevelObjects:nil]) {
			
			id	headerViewAsKey = nil;
			id	composeBackEndAsKey = nil;
			
			//	create keys if the identifier is the DocumentEditor
			if ([identifier isKindOfClass:MCC_PREFIXED_NAME(ClassFromString)(@"DocumentEditor")]) {
				[self addKeySetForEditor:identifier];
				headerViewAsKey = [(DocumentEditor *)identifier valueForKey:@"composeHeaderView"];
				composeBackEndAsKey = ((DocumentEditor *)identifier).backEnd;
			}
			
			//	store it...
			[MCC_PREFIXED_NAME(_ovc_controllers) setObject:[NSDictionary dictionaryWithObjectsAndKeys:
											owningController, kMCCOptionalViewKey,
											headerViewAsKey, kMCCHeaderViewObjectKey,
											composeBackEndAsKey, kMCCBackEndViewObjectKey,
											nil]
									forKey:keyNumber];
			
			//	and return it
			result = owningController;
		}
	}
	
	return result;
}


+ (MCC_PREFIXED_NAME(OptionalViewController) *)controllerWithBackEnd:(ComposeBackEnd *)keyObject {
	return [self controllerWithID:[self editorWithBackEnd:keyObject]];
}

+ (MCC_PREFIXED_NAME(OptionalViewController) *)controllerWithHeaderView:(ComposeHeaderView *)keyObject {
	return [self controllerWithID:[self editorWithHeaderView:keyObject]];
}

+ (void)updateControllerWithEditor:(DocumentEditor *)editor {
	
	//	first remove the existing keySet
	[self removeKeySetForEditor:editor];
	
	//	and readd it
	[self addKeySetForEditor:editor];
}

+ (void)removeControllerWithEditor:(DocumentEditor *)editor {
	
	NSNumber	*keyNumber = [NSNumber numberWithInteger:[editor hash]];
	NSNumber	*headerViewNumber = [NSNumber numberWithInteger:[[editor valueForKey:@"composeHeaderView"] hash]];
	
	//	remove the controller
	if (MCC_PREFIXED_NAME(_ovc_controllers) != nil) {
		//	if it already exists
		if ([MCC_PREFIXED_NAME(_ovc_controllers) objectForKey:keyNumber] != nil) {
			[MCC_PREFIXED_NAME(_ovc_controllers) removeObjectForKey:keyNumber];
		}
		//	otherwise look for the composeHeaderView as key
		else if ([MCC_PREFIXED_NAME(_ovc_controllers) objectForKey:headerViewNumber] != nil) {
			[MCC_PREFIXED_NAME(_ovc_controllers) removeObjectForKey:headerViewNumber];
		}
	}
	
	//	remove the keySet
	[self removeKeySetForEditor:editor];
}


#pragma mark **DocumentEditor Access**

+ (DocumentEditor *)editorWithBackEnd:(ComposeBackEnd *)backEnd {
	return [self editorFromKeyType:kMCCControllerBackEndKey withObject:backEnd];
}

+ (DocumentEditor *)editorWithHeaderView:(ComposeHeaderView *)headerView {
	return [self editorFromKeyType:kMCCControllerHeaderViewKey withObject:headerView];
}


#pragma mark **KeySet Management**

+ (DocumentEditor *)editorFromKeyType:(NSString *)keyType withObject:(id)keyObject {
	DocumentEditor	*result = nil;
	
	for (NSDictionary *item in MCC_PREFIXED_NAME(_ovc_keys)) {
		if ([[item valueForKey:keyType] isEqual:keyObject]) {
			result = [item objectForKey:kMCCControllerEditorKey];
			break;
		}
	}
	
	return result;
}

+ (void)addKeySetForEditor:(DocumentEditor *)editor {
	//	make the keys for the editor, back end, and header view
	NSDictionary	*keySet = [NSDictionary dictionaryWithObjectsAndKeys:
							   editor, kMCCControllerEditorKey,
							   editor.backEnd, kMCCControllerBackEndKey,
							   [editor valueForKey:@"composeHeaderView"], kMCCControllerHeaderViewKey,
							   nil];
	[MCC_PREFIXED_NAME(_ovc_keys) addObject:keySet];
}

+ (void)removeKeySetForEditor:(DocumentEditor *)editor {
	
	//	remove the keySet
	NSDictionary	*foundDict = nil;
	for (NSDictionary *item in MCC_PREFIXED_NAME(_ovc_keys)) {
		if ([[item valueForKey:kMCCControllerEditorKey] isEqual:editor]) {
			foundDict = item;
			break;
		}
	}
	if (foundDict != nil) {
		[MCC_PREFIXED_NAME(_ovc_keys) removeObject:foundDict];
	}
}

@end
