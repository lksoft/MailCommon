//
//  MCCOptionalViewController.h
//  Tealeaves
//
//  Created by Scott Little on 25/6/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MCCCommonHeader.h"

#import "OptionalView.h"

typedef NS_ENUM(NSInteger, MCC_PREFIXED_NAME(OptionalViewPosition)) {
	MCC_PREFIXED_NAME(OptionalViewPositionHiddenAcctShown),
	MCC_PREFIXED_NAME(OptionalViewPositionHiddenAcctHidden),
	MCC_PREFIXED_NAME(OptionalViewPositionHiddenAllHidden),
	MCC_PREFIXED_NAME(OptionalViewPositionShownAcctShown),
	MCC_PREFIXED_NAME(OptionalViewPositionShownAcctHidden),
	MCC_PREFIXED_NAME(OptionalViewPositionShownAllHidden)
};



@class	DocumentEditor;
@class	ComposeBackEnd;
@class	ComposeHeaderView;

@interface MCC_PREFIXED_NAME(OptionalViewController) : NSObject

@property	(nonatomic, strong)	IBOutlet	OptionalView	*optionalView;
@property	(nonatomic, strong)	IBOutlet	NSButton		*visibleCheckbox;
@property	(nonatomic, strong)	IBOutlet	NSButton		*switchView;

@property	(nonatomic, assign)				BOOL			visible;
@property	(nonatomic, assign)				BOOL			doingHeaderCustomization;
@property	(nonatomic, assign)				BOOL			savedIsVisible;

@property	(nonatomic, assign)				MCC_PREFIXED_NAME(OptionalViewPosition)		savedPosition;


#pragma mark - Helper Class Methods

+ (NSString *)optionalViewNibName;
+ (NSNib *)optionalViewNib;

+ (MCC_PREFIXED_NAME(OptionalViewController) *)controllerWithID:(id)keyObject;
+ (MCC_PREFIXED_NAME(OptionalViewController) *)controllerWithBackEnd:(ComposeBackEnd *)keyObject;
+ (MCC_PREFIXED_NAME(OptionalViewController) *)controllerWithHeaderView:(ComposeHeaderView *)keyObject;
+ (void)updateControllerWithEditor:(DocumentEditor *)editor;
+ (void)removeControllerWithEditor:(DocumentEditor *)keyObject;

+ (DocumentEditor *)editorWithBackEnd:(ComposeBackEnd *)backEnd;
+ (DocumentEditor *)editorWithHeaderView:(ComposeHeaderView *)headerView;

@end
