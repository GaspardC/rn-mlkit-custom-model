# DO NOT USE IT / IN DEVELOPMENT




# rn-mlkit-custom-model

## Getting started

`$ npm install rn-mlkit-custom-model --save`

### Mostly automatic installation

`$ react-native link rn-mlkit-custom-model`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `rn-mlkit-custom-model` and add `RNMlkitCustomModel.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNMlkitCustomModel.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNMlkitCustomModelPackage;` to the imports at the top of the file
  - Add `new RNMlkitCustomModelPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':rn-mlkit-custom-model'
  	project(':rn-mlkit-custom-model').projectDir = new File(rootProject.projectDir, 	'../node_modules/rn-mlkit-custom-model/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':rn-mlkit-custom-model')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNMlkitCustomModel.sln` in `node_modules/rn-mlkit-custom-model/windows/RNMlkitCustomModel.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Mlkit.Custom.Model.RNMlkitCustomModel;` to the usings at the top of the file
  - Add `new RNMlkitCustomModelPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNMlkitCustomModel from 'rn-mlkit-custom-model';

// TODO: What to do with the module?
RNMlkitCustomModel;
```
  