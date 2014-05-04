//
//  MCCSimpleOAuth2.h
//  OAuth Tester
//
//  Created by Scott Little on 4/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "MCCCommonHeader.h"


@class MCC_PREFIXED_NAME(SimpleOAuth2);
typedef void (^MCC_PREFIXED_NAME(SimpleOAuth2FinalizeBlock))(MCC_PREFIXED_NAME(SimpleOAuth2) *authObject, NSString *accessCode);

@interface MCC_PREFIXED_NAME(SimpleOAuth2) : NSObject
@property (strong) NSString	*scope;
@property (strong) NSString	*accessToken;
@property (strong) IBOutlet WebView	*webview;

- (instancetype)initWithClientId:(NSString *)aClientId clientSecret:(NSString *)aSecret endpointURL:(NSURL *)anEndpointURL tokenURL:(NSURL *)aTokenURL redirectURL:(NSURL *)aRedirectURL;

- (void)authorizeWithFinalize:(MCC_PREFIXED_NAME(SimpleOAuth2FinalizeBlock))aFinalizeBlock;

@end
