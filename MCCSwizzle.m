//
//  MCCSwizzle.h
//  MailCommonCode
//
//  Created by Scott Little on 24/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//
//	Much of this code is based on pieces written by Scott Morrision (indev.ca)
//	Especially the Property swizzling stuff
//

#import "MCCSwizzle.h"
#import "MCCMailAbstractor.h"
#import <objc/objc-runtime.h>
typedef struct objc_super * super_pointer;


#ifndef MCC_CLASSNAME_SUFFIX_SEPARATOR
#define MCC_CLASSNAME_SUFFIX_SEPARATOR	@"_"
#endif

#ifndef MCC_CLASSNAME_PREFIX_APPENDOR
#define MCC_CLASSNAME_PREFIX_APPENDOR	@"_"
#endif


@interface MCC_PREFIXED_NAME(Swizzle) ()
+ (BOOL)addMethodName:(NSString *)methodName toClass:(Class)targetClass fromProviderClass:(Class)providerClass methodName:(NSString*)providerMethodName isClassMethod:(BOOL)isClassMethod;
+ (void)processMethods:(Method *)methods count:(NSInteger)countDecrementer passingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging isClassMethod:(BOOL)isClassMethod;
@end

#ifdef DEBUG
#define DEFAULT_DEBUGGING	1
#else
#define DEFAULT_DEBUGGING	0
#endif

@implementation MCC_PREFIXED_NAME(Swizzle)

#pragma mark - Main Entry Points

+ (Class)makeSubclassOf:(Class)baseClass {

	NSRange		separatorRange = [[self className] rangeOfString:MCC_CLASSNAME_SUFFIX_SEPARATOR];
	if (separatorRange.location == NSNotFound) {
		NSLog(@"Could not create subclass for %@ - it has no suffix", [self className]);
		return nil;
	}
	NSString	*subclassName = [[self className] substringToIndex:separatorRange.location];

	Class subclass = objc_allocateClassPair(baseClass, [subclassName UTF8String], 0);
	if (!subclass) return nil;
	
	//	Register the subclass
	objc_registerClassPair(subclass);
	
	[self addMethodsPassingTest:^MCC_PREFIXED_NAME(SwizzleType)(NSString *methodName) {
		return MCC_PREFIXED_NAME(SwizzleTypeAdd);
	} toClass:subclass usingPrefix:@"" withDebugging:DEFAULT_DEBUGGING];
	
	[self swizzlePropertiesToClass:subclass];
	
	if (NO) {
		
	}
	
	// add a forwardingInvocationMethod to catch 'super' calls
	Method forwardingMethod = class_getInstanceMethod(PREFIXED_CLS(Swizzle),@selector(MCC_PREFIXED_NAME(_MCCSwizzle_callRuntimeSuperWithInvocation):));
	class_addMethod(subclass, @selector(forwardInvocation:), method_getImplementation(forwardingMethod), method_getTypeEncoding(forwardingMethod));
	
	return subclass;

}

+ (void)swizzle {
	
	NSRange		separatorRange = [[self className] rangeOfString:MCC_CLASSNAME_SUFFIX_SEPARATOR];
	if (separatorRange.location == NSNotFound) {
		NSLog(@"Could not swizzle class %@ - it has no suffix", [self className]);
		return;
	}
	NSString	*targetClassName = [[self className] substringToIndex:separatorRange.location];
	NSString	*prefix = [NSString stringWithFormat:@"%@%@", [[self className] substringFromIndex:separatorRange.location + [MCC_CLASSNAME_SUFFIX_SEPARATOR length]], MCC_CLASSNAME_PREFIX_APPENDOR];

	Class	targetClass = MCC_PREFIXED_NAME(ClassFromString)(targetClassName);
	if (!targetClass) {
		NSLog(@"Class %@ was not found to swizzle", targetClassName);
		return;
	}
	
	[self addAllMethodsToClass:targetClass usingPrefix:prefix];
	
	[self swizzlePropertiesToClass:targetClass];
}

+ (void)addAllMethodsToClass:(Class)targetClass usingPrefix:(NSString*)prefix {
	[self addMethodsPassingTest:nil toClass:targetClass usingPrefix:prefix withDebugging:DEFAULT_DEBUGGING];
}

+ (void)addMethodsPassingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging {

	unsigned int	methodCount = 0;
	Method			*methods = nil;
	
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

#pragma mark - Super Calling Helpers

- (void)MCC_PREFIXED_NAME(_MCCSwizzle_callRuntimeSuperWithInvocation):(NSInvocation *)anInvocation {
	
#ifdef MCC_USE_EXPERIMENTAL_SUPER_OVERRIDE
    Class mySuper = class_getSuperclass([self class]);
    SEL mySel = [anInvocation selector];
    
    if ([mySuper instancesRespondToSelector:[anInvocation selector]] &&
        [[mySuper instanceMethodSignatureForSelector:mySel] isEqualTo: [anInvocation methodSignature]]){
        
        NSMethodSignature * signature = [anInvocation methodSignature];
        NSUInteger argCount = [signature numberOfArguments];
        
        // declare a buffer for the arguments
        uint64_t * argList = malloc([signature frameLength]); // a buffer for the arguments
        uint64_t * curArgPointer = argList; //
        uint64_t * arg = calloc(12,sizeof(uint64_t));
		
        for (NSUInteger argIndex = 0;argIndex<argCount;argIndex++){
            // get the type and size of the argment at the index
            const char *argType = [signature getArgumentTypeAtIndex:argIndex];
            NSUInteger typeSize;
            NSGetSizeAndAlignment(argType, &typeSize, NULL);
            
            // add the argument to the buffer
            [anInvocation getArgument:curArgPointer atIndex:argIndex];
			
            // store the pointer to the argument in the buffer of argumentPointers
            arg[argIndex]=*curArgPointer;
            
            
            // advance the curArgPointer by the size of the argment just entered
            curArgPointer+=typeSize;
		}
        
        void *returnValue=0;
        super_pointer  superPointer = &(struct objc_super){self, mySuper};
        returnValue =  (__bridge void *)(objc_msgSendSuper(superPointer, mySel ,arg[2],arg[3],arg[4],arg[5],arg[6],arg[7],arg[8],arg[9],arg[10],arg[11]));
        [anInvocation setReturnValue:&returnValue];
        free(argList);
        free(arg);
	}
#else
	NSAssert(NO, @"You called super on a method for a swizzled SUBCLASS (%@), which will most likely not do what you expect!!!", [self class]);
#endif
	
}

- (void)dealloc{
    // including this allows the runtime subclass to call
    // [super dealloc]
    // and have the dealloc message get passed to it runtime super
    //
    // Because runtime use of [super dealloc] will call the compiletime super (ie -[MAOSwizzle dealloc])
    // this method will be invoked.  all we need to do is send the message to the runtime super.
    //
    Class runtimeSuper = class_getSuperclass([self class]);
    if (runtimeSuper){
        super_pointer  sp = &(struct objc_super){self, runtimeSuper};
        objc_msgSendSuper(sp,  _cmd);
        return;
    }
#if __has_feature(objc_arc)
#else
    [super dealloc];  // kept in to avoid warning
#endif
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

#undef SWIZ_LOG

@end



#pragma mark - Property Swizzling

#define PROPERTY_KEY_PREFIX @"MCCProperty_"

@implementation MCC_PREFIXED_NAME(Swizzle) (Properties)

/*
 *
 * Method for adding the implemented Class's properties to the targetClass
 *
 */
+(void)swizzlePropertiesToClass:(Class)targetClass{
	
	NSDictionary * propertyDetailList = [self allPropertyDetails];
    
    [propertyDetailList enumerateKeysAndObjectsUsingBlock:^(id propertyName, NSDictionary* propertyDetails, BOOL *stop) {
        NSString * typeString = [propertyDetails objectForKey:@"type"];
        if (typeString) {
            const char typeChar =  [typeString characterAtIndex:0];
            [self synthesizePropertyMethods: propertyName
            						   type: typeChar
            				   retainPolicy: (objc_AssociationPolicy)[[propertyDetails objectForKey:@"retainPolicy"] unsignedLongValue]
            				        toClass: targetClass
								   readOnly: [[propertyDetails objectForKey:@"readOnly"] boolValue]
            				     getterName: [propertyDetails objectForKey:@"getterName"]
            				     setterName: [propertyDetails objectForKey:@"setterName"]];
        } // if typeString
    }];
}



+(NSMutableDictionary*)detailsForProperty:(objc_property_t) aProperty{
	// function will look up specific details about a property, returning in &propertyType, &ivarName and &details the details.
	// propertyType and ivarNames need be freed by the client function.
	
	// this function is optimized to loop through the details once
    NSMutableDictionary * details = [NSMutableDictionary dictionary];
    [details setObject: [NSString stringWithFormat:@"%s",property_getName(aProperty)] forKey:@"propertyName"] ;
    
    [details setObject:[NSNumber numberWithUnsignedLong:OBJC_ASSOCIATION_ASSIGN] forKey:@"retainPolicy"];
	const char * propAttribs = property_getAttributes(aProperty);
	// parse out attributes
    
	char **ap, *argv[10];
	
	char * mutableAttribs = malloc(strlen(propAttribs)+1);
	
	strcpy(mutableAttribs,propAttribs);
	char * freePoint = mutableAttribs;
	for (ap = argv; (*ap = strsep(&mutableAttribs, ",")) != NULL;) {
		if (**ap != '\0'){
			switch(**ap){
				case'T':
                    [details setObject:[NSString stringWithFormat:@"%s",(*ap)+1] forKey:@"type"];
					
					break;
				case 'V':
                    [details setObject:[NSString stringWithFormat:@"%s",(*ap)+1] forKey:@"ivarName"];
					break;
				case '&':
					[details setObject:[NSNumber numberWithUnsignedLong:OBJC_ASSOCIATION_RETAIN] forKey:@"retainPolicy"];
					break;
				case 'R':
                    [details setObject:@YES forKey:@"readOnly"];
					break;
				case 'D':
                    [details setObject:@YES forKey:@"dynamic"];
					break;
				case 'C':
                    [details setObject:[NSNumber numberWithUnsignedLong:OBJC_ASSOCIATION_COPY] forKey:@"retainPolicy"];
					break;
				case 'N':
                    [details setObject:@YES forKey:@"atomic"];
					break;
				case 'W':
                    [details setObject:@YES forKey:@"weakReference"];
					break;
				case 'P':
                    [details setObject:@YES forKey:@"garbageCollectable"];
					break;
                case 'G':
                    [details setObject:[NSString stringWithFormat:@"%s",(*ap)+1] forKey:@"getterName"];
					break;
                case 'S':
                    [details setObject:[NSString stringWithFormat:@"%s",(*ap)+1] forKey:@"getterName"];
					break;
			}
			if (++ap >= &argv[10]) break;
		}
		
	}
	
	//	Update the policy to reflect nonatomic, if needed.
	if (([details objectForKey:@"atomic"] == nil) || ![[details objectForKey:@"atomic"] boolValue]) {
		unsigned long policy = [[details objectForKey:@"retainPolicy"] unsignedLongValue];
		if (policy == OBJC_ASSOCIATION_RETAIN) {
			policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
		}
		else if (policy == OBJC_ASSOCIATION_COPY) {
			policy = OBJC_ASSOCIATION_COPY_NONATOMIC;
		}
		[details setObject:[NSNumber numberWithUnsignedLong:policy] forKey:@"retainPolicy"];
	}
	
	free(freePoint);
    return details;
}

// propertyDetails
// returns all the property details for the implemented swizzleClass
//

+(NSDictionary*)allPropertyDetails {
	
    unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(self, &outCount);
    NSMutableDictionary * propertyInfo = [NSMutableDictionary dictionaryWithCapacity:outCount];
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
		
        NSString * propertyName = [NSString stringWithFormat:@"%s",property_getName(property)];
        NSMutableDictionary * details = [self detailsForProperty:property];
        if (![details objectForKey:@"getterName"]){
            [details setObject:[@"" stringByAppendingString:propertyName] forKey:@"getterName"];
        }
        
        if (![[details objectForKey:@"readOnly"] boolValue]){
            if (![details objectForKey:@"setterName"]){
				NSString* setterName = [NSString stringWithFormat: @"set%@%@:",[[propertyName substringToIndex:1] uppercaseString],[propertyName substringWithRange:NSMakeRange(1,[propertyName length]-1)]];
                [details setObject:setterName forKey:@"setterName"];
            }
			
        }
        [propertyInfo setObject:details forKey:propertyName ];
		
		
    }
    free(properties);
    return propertyInfo;
}

/*
 *
 * creates all the instance methods for accessing the properties
 *
 */

+(void)synthesizePropertyMethods:(NSString*)propertyName
                            type:(char) typeChar
                    retainPolicy:(objc_AssociationPolicy) retainPolicy
                         toClass:(Class)targetClass
						readOnly: (BOOL)readOnly
                      getterName:(NSString*) getterName
                      setterName:(NSString*) setterName{
    // encodings found at https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html%23//apple_ref/doc/uid/TP40008048-CH100-SW1
	
	// prefixes all associatedObjectKeys with PROPERTY_KEY_PREFIX to avoid collisions
	
    SEL propertyNameKey = NSSelectorFromString([PROPERTY_KEY_PREFIX stringByAppendingString:propertyName]);
    
    if (!getterName){
        getterName = propertyName;
    }
    if (!setterName && !readOnly){
        setterName = [NSString stringWithFormat: @"set%@%@:",[[propertyName substringToIndex:1] uppercaseString],[propertyName substringWithRange:NSMakeRange(1,[propertyName length]-1)]];
    }
    
    // check to see if the method is already there...
    unsigned int methodCount = 0;
    Method * methodList = class_copyMethodList(targetClass, &methodCount);
    BOOL hasGetter = NO;
    BOOL hasSetter = NO;
    while (methodCount--){
        SEL existingMethodSelector=  method_getName(methodList[methodCount]);
        if ( existingMethodSelector == NSSelectorFromString(getterName))
			hasGetter= YES;
        if ((setterName != nil) && (existingMethodSelector == NSSelectorFromString(setterName)))
            hasSetter = YES;
    }
    free(methodList);
    if ((hasGetter&&hasSetter) || (hasGetter && readOnly)){
        return;
    }
    
    switch(typeChar){
        case '@': {  //NSObject
            if (!hasGetter){
                id (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
                    id result =  AUTORELEASE(RETAIN(objc_getAssociatedObject(_self,propertyNameKey)));
                    return result;
                });
                class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"@@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
                    void (*setter)(id, SEL, id) = (void*)imp_implementationWithBlock(^(id _self,id value){
                        [_self willChangeValueForKey: propertyName];
                        objc_setAssociatedObject(_self, propertyNameKey, value, retainPolicy);
                        [_self didChangeValueForKey: propertyName];
                    });
                    class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:@");
                }
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case '^': {  //dispatch object
            if (!hasGetter){
                id (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
                    id result =  objc_getAssociatedObject(_self,propertyNameKey);
                    return result;
                });
                class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"^@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
                    void (*setter)(id, SEL, id) = (void*)imp_implementationWithBlock(^(id _self,id value){
                        [_self willChangeValueForKey: propertyName];
                        objc_setAssociatedObject(_self, propertyNameKey, value, retainPolicy);
                        [_self didChangeValueForKey: propertyName];
                    });
                    class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:^");
                }
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'B': { // bool
            if (!hasGetter){
				bool (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) boolValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"B@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,bool value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithBool:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
						
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:B");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'd': {  //double
            if (!hasGetter){
				double (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) doubleValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"d@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,double value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithDouble:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:d");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'f': {  // float
            if (!hasGetter){
				float (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) floatValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"f@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,float value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithFloat:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:f");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'i': { // int
            if (!hasGetter){
				int (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) intValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"i@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,int value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithInt:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:i");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'I': { //unsigned int
            if (!hasGetter){
				unsigned int (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) unsignedIntValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"I@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, unsigned int value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithUnsignedInt:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:I");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'l': { // long
            if (!hasGetter){
				long (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) longValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"l@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,long value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithLong:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:l");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'L': { //unsigned long
            if (!hasGetter){
				unsigned long (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) unsignedLongValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"L@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, unsigned long value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithUnsignedLong:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:L");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'q': { //long long
            if (!hasGetter){
				long long (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) longLongValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"q@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, long long value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithLongLong:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:q");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'Q': { //unsigned long long
            if (!hasGetter){
				unsigned long long (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) unsignedLongLongValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"Q@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, unsigned long long value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithUnsignedLongLong:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:Q");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'c': { //char
            if (!hasGetter){
				char (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) charValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"c@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, char value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithChar:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:c");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'C': { //unsigned char
            if (!hasGetter){
				unsigned char (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) unsignedCharValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"C@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, unsigned char value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithUnsignedChar:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:C");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 's': { //short
            if (!hasGetter){
				float (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) shortValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"s@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,short value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithShort:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:s");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case 'S': { //unsigned short
            if (!hasGetter){
				unsigned short (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [objc_getAssociatedObject(_self,propertyNameKey) unsignedShortValue];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"S@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self, unsigned short value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSNumber numberWithUnsignedShort:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:S");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
            
        case '*': { //c-string  const char*
            if (!hasGetter){
				char* (*getter)(id, SEL) = (void*)imp_implementationWithBlock(^(id _self){
					return [(NSString*)objc_getAssociatedObject(_self,propertyNameKey) UTF8String];
				});
				class_addMethod(targetClass,NSSelectorFromString(getterName),(IMP)getter,"*@:");
            }
            else{
				// NSLog(@"-[%@ %@] exists",targetClass,getterName);
            }
            if (setterName){
                if (!hasSetter){
					void (*setter)(id, SEL, double) = (void*)imp_implementationWithBlock(^(id _self,char * value){
						[_self willChangeValueForKey: propertyName];
						objc_setAssociatedObject(_self,propertyNameKey,[NSString stringWithUTF8String:value],OBJC_ASSOCIATION_RETAIN);
						[_self didChangeValueForKey: propertyName];
					});
					class_addMethod(targetClass,NSSelectorFromString(setterName),(IMP)setter,"v@:*");
				}
                else{
                    //NSLog(@"-[%@ %@] exists",targetClass,setterName);
                }
            }
            break;
        }
        default : {
            NSLog(@"No encoding for typeString %c",typeChar);
        }
            
    }// switch
    
    
}
@end



