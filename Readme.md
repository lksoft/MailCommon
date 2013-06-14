# LKSMailCommon

This is just a good place for me to collect pieces of code or classes that I want to use in more than one Mail plugin. If you find them useful, that is great.

## Avoiding Collisions

All of this code is meant to be used by more than one Mail plugin, so there is the question of namespace and collision of different versions if it is used by multiple plugins that are loaded at the same time. To avoid this issue and ensure that you are running the version that you _expect_ to be running, I have added a mechanism to prefix the code, without having to go through and change all of the names of the symbols. It seems to work pretty well.

There is one thing that you need to do in your project though to ensure that this works. Before every include of the files in this repository, you should define the following define.

	#define	LKS_PREFIXED_NAME(function)	_LKS_PREFIXED_NAME(<prefix>, function)

Where **`<prefix>`** should be replaced with the prefix for your plugin. The best place to do this is at the top of your precompiled header. Then you can call functions, classes and methods defined in header files of this repository using that prefix. For instance the function defined in `LKSMailAbstractor.h` to replace `NSClassFromString`, is defined as `LKS_PREFIXED_NAME(ClassFromString)()`, but if your prefix is `MAO`, then you would just call `MAOClassFromString()`. Makes the rest of your code easier and ensures that you won't collide with others.

## LKSMailAbstractor

This exposes a single function, `<prefix>ClassFromString`, that you can use as a drop in replacement for `NSClassFromString`, that should always give you the relevant `Class` for the name you have passed in. The best practice is to always look for the pre-Mavericks class name and the correct one will be given to you for the system you are running on.

Behind the scenes there is a lookup file that can be used to map any class you want to another class for a particular release of the OS (10.7, 10.8, 10.9 for example). Before that it will just try to do a simple mapping by prepending the class name with either `'MF'` or `'MC'` to see if those classes are valid.
