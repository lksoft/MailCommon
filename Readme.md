# MailCommon Code

This is just a good place for me to collect pieces of code or classes that I want to use in more than one Mail plugin. If you find them useful, that is great.

## Avoiding Collisions

All of this code is meant to be used by more than one Mail plugin, so there is the question of namespace and collision of different versions if it is used by multiple plugins that are loaded at the same time. To avoid this issue and ensure that you are running the version that you _expect_ to be running, I have added a mechanism to prefix the code, without having to go through and change all of the names of the symbols. It seems to work pretty well.

There is one thing that you need to do in your project though to ensure that this works. Before every include of the files in this repository, you should define the following define.

	#define	MCC_PLUGIN_PREFIX	<prefix>

Where **`<prefix>`** should be replaced with the prefix for your plugin. The best place to do this is at the top of your precompiled header. Then you can call functions, classes and methods defined in header files of this repository using that prefix. For instance the function defined in `MCCMailAbstractor.h` to replace `NSClassFromString`, is defined as `MCC_PREFIXED_NAME(ClassFromString)()`, but if your prefix is `MAO`, then you would just call `MAOClassFromString()`. Makes the rest of your code easier and ensures that you won't collide with others.

## MCCMailAbstractor

This exposes a single function, `<prefix>ClassFromString`, that you can use as a drop in replacement for `NSClassFromString`, that should always give you the relevant `Class` for the name you have passed in. The best practice is to always look for the pre-Mavericks class name and the correct one will be given to you for the system you are running on.

First it will just try to do a simple mapping by prepending the class name with either `'MF'` or `'MC'` to see if those classes are valid.

If the class is not found then it uses a lookup file to map any class you want to another class for a particular release of the OS (10.7, 10.8, 10.9 for example). The name of this file for general use is `MailVersionClassMappings.plist`. In addition, you can add a specific version for your plugin if you want named `PluginClassMappings.plist` if you have some special mapping requirements. Any mappings in this file will override those in the general file. See `MailVersionClassMappings.plist` for examples of the mappings, they should be fairly obvious.

## MCCSwizzle

This is a utility class from which you can do all of your swizzling and subclassing with easy methods to call simply from the +load method. It is also Collision-Safe using the same mechanism as `MCCMailAbstractor` above.

To do either class swizzling or subclassing, just create a new object that subclasses `MCC_PREFIXED_NAME(Swizzle)` and in its `+load` method call one of the methods listed below to do as you need and presto, you have a swizzled class. In general, methods just need to be defined as the name of the original method and they will swizzle the appropriate method in the original class. Best practice indicates that methods that are just added to the class should have some kind of uniqueness, so perhaps a prefix or suffix that ensures that it won't clash with some future method created by Apple. I actually, just try to insert something in the name of the method that is rather unique to my plugin, but that doesn't break the flow of the name, for instance, `-[Signature trulyAllSignaturesForSignatureProfiler]`. Looks better to me, but is still unique.

### Methods

#### `+(void)swizzle` {#swizzle}

This method is the most common one to use and basically uses all of the others below to do its work. It will add all of the methods defined to the class and then try to swizzle those that need swizzling (i.e. if the method already exists in the parent class. It will take the target class from the name of calling class before an underscore in the name. For instance if your class is `Message_SIS`, it will use `Message` as the target to swizzle. And, of course, it will pass that through `MCC_PREFIXED_NAME(ClassFromString)()` to ensure that the right class is targeted for the running OS. The part after the underscore (in our example `SIS`) will be used as the prefix for all swizzling. So inside of your methods, when you want to call the super, you call `[self SISoriginalMethodName]`.

The `+swizzle` method will swizzle class & instance methods, obviously, and even provide implementations for properties defined, assuming that the accessors aren't already there. This last one is very cool stuff sent to me by Scott Morrison of [Indev Software](http://indev.ca).

**_Please Note_**

For the property swizzling to not break everything though, you need to add each property as `@dynamic propName;` inside your implementation unless you provide both methods. If you don't **ALL** of the properties of the class that _you are swizzling_ can have undefined results!

#### `+(void)addAllMethodsToClass:(Class)targetClass usingPrefix:(NSString *)prefix` {#addAllMethods}

This method does almost the same thing as `+swizzle`, except that it lets you control what the actual class and prefix used are independently of the provider class name, in case you need that. It does **NOT** add implementations for properties though, since the method name does not imply that. You can call the property swizzling method afterwards if needed, see [below](#propertySwizzle)

#### `+(void)addMethodsPassingTest:(MCC_PREFIXED_NAME(SwizzleFilterBlock))testBlock ivarsPassingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))ivarTestBlock toClass:(Class)targetClass usingPrefix:(NSString*)prefix withDebugging:(BOOL)debugging`

This verbose method gives even more control as to what gets swizzled and how. This is useful for supporting the different OS versions, as you can simply provide a block to tell the swizzler which methods to do for which OS. The two block types are defined as follows:

	typedef enum MCC_PREFIXED_NAME(SwizzleType) {
		MCC_PREFIXED_NAME(SwizzleTypeNone),
		MCC_PREFIXED_NAME(SwizzleTypeNormal),
		MCC_PREFIXED_NAME(SwizzleTypeAdd)
	} MCC_PREFIXED_NAME(SwizzleType);

	typedef MCC_PREFIXED_NAME(SwizzleType)(^MCC_PREFIXED_NAME(SwizzleFilterBlock))(NSString *methodName);
	typedef BOOL(^MCC_PREFIXED_NAME(AddIvarFilterBlock))(NSString *ivarName);

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
	} ivarsPassingTest:nil toClass:SISClassFromString(@"MessageViewer") usingPrefix:MySwizzlePrefix withDebugging:YES];

The `ivarsPassingTest:` part functions the same way, just with iVar names. If the block is nil then no iVars will be added to the class, which is different than the `methodsPassingTest:` part, which will swizzle methods that are found in the target class and add all of the others.

#### `+(Class)makeSubclassOf:(Class)baseClass usingClassName:(NSString *)subclassName` & </br>`+(Class)makeSubclassOf:(Class)baseClass usingClassName:(NSString*)subclassName addIvarsPassingTest:(MCC_PREFIXED_NAME(AddIvarFilterBlock))testBlock`

These two methods are used to make a provider an actual subclass of another class, using the name that you provide. The second variation will add any iVars to the subclass that is created. Note that the behavior of these two is different than `+swizzle` in that if the ivar block is nil then **all** iVars will be added automatically. These will also add implementations for all defined properties automatically.

#### `+(void)swizzlePropertiesToClass:(Class)targetClass`

This method is called by the `+makeSubclassOf` & `+swizzle` methods and you can call it independently as well. It finds all properties defined for the caller (the provider) and will create implementations for those methods in the `targetClass`, unless the implementations already exist, then it will leave those alone.
