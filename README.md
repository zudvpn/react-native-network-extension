
# react-native-network-extension

## Getting started

`$ npm install react-native-network-extension --save`

### Mostly automatic installation

`$ react-native link react-native-network-extension`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-network-extension` and add `RNNetworkExtension.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNNetworkExtension.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNNetworkExtensionPackage;` to the imports at the top of the file
  - Add `new RNNetworkExtensionPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-network-extension'
  	project(':react-native-network-extension').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-network-extension/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-network-extension')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNNetworkExtension.sln` in `node_modules/react-native-network-extension/windows/RNNetworkExtension.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Network.Extension.RNNetworkExtension;` to the usings at the top of the file
  - Add `new RNNetworkExtensionPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Setup `AppDelegate.m`
	#import "AppDelegate.h"

	// Other imports...

	#import <RNNetworkExtension/RNNetworkExtension.h>

	@implementation AppDelegate

	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
		// Other codes...
		[RNNetworkExtension bootstrap];
	
		return YES;
	}

## Usage
```javascript
import RNNetworkExtension from 'react-native-network-extension';

// TODO: What to do with the module?
RNNetworkExtension;
```
  