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

#ifndef	MCCLog
#define	MCCLog(frmt, ...)	NSLog(frmt, ##__VA_ARGS__)
#endif

NSString *URLEncodedStringForString(NSString *inputString);

#define STANDARD_GRANT	@"authorization_code"
#define REFRESH_GRANT	@"refresh_token"

//	Expire the token 5 minutes before it should refresh
#define EXPIRE_BUFFER_INTERVAL	(5.0f * 60.0f)

NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) = @"SimpleOAuth2ErrorDomain";
NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationNotification) = @"SimpleOAuth2AuthorizationNotification";
NSString *const MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationFailedNotification) = @"SimpleOAuth2AuthorizationFailedNotification";

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
@property (strong) NSString	*grantType;
@property (strong) NSString *serviceName;
@property (strong) NSString *bundleID;
@property (assign) MCC_PREFIXED_NAME(SimpleOAuthStorageType) storageType;
@end


@implementation MCC_PREFIXED_NAME(SimpleOAuth2)

- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName
					 storageType:(MCC_PREFIXED_NAME(SimpleOAuthStorageType))aStorageType
						bundleID:(NSString *)aStorageBundleID {
	
	NSAssert(IS_NOT_EMPTY(aClientId), @"The Client ID cannot be empty for SimpleOAuth2");
	NSAssert(IS_NOT_EMPTY(aSecret), @"The Client Secret cannot be empty for SimpleOAuth2");
	NSAssert((anEndpointURL != nil), @"The endpoint URL cannot be nil for SimpleOAuth2");
	NSAssert([[anEndpointURL scheme] isEqualToString:@"https"], @"The endpoint URL for SimpleOAuth2 must be https");
	NSAssert((aRedirectURL != nil), @"The redirect URL cannot be nil for SimpleOAuth2");
	NSAssert((aTokenURL != nil), @"The token URL cannot be nil for SimpleOAuth2");
	NSAssert([[aTokenURL scheme] isEqualToString:@"https"], @"The token URL for SimpleOAuth2 must be https");
	NSAssert(IS_NOT_EMPTY(aServiceName), @"The Service name cannot be empty for SimpleOAuth2");
	self = [super init];
	
	if (self) {
		self.clientId = aClientId;
		self.clientSecret = aSecret;
		self.endpointURL = anEndpointURL;
		self.tokenURL = aTokenURL;
		self.redirectURL = aRedirectURL;
		self.grantType = STANDARD_GRANT;
		self.encodedRedirectURLString = URLEncodedStringForString([self.redirectURL absoluteString]);
		self.scope = @"all";
		self.serviceName = aServiceName;
		self.storageType = aStorageType;
		self.bundleID = aStorageBundleID;
		self.tokenAccountName = [NSString stringWithFormat:@"%@: Access Token", aServiceName];
		self.refreshAccountName = [NSString stringWithFormat:@"%@: Refresh Token", aServiceName];
		self.tokenExpiresAccountName = [NSString stringWithFormat:@"%@: Date Token Expires", aServiceName];
		
		self.accessToken = [self storedTokenForKey:self.tokenAccountName];
		NSString	*expiresTimeIntervalString = [self storedTokenForKey:self.tokenExpiresAccountName];
		if (expiresTimeIntervalString) {
			if ([self resetRefreshTimerWithTimeIntervalSinceReferenceDate:[expiresTimeIntervalString doubleValue]]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationNotification) object:self];
				});
			}
		}
		
		//	Set to receive notifications for sleep, wake and clock changes in order to adjust the token renewing.
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(resetTimerFromNotification:) name:NSWorkspaceWillSleepNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(resetTimerFromNotification:) name:NSWorkspaceDidWakeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTimerFromNotification:) name:NSSystemClockDidChangeNotification object:nil];
		
	}
	return self;
}

- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName
					 storageType:(MCC_PREFIXED_NAME(SimpleOAuthStorageType))aStorageType {
	return [self initWithClientId:aClientId clientSecret:aSecret endpointURL:anEndpointURL tokenURL:aTokenURL redirectURL:aRedirectURL forServiceName:aServiceName storageType:aStorageType bundleID:nil];
}

- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName
						bundleID:(NSString *)aStorageBundleID {
	return [self initWithClientId:aClientId clientSecret:aSecret endpointURL:anEndpointURL tokenURL:aTokenURL redirectURL:aRedirectURL forServiceName:aServiceName storageType:MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeDefaults) bundleID:aStorageBundleID];
}

- (instancetype)initWithClientId:(NSString *)aClientId
					clientSecret:(NSString *)aSecret
					 endpointURL:(NSURL *)anEndpointURL
						tokenURL:(NSURL *)aTokenURL
					 redirectURL:(NSURL *)aRedirectURL
				  forServiceName:(NSString *)aServiceName {
	return [self initWithClientId:aClientId clientSecret:aSecret endpointURL:anEndpointURL tokenURL:aTokenURL redirectURL:aRedirectURL forServiceName:aServiceName storageType:MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeDefaults) bundleID:nil];
}


#pragma mark - Public Methods

- (void)authorize {
	if ([self alreadyHasToken]) {
		return;
	}
	NSString	*scopeParameter = @"";
	if (IS_NOT_EMPTY(self.scope)) {
		NSString	*encodedScope = [self.scope stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		scopeParameter = [NSString stringWithFormat:@"&scope=%@", encodedScope];
	}
	NSString	*urlString = [NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=code%@", [self.endpointURL absoluteString], self.clientId, self.encodedRedirectURLString, scopeParameter];
	NSURL	*loadURL = [NSURL URLWithString:urlString];
	if (loadURL) {
		[[self.webview mainFrame] loadRequest:[NSURLRequest requestWithURL:loadURL]];
	}
	else {
		NSError	*anError = [NSError errorWithDomain:@"MCCSimpleOAuth2" code:101 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"I could not authorize with the URL '%@' - it couldn't be made into a valid URL", urlString]}];
		[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationFailedNotification) object:self userInfo:@{@"error": anError}];
	}
}

- (void)deauthorize {
	self.accessToken = nil;
	[self deleteTokenForKey:self.refreshAccountName];
	[self deleteTokenForKey:self.tokenAccountName];
	[self deleteTokenForKey:self.tokenExpiresAccountName];
}


#pragma mark - Internal Methods

- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.refreshTimer invalidate];
	
#if !__has_feature(objc_arc)
	self.accessToken = nil;
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
		NSError	*error = nil;
		if ((self.webview == nil) && (self.accessToken == nil)) {
			error = [NSError errorWithDomain:MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) code:MCC_PREFIXED_CONSTANT(SimpleOAuthErrorNoWebView) userInfo:@{}];
		}
		__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			NSDictionary	*userInfo = nil;
			NSString		*note = MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationNotification);
			if (error) {
				userInfo = @{@"error": error};
				note = MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationFailedNotification);
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:note object:welf userInfo:userInfo];
		}];
		return YES;
	}
	return NO;
}

- (void)processResultsOfAuthResponse:(NSURLResponse *)response withData:(NSData *)data error:(NSError *)connectionError {
	
	//	Remove any existing accessToken
	[self deleteTokenForKey:self.tokenAccountName];
	[self deleteTokenForKey:self.tokenExpiresAccountName];
	[self resetRefreshTimerWithTimeIntervalSinceReferenceDate:0.0f];
	
	NSError		*error = nil;
	if (connectionError) {
		error = connectionError;
	}
	else {
		NSDictionary	*resultDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (error == nil) {
			
			if (resultDict[@"error"]) {
				
				error = [NSError errorWithDomain:MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) code:MCC_PREFIXED_CONSTANT(SimpleOAuthErrorRetrievingToken) userInfo:@{@"IFS_ERROR_INFO": resultDict}];
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
				self.accessToken = resultDict[@"access_token"];
				self.scope = resultDict[@"scope"];
				
				//	Store the token in the keychain
				if (self.accessToken) {
					[self setStoredToken:self.accessToken forKey:self.tokenAccountName];
				}
				
				//	Store the expiration date in the keychain as well, if there is one
				if (resultDict[@"expires_in"]) {
					NSTimeInterval	expireTimeIntervalSinceRefDate = [NSDate timeIntervalSinceReferenceDate] + [resultDict[@"expires_in"] integerValue];
					MCCLog(@"ExpireTimeInterval = '%@' aka %@!!!!", [@(expireTimeIntervalSinceRefDate) stringValue], [NSDate dateWithTimeIntervalSinceReferenceDate:expireTimeIntervalSinceRefDate]);
					[self setStoredToken:[@(expireTimeIntervalSinceRefDate) stringValue] forKey:self.tokenExpiresAccountName];

					//	Reset the timer for the next expiry
					[self resetRefreshTimerWithTimeIntervalSinceReferenceDate:expireTimeIntervalSinceRefDate];
				}
				
				//	Store the refresh token in the keychain as well, if there is one
				if (resultDict[@"refresh_token"]) {
					[self deleteTokenForKey:self.refreshAccountName];
					[self setStoredToken:resultDict[@"refresh_token"] forKey:self.refreshAccountName];
				}
			}
		}
	}
	
	__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		NSDictionary	*userInfo = nil;
		NSString		*note = MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationNotification);
		if (error) {
			userInfo = @{@"error": error};
			note = MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationFailedNotification);
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:note object:welf userInfo:userInfo];
	}];
}

- (void)renewAccessToken:(NSTimer *)aTimer {
	MCCLog(@"Renewing the access token at: %@", [NSDate date]);
	[self resetRefreshTimerWithTimeIntervalSinceReferenceDate:0.0f];
	NSString	*refreshToken = [self storedTokenForKey:self.refreshAccountName];
	NSString	*postBodyString = [NSString stringWithFormat:@"grant_type=%@&refresh_token=%@", REFRESH_GRANT, refreshToken];
	NSMutableURLRequest	*accessRequest = [NSMutableURLRequest requestWithURL:self.tokenURL];
	[accessRequest setHTTPMethod:@"POST"];
	[accessRequest setHTTPBody:[postBodyString dataUsingEncoding:NSUTF8StringEncoding]];
	[accessRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[accessRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[accessRequest addValue:[NSString stringWithFormat:@"%@", @([postBodyString length])] forHTTPHeaderField:@"Content-Length"];
	NSString	*authValue = [[[NSString stringWithFormat:@"%@:%@", self.clientId, self.clientSecret] dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
	[accessRequest addValue:[NSString stringWithFormat:@"Basic %@", authValue] forHTTPHeaderField:@"Authorization"];
	
	__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
	[NSURLConnection sendAsynchronousRequest:accessRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		[welf processResultsOfAuthResponse:response withData:data error:connectionError];
	}];
}

- (void)retreiveAccessTokenUsingCode:(NSString *)aCode {
	
	NSString	*postBodyString = [NSString stringWithFormat:@"grant_type=%@&client_id=%@&client_secret=%@&code=%@&redirect_uri=%@", self.grantType, self.clientId, self.clientSecret, aCode, self.encodedRedirectURLString];
	NSMutableURLRequest	*accessRequest = [NSMutableURLRequest requestWithURL:self.tokenURL];
	[accessRequest setHTTPMethod:@"POST"];
	[accessRequest setHTTPBody:[postBodyString dataUsingEncoding:NSUTF8StringEncoding]];
	[accessRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[accessRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[accessRequest addValue:[NSString stringWithFormat:@"%@", @([postBodyString length])] forHTTPHeaderField:@"Content-Length"];
	
	__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
	[NSURLConnection sendAsynchronousRequest:accessRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		[welf processResultsOfAuthResponse:response withData:data error:connectionError];
	}];
	
}

- (BOOL)resetRefreshTimerWithTimeIntervalSinceReferenceDate:(NSTimeInterval)expiresInterval {
	MCCLog(@"Resetting the refresh timer: %@", @(expiresInterval));
	[self.refreshTimer invalidate];
	self.refreshTimer = nil;
	BOOL	wasReset = NO;
	if (expiresInterval > 0.1f) {
		NSDate	*expiresDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(expiresInterval - EXPIRE_BUFFER_INTERVAL)];
		MCCLog(@"Expires date is:%@", expiresDate);
		if ([expiresDate timeIntervalSinceDate:[NSDate date]] < 0) {
			[self renewAccessToken:nil];
		}
		else {
			MCCLog(@"Setting a new timer");
			NSTimer	*aTimer = [[NSTimer alloc] initWithFireDate:expiresDate interval:1.0 target:self selector:@selector(renewAccessToken:) userInfo:nil repeats:NO];
			self.refreshTimer = aTimer;
			[[NSRunLoop mainRunLoop] addTimer:aTimer forMode:NSRunLoopCommonModes];
			MCC_RELEASE(aTimer);
			wasReset = YES;
		}
	}
	return wasReset;
}

- (void)resetTimerFromNotification:(NSNotification *)aNote {
	MCCLog(@"Received notification to reset timer: %@", aNote);
	NSTimeInterval	expiresInterval = 0.0f;
	if (![[aNote name] isEqualToString:NSWorkspaceWillSleepNotification]) {
		NSString	*expiresTimeIntervalString = [self storedTokenForKey:self.tokenExpiresAccountName];
		if (expiresTimeIntervalString) {
			expiresInterval = [expiresTimeIntervalString doubleValue];
		}
	}
	[self resetRefreshTimerWithTimeIntervalSinceReferenceDate:expiresInterval];
}


#pragma mark - Storing Values

- (id)storedTokenForKey:(NSString *)key {
	id	newValue = nil;
	switch (self.storageType) {
		case MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeDefaults):
			if (self.bundleID == nil) {
				[[NSUserDefaults standardUserDefaults] objectForKey:key];
			}
			else {
				id	domainDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:self.bundleID];
				newValue = [domainDefaults objectForKey:key];
			}
			break;
			
		case MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeKeychain):
			newValue = [MCC_PREFIXED_NAME(Keychain) passwordForService:key account:key];
			break;
	}
	return newValue;
}

- (void)deleteTokenForKey:(NSString *)key {
	switch (self.storageType) {
		case MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeDefaults):
			if (self.bundleID == nil) {
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
			}
			else {
				NSMutableDictionary		*domainDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:self.bundleID] mutableCopy];
				[domainDefaults removeObjectForKey:key];
				[[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionaryWithDictionary:domainDefaults] forName:self.bundleID];
				[domainDefaults release];
			}
			break;
			
		case MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeKeychain):
			[MCC_PREFIXED_NAME(Keychain) deletePasswordForService:key account:key];
			break;
	}
}

- (void)setStoredToken:(id)newValue forKey:(NSString *)key {
	switch (self.storageType) {
		case MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeDefaults):
			if (self.bundleID == nil) {
				[[NSUserDefaults standardUserDefaults] setObject:newValue forKey:key];
			}
			else {
				NSMutableDictionary		*domainDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:self.bundleID] mutableCopy];
				[domainDefaults setObject:newValue forKey:key];
				[[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionaryWithDictionary:domainDefaults] forName:self.bundleID];
				[domainDefaults release];
			}
			break;
			
		case MCC_PREFIXED_CONSTANT(SimpleOAuthStorageTypeKeychain):
			[MCC_PREFIXED_NAME(Keychain) setPassword:newValue forService:key account:key];
			break;
	}
}


#pragma mark - WebView Delegate Methods

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
	MCCLog(@"Need to decide policy for navigation of request: %@", request);
	
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
			NSError	*anError = [NSError errorWithDomain:MCC_PREFIXED_CONSTANT(SimpleOAuth2ErrorDomain) code:MCC_PREFIXED_CONSTANT(SimpleOAuthErrorNavigation) userInfo:@{@"IFS_ERROR_INFO": queryResults}];
			
			//	Call the finalize with it
			self.accessToken = nil;
			
			__block	MCC_PREFIXED_NAME(SimpleOAuth2)	*welf = self;
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[[NSNotificationCenter defaultCenter] postNotificationName:MCC_PREFIXED_CONSTANT(SimpleOAuth2AuthorizationFailedNotification) object:welf userInfo:@{@"error": anError}];
			}];
		}
		else {
			[self retreiveAccessTokenUsingCode:queryResults[@"code"]];
		}
		
	}
	[listener use];
}



@end

NSString *URLEncodedStringForString(NSString *inputString) {

	if (OSVERSION > MCC_PREFIXED_NAME(OSVersionMountainLion)) {
		return [inputString stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"] invertedSet]];
	}
	
	NSMutableString	*outputString = [[inputString mutableCopy] autorelease];
	//	Do the percent first outside of the dictionary to ensure it is first
	[outputString replaceOccurrencesOfString:@"%" withString:@"%25" options:0 range:NSMakeRange(0, [outputString length])];
	NSDictionary	*mappings = @{@"!": @"%21",
								  @"*": @"%2A",
								  @"'": @"%27",
								  @"(": @"%28",
								  @")": @"%29",
								  @";": @"%3B",
								  @":": @"%3A",
								  @"@": @"%40",
								  @"&": @"%26",
								  @"=": @"%3D",
								  @"+": @"%2B",
								  @"$": @"%24",
								  @",": @"%2C",
								  @"/": @"%2F",
								  @"?": @"%3F",
								  @"#": @"%23",
								  @"[": @"%5B",
								  @"]": @"%5D"};
	[mappings enumerateKeysAndObjectsUsingBlock:^(NSString *charString, NSString *replacement, BOOL *stop) {
		[outputString replaceOccurrencesOfString:charString withString:replacement options:0 range:NSMakeRange(0, [outputString length])];
	}];
	
	return [NSString stringWithString:outputString];
}

