//
//  MCCSimpleOAuth2.m
//  OAuth Tester
//
//  Created by Scott Little on 4/5/14.
//  Copyright (c) 2014 Little Known Software, Inc. All rights reserved.
//

#import "MCCSimpleOAuth2.h"
#import "MCCUtilities.h"


@interface MCC_PREFIXED_NAME(SimpleOAuth2) ()
@property (strong) NSString	*clientId;
@property (strong) NSString	*clientSecret;
@property (strong) NSURL	*endpointURL;
@property (strong) NSURL	*tokenURL;
@property (strong) NSURL	*redirectURL;
@property (strong) NSString	*encodedRedirectURLString;
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
		self.encodedRedirectURLString = [[self.redirectURL absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]];
		self.scope = @"all";
	}
	return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc {
	self.accessCode = nil;
	self.clientId = nil;
	self.clientSecret = nil;
	self.endpointURL = nil;
	self.tokenURL = nil;
	self.redirectURL = nil;
	self.encodedRedirectURLString = nil;
	[super dealloc];
}
#endif

- (void)authorizeWithFinalize:(MCC_PREFIXED_NAME(SimpleOAuth2FinalizeBlock))aFinalizeBlock {
	if (self.webview == nil) {
		if (aFinalizeBlock) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				aFinalizeBlock(self, nil);
			}];
			return;
		}
	}
	
	self.finalizeBlock = aFinalizeBlock;
	NSURL	*loadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=code&scope=%@", [self.endpointURL absoluteString], self.clientId, self.encodedRedirectURLString, self.scope]];
	[[self.webview mainFrame] loadRequest:[NSURLRequest requestWithURL:loadURL]];
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
				welf.finalizeBlock(welf, welf.accessToken);
			}
		}
		
		//	{"token_type":"bearer","mapi":"zhwsreh629pmketed3wca42u","access_token":"s55dvvucwkwq4rrn2ray8jwt","scope":"all|tr111.infusionsoft.com"}
	}];
}

#pragma mark WebView Delegate Methods

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
	NSLog(@"Need to decide policy for navigation of request: %@", request);
	
	NSString	*resultBaseURLString = [NSString stringWithFormat:@"%@://%@%@", [[request URL] scheme], [[request URL] host], [[request URL] path]];
	NSString	*redirectBaseURLString = [NSString stringWithFormat:@"%@://%@%@", [self.redirectURL scheme], [self.redirectURL host], [self.redirectURL path]];
	
	if ([resultBaseURLString isEqual:redirectBaseURLString]) {
		
		NSMutableDictionary	*queryResults = [NSMutableDictionary dictionaryWithCapacity:3];
		NSArray	*queryValues = [[[request URL] query] componentsSeparatedByString:@"&"];
		for (NSString *aQuery in queryValues) {
			NSString	*key = [aQuery substringToIndex:[aQuery rangeOfString:@"="].location];
			NSString	*value = [aQuery substringFromIndex:([aQuery rangeOfString:@"="].location + 1)];
			queryResults[key] = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		
		[self retreiveAccessTokenUsingCode:queryResults[@"code"]];
		
//		self.accessCode = queryResults[@"code"];
//		NSLog(@"Scope returned is:'%@'", queryResults[@"scope"]);
//		if (self.finalizeBlock) {
//			self.finalizeBlock(self, self.accessCode);
//		}
	}
	[listener use];
}



@end
