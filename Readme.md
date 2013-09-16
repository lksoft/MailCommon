# MailCommon Code

This is a collection of code that is reusable within Mail.app plugins that makes it easier to get the necessary work done without having to reinvent the wheel and also to avoid at least the basic problems between plugins.

## Avoiding Collisions

All of this code is meant to be used by more than one Mail.app plugin, so there is the question of namespace and collision of different versions if it is used by multiple plugins that are loaded at the same time. To avoid this issue and ensure that you are running the version that you _expect_ to be running, I have added a mechanism to prefix the code, without having to go through and change all of the names of the symbols. It seems to work pretty well.

There is one thing that you need to do in your project though to ensure that this works. Before every include of the files in this repository, you should create the following `#define`.

	#define	MCC_PLUGIN_PREFIX	<prefix>

Where **`<prefix>`** should be replaced with the prefix for your plugin. The best place to do this is at the top of your precompiled header. Then you can call functions, classes and methods defined in header files of this repository using that prefix. For instance the function defined in `MCCMailAbstractor.h` to replace `NSClassFromString`, is defined as `MCC_PREFIXED_NAME(ClassFromString)()`, but if your prefix is `MAO`, then you would just call `MAOClassFromString()` in all of your code. Makes the rest of your code easier and ensures that you won't collide with others.

**_Best Practice Note_**

Although most people have been using a 2 character class prefix code for a while, Apple actually recommends a **3** character prefix, which is why you'll notice that all code here and all examples use that practice. I recommend that you do the same.

This recommendation from Apple is made in the WWDC 2010 video [Application Frameworks, Session 130](http://developer.apple.com/videos/wwdc/2010/) - "Future Proofing your Application".

## MCCMailAbstractor

This exposes a single function, `<prefix>ClassFromString`, that you can use as a drop in replacement for `NSClassFromString`, that should always give you the relevant `Class` for the name you have passed in. The best practice is to always look for the pre-Mavericks class name and the correct one will be given to you for the system you are running on.

First it will just try to do a simple mapping by prepending the class name with either `'MF'` or `'MC'` to see if those classes are valid.

If the class is not found then it uses a lookup file to map any class you want to another class for a particular release of the OS (10.7, 10.8, 10.9 for example). The name of this file for general use is `MailVersionClassMappings.plist`. In addition, you can add a specific version for your plugin if you want named `PluginClassMappings.plist` if you have some special mapping requirements. Any mappings in this file will override those in the general file. See `MailVersionClassMappings.plist` for examples of the mappings, they should be fairly obvious.

## MCCSwizzle

This is a utility class from which you can do all of your swizzling and subclassing with easy methods to call simply from the +load method. It is also Collision-Safe using the same mechanism as `MCCMailAbstractor` above.

To do either class swizzling or subclassing, just create a new object that subclasses `MCC_PREFIXED_NAME(Swizzle)` and in its `+load` method call one of the methods listed below to do as you need and presto, you have a swizzled class. In general, methods just need to be defined as the name of the original method and they will swizzle the appropriate method in the original class. Best practice indicates that methods that are just added to the class should have some kind of uniqueness, so perhaps a prefix or suffix that ensures that it won't clash with some future method created by Apple. I actually, just try to insert something in the name of the method that is rather unique to my plugin, but that doesn't break the flow of the name, for instance, `-[Signature trulyAllSignaturesForSignatureProfiler]`. Looks better to me, but is still unique.

## Methods

### `+(void)swizzle` {#swizzle}

This method is the most common one to use and basically uses all of the others below to do its work. It will add all of the methods defined in the provider class to the swizzling class and then try to swizzle those that need swizzling (i.e. if the method already exists in the parent class. It will take the target class from the name of calling class before the defined separator (which is a single underscore [`_`] by default) in the name. For instance if your class is `Message_SIS`, it will use `Message` as the target to swizzle. And, of course, it will pass that through `MCC_PREFIXED_NAME(ClassFromString)()` to ensure that the right class is targeted for the running OS. The part after the separator (in our example `SIS`) will be used as the prefix for all swizzling. So inside of your methods, when you want to call the super, you call `[self SIS_originalMethodName]`. Note in that example the added underscore [`_`] after the prefix, which is also a default. Both the separator and prefix appendor (I know, that probably isn't a word, but I didn't want it to be _prefix suffix_) can be overridden on the project level. I wanted to try to override on the file level, but couldn't do it reasonably. Anyway, if you define the following in the `GCC_PREPROCESSOR_DEFINITIONS` build setting in the project, they will be used. **Please note that the quotes in the string literal need to be escaped.**

	MCC_CLASSNAME_SUFFIX_SEPARATOR=@\"__\"
	MCC_CLASSNAME_PREFIX_APPENDOR=@\"\"
	
In the example provided here, the defaults of the separator as `@"_"` and the appendor as `@""` are overridden to use two underscores `@"__"` as the separator with no appendor at all `@""`.

The `+swizzle` method will swizzle class & instance methods, obviously, and even provide implementations for properties defined, assuming that the accessors aren't already there. This last one is very cool stuff sent to me by Scott Morrison of [Indev Software](http://indev.ca).

**_Please Note_**

For the property swizzling to not break everything though, you need to add each property as `@dynamic propName;` inside your implementation unless you provide both methods. If you don't, **ALL** of the properties of the class that _you are swizzling_ can have undefined results! This is definitely an issue when building with Xcode 5 and may not be noticed in 4, but using `@dynamic` is a good idea, since you **are** providing the implementations after compile time.

### `+(void)addAllMethodsToClass:(Class)targetClass usingPrefix:(NSString *)prefix` {#add_all_methods}

This method does almost the same thing as `+swizzle`, except that it lets you control what the actual class and prefix used are independently of the provider class name, in case you need that. It does **NOT** add implementations for properties though, since the method name does not imply that. You can call the property swizzling method afterwards if needed, see [below](#swizzle_properties)

### `+(void)addMethodsPassingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging` {#add_methods_passing_test}

This verbose method gives even more control as to what gets swizzled and how. This is useful for supporting the different OS versions, as you can simply provide a block to tell the swizzler which methods to do for which OS. The two block types are defined as follows:

	typedef enum MCC_PREFIXED_NAME(SwizzleType) {
		MCC_PREFIXED_NAME(SwizzleTypeNone),
		MCC_PREFIXED_NAME(SwizzleTypeNormal),
		MCC_PREFIXED_NAME(SwizzleTypeAdd)
	} MCC_PREFIXED_NAME(SwizzleType);

	typedef MCC_PREFIXED_NAME(SwizzleType)(^MCC_PREFIXED_NAME(SwizzleFilterBlock))(NSString *methodName);

You simply give a block that tests a name and returns a swizzle type. The easiest way to describe this is with an example. In the following example, I am swizzling `MessageViewer` and adding some methods and swizzling one (`_setUpWindowContents`). In addition, I have a test to see if the `MessageViewingPane` class exists and if it does I swizzle one method and if not I swizzle a different one. Then in my test block I simply use the lists I made to decide if something should be swizzled and how.

	NSMutableArray	*addMethodList = [NSMutableArray array];
	NSMutableArray	*swizzleMethodList = [NSMutableArray array];
	
	//	Add the methods that should always be added
	[addMethodList addObject:@"adjustExpandingSplitViewFrameWithSISSidebarVisible:"];
	[addMethodList addObject:@"existingMessageViewerForSelectedMessage:"];
	[swizzleMethodList addObject:@"_setUpWindowContents"];
	[addMethodList addObject:@"sisSidebarVisibilityHasChanged:"];
	
	//	For Snow Leopard, swizzle the method for placing our view and the change selection method
	if (SISClassFromString(@"MessageViewingPane") == nil) {
		[swizzleMethodList addObject:@"selectedMessagesDidChange"];
	}
	else {
		[swizzleMethodList addObject:@"dealloc"];
	}
	
	//	Swizzle or add appropriately
	[self addMethodsPassingTest:^SISSwizzleType(NSString *methodName) {
		if ([addMethodList containsObject:methodName]) {
			return SISSwizzleTypeAdd;
		}
		else if ([swizzleMethodList containsObject:methodName]) {
			return SISSwizzleTypeNormal;
		}
		return SISSwizzleTypeNone;
	} toClass:SISClassFromString(@"MessageViewer") usingPrefix:MySwizzlePrefix withDebugging:YES];

### `+(Class)makeSubclassOf:(Class)baseClass` {#make_subclass_of}

This method is used to make a provider an actual subclass of another class. The name of the class to be added is the same as with `+swizzle`, so if your provider class name is `CoolClass_CCP` and assuming the default separator, then the subclass created would be named `CoolClass`. This will also add implementations for all defined properties automatically.

This method will also setup a `forwardInvocation:` method for the subclass created that with assert if you call `[super someMethodName]` inside the subclass directly. The reason for this is that you almost never really want that. The `super` of your subclass is always `MCC_PREFIXED_NAME(Swizzle)` and not the baseClass that you wanted to subclass. The exception to this is `dealloc` for which there is an implementation that **will** call the correct dealloc for you.

This `forwardInvocation:` however gives us the opportunity to do something experimental and potentially cool, but **it has not been tried in production code yet**! If you add a `GCC_PREPROCESSOR_DEFINITIONS` build setting for `MCC_USE_EXPERIMENTAL_SUPER_OVERRIDE` (it just needs to be defined, no specific value is required), then the `forwardInvocation:` will actually allow you to then use `[super someMethodName]` just as you would expect. Which makes for nice pretty code. **_HOWEVER_**, be forewarned that this is **EXPERIMENTAL** and certainly has not been optimized for any kind of method calls that will be happening a lot, so performance could suffer greatly. It could be great for classes that do not have a lot of instances and just have a couple of methods that call the super. Scott Morrison of [Indev Software](http://indev.ca) also provided this experimental piece of code.

In any case, you should probably use the macros `SUPER(…)` or `SUPER_SELECTOR(SEL, …)` in most cases to call to super from a subclass.

### `+(void)swizzlePropertiesToClass:(Class)targetClass`  {#swizzle_properties}

This method is called by the `+makeSubclassOf:` & `+swizzle` methods and you can call it independently as well. It finds all properties defined for the caller (the provider) and will create implementations for those methods in the `targetClass`, unless the implementations already exist, then it will leave those alone.

**_Please Note_**

For the property swizzling to not break everything though, you need to add each property as `@dynamic propName;` inside your implementation unless you provide both methods. If you don't, **ALL** of the properties of the class that _you are swizzling_ can have undefined results! This is definitely an issue when building with Xcode 5 and may not be noticed in 4, but using `@dynamic` is a good idea, since you **are** providing the implementations after compile time.

