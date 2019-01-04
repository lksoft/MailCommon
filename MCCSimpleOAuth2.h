//
//  MCCSimpleOAuth2.h
//  OAuth Tester
//
//  Created by Scott Little on 4/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "MCCCommonHeader.h"


typedef NS_ENUM(NSInteger, MCC_PREFIXED_NAME(SimpleOAuthError)) {
	MCC_PREFIXED_CONSTANT(SimpleOAuthErrorNoWebView) = 101,
	MCC_PREFIXED_CONSTANT(SimpleOAuthErrorRetrievingToken),
	MCC_PREFIXED_CONSTANT(SimpleOAuthErrorNavigation)
};

typedef NS_ENUM(NSInteger, MCC_PREFIXED_NAME(SimpleOAuthStorageType)) {
	MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeDefaults) = 0,
	MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeKeychain)
};

@class MCC_PREFIXED_NAME(SimpleOAuth2);

extern NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain);
extern NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationNotification);
extern NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationFailedNotification);


@interface MCC_PREFIXED_NAME(SimpleOAuth2) : NSObject
#ifdef MAC_OS_X_VERSION_10_11
<WebPolicyDelegate>
#endif
@property (strong) NSString	*scope;
@property (strong) NSString	*accessToken;
@property (strong) IBOutlet WebView	*webview;

- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName
					 storageType:(MCC_PREFIXED_NAME(SimpleOAuthStorageType))aStorageType
						bundleID:(NSString *)aStorageBundleID;
- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName
					 storageType:(MCC_PREFIXED_NAME(SimpleOAuthStorageType))aStorageType;
- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName
						bundleID:(NSString *)aStorageBundleID;
- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName;

- (void)authorize;
- (void)deauthorize;
- (void)forceRenewalNow;

@end
