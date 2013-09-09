//
//  MCCSwizzle.h
//  MailCommonCode
//
//  Created by Scott Little on 24/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MCCSwizzle.h"
#import <objc/objc-runtime.h>

@interface MCC_PREFIXED_NAME(Swizzle) ()
+ (BOOL)addMethodName:(NSString *)methodName toClass:(Class)targetClass fromProviderClass:(Class)providerClass methodName:(NSString*)providerMethodName isClassMethod:(BOOL)isClassMethod;
+ (void)processMethods:(Method *)methods count:(NSInteger)countDecrementer passingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging isClassMethod:(BOOL)isClassMethod;
+ (BOOL)addIvarsToClass:(Class)subclass passingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))testBlock withDebugging:(BOOL)debugging;
@end

#ifdef DEBUG
#define DEFAULT_DEBUGGING	1
#else
#define DEFAULT_DEBUGGING	0
#endif

@implementation MCC_PREFIXED_NAME(Swizzle)

#pragma mark - Main Entry Points

+ (Class)makeSubclassOf:(Class)baseClass usingClassName:(NSString*)subclassName {
	return [self makeSubclassOf:baseClass usingClassName:subclassName addIvarsPassingTest:nil];
}

+ (Class)makeSubclassOf:(Class)baseClass usingClassName:(NSString*)subclassName addIvarsPassingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))testBlock {
	
	Class subclass = objc_allocateClassPair(baseClass, [subclassName UTF8String], 0);
	if (!subclass) return nil;
	
	//	Add the ivars and register subclass
	if (![self addIvarsToClass:subclass passingTest:testBlock withDebugging:DEFAULT_DEBUGGING]) {
		return nil;
	}
	objc_registerClassPair(subclass);
	
	//	Then add all methods, since this is a subclass
	[self addMethodsPassingTest:^MCC_PREFIXED_NAME(SwizzleType)(NSString *methodName) {
		return MCC_PREFIXED_NAME(SwizzleTypeAdd);
	} ivarsPassingTest:nil toClass:subclass usingPrefix:@"" withDebugging:DEFAULT_DEBUGGING];
	
	return subclass;
}

+ (void)swizzle {
	NSRange		underscoreRange = [[self className] rangeOfString:@"_"];
	if (underscoreRange.location == NSNotFound) {
		NSLog(@"Could not swizzle class %@ - it has no suffix", [self className]);
		return;
	}
	NSString	*targetClassName = [[self className] substringToIndex:underscoreRange.location];
	NSString	*prefix = [NSString stringWithFormat:@"%@_", [[self className] substringFromIndex:underscoreRange.location + 1] ];
	
	if (!MCC_PREFIXED_NAME(ClassFromString)(targetClassName)) {
		NSLog(@"Class %@ was not found to swizzle", targetClassName);
	}
	
	[self addAllMethodsToClass:MCC_PREFIXED_NAME(ClassFromString)(targetClassName) usingPrefix:prefix];
}

+ (void)addAllMethodsToClass:(Class)targetClass usingPrefix:(NSString*)prefix {
	[self addMethodsPassingTest:nil ivarsPassingTest:nil toClass:targetClass usingPrefix:prefix withDebugging:DEFAULT_DEBUGGING];
}

+ (void)addMethodsPassingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock ivarsPassingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))ivarTestBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging {
    
	unsigned int	methodCount = 0;
	Method			*methods = nil;
	
	//	Add ivars IF and Only IF there is a test
	if (ivarTestBlock != nil) {
		[self addIvarsToClass:targetClass passingTest:ivarTestBlock withDebugging:debugging];
	}
	
	// Extend instance Methods
	methods = class_copyMethodList(self, &methodCount);
	[self processMethods:methods count:(NSInteger)methodCount passingTest:testBlock toClass:targetClass usingPrefix:prefix withDebugging:debugging isClassMethod:NO];
	
	free(methods);
	
	// Extend Class Methods
	methods = class_copyMethodList(object_getClass(self), &methodCount);
	[self processMethods:methods count:(NSInteger)methodCount passingTest:testBlock toClass:targetClass usingPrefix:prefix withDebugging:debugging isClassMethod:YES];
	free(methods);
	
	methods = NULL;
	
}


#pragma mark - Actual Swizzling Methods

+ (BOOL)addMethodName:(NSString *)methodName toClass:(Class)targetClass fromProviderClass:(Class)providerClass methodName:(NSString*)providerMethodName isClassMethod:(BOOL)isClassMethod {
	
	//	If this is a class method, get the meta class
	if (isClassMethod) {
		targetClass = object_getClass(targetClass);
	}
	
	//	If there isn't one return
	if (targetClass == nil) {
		return NO;
	}
	
	//	Get our selector and method names
	SEL		providerSelector = NSSelectorFromString(providerMethodName);
	Method	originalMethod = class_getInstanceMethod(providerClass,providerSelector);
	if (isClassMethod) {
		originalMethod = class_getClassMethod(providerClass,providerSelector);
	}
	
	//	If there is no original method do thing
	if (originalMethod == nil) {
		return NO;
	}
	
	IMP		originalImplementation  = method_getImplementation(originalMethod);
	if (originalImplementation == NULL){
		return NO;
	}
    SEL		targetSelector = NSSelectorFromString(methodName);

	//	Add the method
	class_addMethod(targetClass, targetSelector, originalImplementation, method_getTypeEncoding(originalMethod));
	
	return YES;
}

#if (DEFAULT_DEBUGGING == 1)
#define SWIZ_LOG(s, ...)	{if (debugging) NSLog(s, ## __VA_ARGS__);}
#else
#define SWIZ_LOG(s, ...)	
#endif

+ (void)processMethods:(Method *)methods count:(NSInteger)countDecrementer passingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging isClassMethod:(BOOL)isClassMethod {
	
	SWIZ_LOG(@"%ld methods to test from provider %@", (long)countDecrementer, self);
	
	while (methods && countDecrementer--){
        SEL			providerMethodSelector = method_getName(methods[countDecrementer]);
		NSString	*providerMethodName = NSStringFromSelector(providerMethodSelector);
		//	Always skip the load selector to avoid deadlocks
		if ([providerMethodName isEqualToString:@"load"]) { continue; }
		
		NSString	*categoryMethodName = providerMethodName;
		BOOL		justAddMethod = NO;
		
		//	If there is a test block, see if and how this method should be swizzled
		if (testBlock != nil) {
			switch (testBlock(providerMethodName)) {
				case MCC_PREFIXED_NAME(SwizzleTypeNone):
					continue;
					break;
					
				case MCC_PREFIXED_NAME(SwizzleTypeAdd):
					justAddMethod = YES;
					break;
					
				default:
					break;
			}
		}
		
		//	Just add the method if that is appropriate
        Method		oldMethod = class_getInstanceMethod(targetClass, providerMethodSelector);
		if (isClassMethod) {
			oldMethod = class_getClassMethod(targetClass, providerMethodSelector);
		}
        if (justAddMethod || (oldMethod == NULL)) {
			SWIZ_LOG(@"Adding %@ method %@ with provider method %@ to class %@", (isClassMethod?@"class":@"instance"), categoryMethodName, providerMethodName, NSStringFromClass(targetClass));
            // no existing method -- so add it as a category method/or override
            [self addMethodName:categoryMethodName 
						toClass:targetClass 
			  fromProviderClass:self 
					 methodName:providerMethodName
				  isClassMethod:isClassMethod];
            continue;
        }
		//	Otherwise swizzle it
        else{
        	categoryMethodName = [prefix stringByAppendingString:providerMethodName];
			SEL		categoryMethodSelector = NSSelectorFromString(categoryMethodName);
			
			SWIZ_LOG(@"Swizzling %@ method %@ with %@ on class %@", (isClassMethod?@"class":@"instance"), categoryMethodName, providerMethodName, NSStringFromClass(targetClass));
			[self addMethodName:categoryMethodName 
						toClass:targetClass 
			  fromProviderClass:self 
					 methodName:providerMethodName
				  isClassMethod:isClassMethod];
			
			Method	newMethod = class_getInstanceMethod(targetClass, categoryMethodSelector);
			if (isClassMethod) {
				newMethod = class_getClassMethod(targetClass, categoryMethodSelector);
			}
			if (newMethod==NULL) {
				NSLog(@"SWIZZLE Error - Can't find target method for -[%@ %@]",NSStringFromClass(targetClass),NSStringFromSelector(categoryMethodSelector));
				continue;
			}
			IMP		oldIMP = method_setImplementation(oldMethod,method_getImplementation(newMethod));
			method_setImplementation(newMethod, oldIMP);
        }
	}
}

+ (BOOL)addIvarsToClass:(Class)subclass passingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))testBlock withDebugging:(BOOL)debugging {

	@autoreleasepool {
		unsigned int ivarCount = 0;
		Ivar * ivars = class_copyIvarList(self, &ivarCount);
		
		SWIZ_LOG(@"%d ivars to add to subclass from provider %@", ivarCount, self);
		
		unsigned int ci = 0;
		for (ci = 0 ;ci < ivarCount; ci++) {
			Ivar anIvar = ivars[ci];
			
			NSUInteger ivarSize = 0;
			NSUInteger ivarAlignment = 0;
			const char * typeEncoding = ivar_getTypeEncoding(anIvar);
			NSGetSizeAndAlignment(typeEncoding, &ivarSize, &ivarAlignment);
			const char * ivarName = ivar_getName(anIvar);
			NSString * ivarStringName = [NSString stringWithUTF8String:ivarName];
			if ((testBlock == nil) || testBlock(ivarStringName)){
				BOOL addIVarResult = class_addIvar(subclass, ivarName, ivarSize, ivarAlignment, typeEncoding);
				if (!addIVarResult){
					SWIZ_LOG(@"Could not add iVar %s", ivarName);
					return NO;
				}
				SWIZ_LOG(@"Added iVar %s", ivarName);
			}
		}
		free(ivars);
	}
	
	return YES;
}

#undef SWIZ_LOG


#pragma mark - Utility Method

+ (void)printAllIvarsForClass:(Class)aClass {

	NSLog(@"iVars for class:%@", NSStringFromClass(aClass));
	unsigned int ivarCount = 0;
	Ivar	*ivars = class_copyIvarList(aClass, &ivarCount);
	unsigned int ci = 0;
	for (ci = 0 ;ci < ivarCount; ci++) {
		Ivar anIvar = ivars[ci];
		NSLog(@"iVar[%d] %s", ci, ivar_getName(anIvar));
	}
	free(ivars);

}

+ (void)printAllMethodsForClass:(Class)aClass {
	NSLog(@"Methods for Class:%@", NSStringFromClass(aClass));
	unsigned int methodCount = 0;
	Method * methods = nil;
	// extend instance Methods
	methods = class_copyMethodList(aClass, &methodCount);
	int ci = methodCount;
	
	NSLog(@"  Instance Methods:");
	while (methods && ci--){
		NSString	*providerMethodName = NSStringFromSelector(method_getName(methods[ci]));
		NSLog(@"    - ()%@", providerMethodName);
	}
	free(methods);

	// extend Class Methods
	methods = class_copyMethodList(object_getClass(aClass), &methodCount);
	ci = methodCount;
	NSLog(@"  Class Methods:");
	while (methods && ci--){
		NSString	*providerMethodName = NSStringFromSelector(method_getName(methods[ci]));
		NSLog(@"    + ()%@", providerMethodName);
	}
	free(methods);
}

+ (void)printAllMethodsInHierarchyOfClass:(Class)aClass {
	Class	superClass = [aClass superclass];
	while (aClass != superClass) {
		[self printAllMethodsForClass:aClass];
		aClass = superClass;
		superClass = object_getClass(aClass);
	}
}

+ (NSString *)memoryLocationOfMethodNamed:(NSString *)methodName forClassNamed:(NSString *)className {
	BOOL	isClassMethod = NO;
	
	if (IsEmpty(methodName)) {
		return @"No Method";
	}
	
	if (IsEmpty(className)) {
		return @"No Class";
	}
	
	if ([[methodName substringToIndex:1] isEqualToString:@"+"]) {
		isClassMethod = YES;
		methodName = [methodName substringFromIndex:1];
	}
	else if ([[methodName substringToIndex:1] isEqualToString:@"-"]) {
		methodName = [methodName substringFromIndex:1];
	}
	
	if (!DBGClassFromString(className)) {
		return [NSString stringWithFormat:@"Class %@ was not found.", className];
	}
	
	if (!NSSelectorFromString(methodName)) {
		return [NSString stringWithFormat:@"Selector %@ was not found.", methodName];
	}
	
	if (isClassMethod) {
		return [NSString stringWithFormat:@"%p", method_getImplementation(class_getClassMethod(DBGClassFromString(className), NSSelectorFromString(methodName)))];
	}
	else {
		return [NSString stringWithFormat:@"%p", class_getMethodImplementation(DBGClassFromString(className), NSSelectorFromString(methodName))];
	}
	
}


@end
