//
//  MCCWebScriptWindowController.m
//  MailCommon
//
//  Created by smorr on 2013-09-24.
//  Copyright (c) 2013 Indev Software. All rights reserved.
//

#import "MCCWebScriptWindowController.h"
#import "MCCWebScriptPageController.h"

#if __has_feature(objc_arc)
#define RETAIN(x) (x)
#define RELEASE(x)
#define AUTORELEASE(x) (x)
#define DEALLOC(x) (x)
#else
#define RETAIN(x) ([(x) retain])
#define RELEASE(x) ([(x) release])
#define AUTORELEASE(x) ([(x) autorelease])
#define DEALLOC(x) ([(x) dealloc])
#endif



@interface MCC_PREFIXED_NAME(WebScriptWindowController) ()

@property	(assign)	IBOutlet	WebView		*webView;
@property	(strong)				NSString	*filePath;

@end

@implementation MCC_PREFIXED_NAME(WebScriptWindowController)

#pragma mark - Creation and Setup

- (id)init {
	self = [super init];
	if (self){
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        if ( ![myBundle loadNibNamed:[self nibName] owner:self topLevelObjects:nil]){
			NSLog( @"Warning: Failed to load nib" );
        }
	}
	return self;
}

- (void)awakeFromNib {
	[self.webView setUIDelegate:self];
	[self.webView setResourceLoadDelegate:self];
	[self.webView setFrameLoadDelegate:self];
	[[self.webView preferences] setJavaScriptEnabled:YES];
	[[[self.webView mainFrame] frameView] setAllowsScrolling:NO];
    [self addObserver:self forKeyPath:@"pageController" options:0 context:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([@"pageController" isEqualToString:keyPath]){
		[[self.webView windowScriptObject] setValue:self.pageController forKey:@"pageController"];
    }
    else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setPageControllerClassName:(NSString*)controllerClassName {
	Class  aClassName = NSClassFromString(controllerClassName);
	if (aClassName){
		MCC_PREFIXED_NAME(WebScriptPageController)	*controllerObject= [[aClassName alloc] init];
		if (controllerObject && [controllerObject isKindOfClass:[MCC_PREFIXED_NAME(WebScriptPageController) class]]){
			self.pageController = controllerObject;
			controllerObject.webView = self.webView;
		}
		else{
			NSLog(@"ERROR Class %@ does not inherit from %@!", controllerClassName, [MCC_PREFIXED_NAME(WebScriptPageController) class]);
			
		}
        RELEASE(controllerObject);
	}
	else{
		NSLog(@"ERROR cannot find Class %@!",controllerClassName);
		
	}
}

- (void)loadFile:(NSString*)fileName ofType:(NSString*)type {
	
	self.filePath = nil;
	NSBundle	*thisBundle = [NSBundle bundleForClass:[self class]];
    NSString	*contentPath = [thisBundle resourcePath];
    
	for (NSString *aLocalization in [thisBundle preferredLocalizations]) {
		NSString	*newPath = [contentPath stringByAppendingFormat:@"/%@.lproj/%@.%@",aLocalization,fileName,type];
		if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
			self.filePath = newPath;
			break;
		}
	}
	
	if (!self.filePath){
		self.filePath = [contentPath stringByAppendingFormat:@"/en.lproj/%@.%@",fileName,type];
	}
	
    if (self.filePath) {
        [self.webView setMainFrameURL:self.filePath];
        self.pageController = nil;
		
	}
	
	NSString * html = [NSString stringWithContentsOfFile:self.filePath encoding:NSUTF8StringEncoding error:nil];
	
	NSArray	*lines = [html componentsSeparatedByString:@"\n"];
	for (NSString *aLine in lines) {
		NSRange	configRange = [aLine rangeOfString:@"<!--config--"];
		if (configRange.location != NSNotFound) {
			NSString	*configString = [[aLine substringFromIndex:(configRange.location + configRange.length)] stringByReplacingOccurrencesOfString:@"-->" withString:@""];
			if ([configString hasPrefix:@"size:"]) {
				NSWindow	*window = self.window;
				configString = [[configString stringByReplacingOccurrencesOfString:@"size:" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				NSSize	size = NSSizeFromString(configString);
				NSRect	winFrame = [window frame];
				NSSize	winContentSize = [[self.window contentView] frame].size;
				CGFloat	chromeHeightDifference = winFrame.size.height - winContentSize.height;
				CGFloat	newWindowHeight = size.height + chromeHeightDifference;
				winFrame.origin.x -= floorf((size.width - winFrame.size.width) / 2.0f);
				winFrame.size.width = size.width;
				winFrame.origin.y -= newWindowHeight - winFrame.size.height;
				winFrame.size.height = newWindowHeight;
				//	Stay below the menu
				if (winFrame.origin.y < 40){
					winFrame.origin.y = 40;
				}
				//	Don't get taller than MBA 11" content area
				if (winFrame.size.height > 655) {
					winFrame.size.height = 655;
				}
				[window setFrame:winFrame display:YES animate:YES];
				NSLog(@"Setting Window size to:%@", NSStringFromSize(winFrame.size));
			}
		}
		else if ([aLine rangeOfString:@"</head>"].location != NSNotFound) {
			break;
		}
	}
	
	NSLog(@"Window size is:%@", NSStringFromSize([self.window frame].size));
}

- (void)closeWindow {
    [[self.webView window] close];
}


- (void)showEmbeddedPage:(NSString *)pageName {
	NSString	*extension = @"html";
	if ([[pageName pathExtension] length] > 0) {
		extension = [pageName pathExtension];
	}
	[self loadFile:[pageName stringByDeletingPathExtension] ofType:extension];
	if (![[self window] isVisible]) {
		[[self window] center];
	}
	[self showWindow:nil];
}


#pragma mark - Added JS Methods

- (void)showWindowAndLoadURL:(NSURL*)url {
	if (![[self window] isVisible]) {
		[[self window] center];
	}
	[[self window] makeKeyAndOrderFront:self];
	[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)openURL:(NSString*)urlString {
	NSURL* url = [NSURL URLWithString:urlString];
	if ([url host]){
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
	else {
		[self loadFile:[[url URLByDeletingPathExtension] absoluteString] ofType:[url pathExtension]];
	}
    
}

- (void)log:(id)logString {
	if (logString && [logString isKindOfClass:NSClassFromString(@"DOMNodeList")]){
		NSMutableArray	*list = [NSMutableArray arrayWithCapacity:[(DOMNodeList*)logString length]];
		for (NSInteger i = 0; i<[(DOMNodeList*)logString length]; i++){
			[list addObject:[logString item:(int)i]];
		}
		NSLog(@"Javascript Log: %@", list);
	}
	else
		NSLog(@"Javascript Log: %@", logString);
}


#pragma mark - WebView Methods

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	[self.webView setHidden:NO];
	if (![[self window] isVisible]) {
		[[self window] makeKeyAndOrderFront:self];
	}
	
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame {
    [windowScriptObject setValue:self forKey:@"windowController"];
    [windowScriptObject setValue:self forKey:@"console"];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel {
    if (sel == @selector(setPageControllerClassName:)){
        return NO;
    }
    if (sel == @selector(log:)){
        return NO;
    }
    if (sel == @selector(openURL:)){
        return NO;
    }
    if (sel == @selector(closeWindow)){
        return NO;
    }
    if (sel == @selector(showEmbeddedPage:)){
        return NO;
    }
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel {
	
    if (sel == @selector(setPageControllerClassName:)){
        return @"setPageControllerClassName";
    }
    if (sel == @selector(log:)){
        return @"log";
    }
    if (sel == @selector(openURL:)){
        return @"openURL";
    }
    if (sel == @selector(closeWindow)){
        return @"closeWindow";
    }
    if (sel == @selector(showEmbeddedPage:)){
        return @"showEmbeddedPage";
    }
    else {
		return nil;
	}
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
    return YES;
}

+ (NSString *)webScriptNameForKey:(const char *)name {
 	return nil;
}



#pragma mark - Methods to Override

- (NSString*)nibName {
	NSAssert(NO, @"Override nibName for your WebScriptWindowController");
    return nil;
}


#pragma mark - Class Methods

+ (instancetype)sharedInstance {
	static dispatch_once_t pred;
	static MCC_PREFIXED_NAME(WebScriptWindowController)	*_sharedInstance = nil;
	
	dispatch_once(&pred, ^{
		_sharedInstance = [[(Class)self alloc] init];
	});
	return _sharedInstance;
    
}


@end

