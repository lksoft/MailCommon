//
//  MCCSimpleOAuth2.m
//  OAuth Tester
//
//  Created by Scott Little on 4/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCSimpleOAuth2.h"
#import "MCCUtilities.h"
#import "MCCSSKeychain.h"
#import "SSKeychain.h"

#define URL_ENCODE(stringValue)	[stringValue stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]]

NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) = @"SimpleOAuth2ErrorDomain";


@interface MCC_PREFIXED_NAME(SimpleOAuth2) ()
@property (strong) NSString	*clientId;
@property (strong) NSString	*clientSecret;
@property (strong) NSURL	*endpointURL;
@property (strong) NSURL	*tokenURL;
@property (strong) NSURL	*redirectURL;
@property (strong) NSString	*encodedRedirectURLString;
@property (strong) NSString	*tokenAccountName;
@property (strong) NSString	*refreshAccountName;
@property (strong) NSString	*tokenExpiresAccountName;
@property (strong) NSTimer	*refreshTimer;
@property (strong) MCC_PREFIXED_NAME(SimpleOAuth2FinalizeBlock)	finalizeBlock;
@end


@implementation MCC_PREFIXED_NAME(SimpleOAuth2)

- (instancetype)initWithClientId:(NSString *)aClientId clientSecret:(NSString *)aSecret endpointURL:(NSURL *)anEndpointURL tokenURL:(NSURL *)aTokenURL redirectURL:(NSURL *)aRedirectURL {
	NSAssert(!IS_EMPTY(aClientId), @"The Client ID cannot be empty for SimpleOAuth2");
	NSAssert(!IS_EMPTY(aSecret), @"The Client Secret cannot be empty for SimpleOAuth2");
	NSAssert((anEndpointURL != nil), @"The endpoint URL cannot be nil for SimpleOAuth2");
	NSAssert([[anEndpointURL scheme] isEqualToString:@"https"], @"The endpoint URL for SimpleOAuth2 must be https");
	NSAssert((aRedirectURL != nil), @"The redirect URL cannot be nil for SimpleOAuth2");
	NSAssert((aTokenURL != nil), @"The token URL cannot be nil for SimpleOAuth2");
	NSAssert([[aTokenURL scheme] isEqualToString:@"https"], @"The token URL for SimpleOAuth2 must be https");
	self = [super init];
	if (self) {
		self.clientId = aClientId;
		self.clientSecret = aSecret;
		self.endpointURL = anEndpointURL;
		self.tokenURL = aTokenURL;
		self.redirectURL = aRedirectURL;
		self.encodedRedirectURLString = URL_ENCODE([self.redirectURL absoluteString]);
		self.scope = @"all";
		self.tokenAccountName = [NSString stringWithFormat:@"%@-accessToken", self.clientId];
		self.refreshAccountName = [NSString stringWithFormat:@"%@-refreshToken", self.clientId];
		self.tokenExpiresAccountName = [NSString stringWithFormat:@"%@-tokenExpires", self.clientId];
		self.accessToken = [MCC_PREFIXED_NAME(Keychain)passwordForService:[self.tokenURL absoluteString] account:self.tokenAccountName];

		NSString	*expiresTimeIntervalString = [MCC_PREFIXED_NAME(Keychain)passwordForService:[self.tokenURL absoluteString] account:self.tokenExpiresAccountName];
		if (expiresTimeIntervalString) {
			NSDate	*expiresDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[expiresTimeIntervalString doubleValue] - 11.0];
			NSTimer	*aTimer = [[NSTimer alloc] initWithFireDate:expiresDate interval:1.0 target:self selector:@selector(renewAccessToken:) userInfo:nil repeats:NO];
			self.refreshTimer = aTimer;
			[[NSRunLoop mainRunLoop] addTimer:aTimer forMode:NSRunLoopCommonModes];
			RELEASE(aTimer);
		}
	
	}
	return self;
}

- (void)dealloc {
	[self.refreshTimer invalidate];

#if !__has_feature(objc_arc)
	self.accessCode = nil;
	self.clientId = nil;
	self.clientSecret = nil;
	self.endpointURL = nil;
	self.tokenURL = nil;
	self.redirectURL = nil;
	self.encodedRedirectURLString = nil;
	self.tokenAccountName = nil;
	self.refreshAccountName = nil;
	self.tokenExpiresAccountName = nil;
	self.refreshTimer = nil;
	[super dealloc];
#endif
}

- (BOOL)alreadyHasToken {
	if ((self.webview == nil) || self.accessToken) {
		if (self.finalizeBlock) {
			NSError	*error = nil;
			if (self.webview == nil) {
				error = [NSError errorWithDomain:MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) code:101 userInfo:@{}];
			}
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				self.finalizeBlock(self, error);
			}];
		}
		return YES;
	}
	return NO;
}

- (void)renewAccessToken:(NSTimer *)aTimer {
	[aTimer invalidate];
	self.refreshTimer = nil;
	self.accessToken = nil;
	NSString	*refreshToken = [MCC_PREFIXED_NAME(Keychain)passwordForService:[self.tokenURL absoluteString] account:self.refreshAccountName];
	[self retreiveAccessTokenUsingCode:refreshToken];
}

- (void)authorizeWithFinalize:(MCC_PREFIXED_NAME(SimpleOAuth2FinalizeBlock))aFinalizeBlock {
	self.finalizeBlock = aFinalizeBlock;
	if ([self alreadyHasToken]) {
		return;
	}
	
	NSURL	*loadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=code%@%@", [self.endpointURL absoluteString], self.clientId, self.encodedRedirectURLString, (self.scope?@"&scope=":@""), self.scope?self.scope:@""]];
	[[self.webview mainFrame] loadRequest:[NSURLRequest requestWithURL:loadURL]];
}

- (void)authorizeUsingUser:(NSString *)username andPassword:(NSString *)password withFinalize:(MCC_PREFIXED_NAME(SimpleOAuth2FinalizeBlock))aFinalizeBlock {
	self.finalizeBlock = aFinalizeBlock;
	if ([self alreadyHasToken]) {
		return;
	}
	
	NSString	*postBodyString = [NSString stringWithFormat:@"grant_type=password&client_id=%@&username=%@&password=%@", self.clientId, URL_ENCODE(username), URL_ENCODE(password)];
	NSMutableURLRequest	*accessRequest = [NSMutableURLRequest requestWithURL:self.tokenURL];
	[accessRequest setHTTPMethod:@"POST"];
	[accessRequest setHTTPBody:[postBodyString dataUsingEncoding:NSUTF8StringEncoding]];
	[accessRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[accessRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[accessRequest addValue:[NSString stringWithFormat:@"%@", @([postBodyString length])] forHTTPHeaderField:@"Content-Length"];
	
	__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
	[NSURLConnection sendAsynchronousRequest:accessRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		
		if (connectionError) {
			NSLog(@"Connection Error is:%@", connectionError);
		}
		else {
			NSError			*error = nil;
			NSDictionary	*resultDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
			if (error != nil) {
				NSLog(@"JSON Error is:%@", error);
			}
			NSLog(@"Response data is:%@", resultDict);
			welf.accessToken = resultDict[@"access_token"];
			welf.scope = resultDict[@"scope"];
			if (welf.finalizeBlock) {
				welf.finalizeBlock(welf, nil);
			}
		}
		
	}];
}

- (void)retreiveAccessTokenUsingCode:(NSString *)aCode {
	
	NSString	*postBodyString = [NSString stringWithFormat:@"grant_type=authorization_code&client_id=%@&client_secret=%@&code=%@&redirect_uri=%@", self.clientId, self.clientSecret, aCode, self.encodedRedirectURLString];
	NSMutableURLRequest	*accessRequest = [NSMutableURLRequest requestWithURL:self.tokenURL];
	[accessRequest setHTTPMethod:@"POST"];
	[accessRequest setHTTPBody:[postBodyString dataUsingEncoding:NSUTF8StringEncoding]];
	[accessRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[accessRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[accessRequest addValue:[NSString stringWithFormat:@"%@", @([postBodyString length])] forHTTPHeaderField:@"Content-Length"];
	
	__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
	[NSURLConnection sendAsynchronousRequest:accessRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		
		//	Remove any existing accessToken
		NSString	*serviceString = [self.tokenURL absoluteString];
		[MCC_PREFIXED_NAME(Keychain) deletePasswordForService:serviceString account:welf.tokenAccountName];
		[MCC_PREFIXED_NAME(Keychain) deletePasswordForService:serviceString account:welf.tokenExpiresAccountName];
		[welf.refreshTimer invalidate];
		welf.refreshTimer = nil;
		
		NSError		*error = nil;
		if (connectionError) {
			error = connectionError;
		}
		else {
			NSDictionary	*resultDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
			if (error == nil) {
				
				if (resultDict[@"error"]) {
					
					error = [NSError errorWithDomain:MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) code:101 userInfo:@{}];
					/*	Errors:
					 invalid_request
					 invalid_client
					 invalid_grant
					 unauthorized_client
					 unsupported_grant_type
					 invalid_scope
					 */
					
				}
				else {
					welf.accessToken = resultDict[@"access_token"];
					welf.scope = resultDict[@"scope"];
					
					//	Store the token in the keychain
					if (welf.accessToken) {
						[MCC_PREFIXED_NAME(Keychain) setPassword:welf.accessToken forService:serviceString account:welf.tokenAccountName];
					}
					
					//	Store the expiration date in the keychain as well, if there is one
					if (resultDict[@"expires_in"]) {
						NSTimeInterval	expireTimeIntervalSinceRefDate = [NSDate timeIntervalSinceReferenceDate] + [resultDict[@"expires_in"] integerValue];
						NSLog(@"expireTimeInterval = '%@'", [@(expireTimeIntervalSinceRefDate) stringValue]);
						[MCC_PREFIXED_NAME(Keychain) setPassword:[@(expireTimeIntervalSinceRefDate) stringValue] forService:serviceString account:welf.tokenExpiresAccountName];
					}
					
					//	Store the refresh token in the keychain as well, if there is one
					if (resultDict[@"refresh_token"]) {
						[MCC_PREFIXED_NAME(Keychain) deletePasswordForService:serviceString account:welf.refreshAccountName];
						[MCC_PREFIXED_NAME(Keychain) setPassword:resultDict[@"refresh_token"] forService:serviceString account:welf.refreshAccountName];
					}
				}
			}
		}
		
		if (welf.finalizeBlock) {
			welf.finalizeBlock(welf, error);
		}
		
	}];
	
}

#pragma mark WebView Delegate Methods

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
	NSLog(@"Need to decide policy for navigation of request: %@", request);
	
	NSString	*resultBaseURLString = [NSString stringWithFormat:@"%@://%@%@", [[request URL] scheme], [[request URL] host], [[request URL] path]];
	NSString	*redirectBaseURLString = [NSString stringWithFormat:@"%@://%@%@", [self.redirectURL scheme], [self.redirectURL host], [self.redirectURL path]];
	
	if ([resultBaseURLString isEqual:redirectBaseURLString]) {
		
		//	Extract the query values on the request
		NSMutableDictionary	*queryResults = [NSMutableDictionary dictionaryWithCapacity:3];
		NSArray	*queryValues = [[[request URL] query] componentsSeparatedByString:@"&"];
		for (NSString *aQuery in queryValues) {
			NSString	*key = [aQuery substringToIndex:[aQuery rangeOfString:@"="].location];
			NSString	*value = [aQuery substringFromIndex:([aQuery rangeOfString:@"="].location + 1)];
			queryResults[key] = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		
		//	Test URL query values for error code
		if (queryResults[@"error"]) {
			
			//	access_denied = no token for me
			//	invalid_scope = bad scope value
			
			//	invalid_request = bad request, should be my fault
			
			//	unauthorized_client = self explanitory
			//	unsupported_response_type = self explanitory
			//	server_error = 500 equivalent
			//	temporarily_unavailable = 503 equivalent
			
			//	Construct a reasonable error message
			NSError	*anError = [NSError errorWithDomain:MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) code:101 userInfo:@{}];
			
			//	Call the finalize with it
			self.accessToken = nil;
			if (self.finalizeBlock) {
				self.finalizeBlock(self, anError);
			}
		}
		else {
			[self retreiveAccessTokenUsingCode:queryResults[@"code"]];
		}
		
	}
	[listener use];
}



@end
