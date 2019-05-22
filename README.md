
# rn-mlkit-custom-model


<p align="center">
  <img  src="https://user-images.githubusercontent.com/9252579/58023322-d2085c80-7b0f-11e9-83af-db2281047e5c.png">
</p>


MLKit Custom Model bridge for React-native running on iOS and Android.

Native code inspired from the Firebase documentation: https://firebase.google.com/docs/ml-kit/use-custom-models


The [example](example/mlcamera) provided uses react-native camera and mobilenet_v1_1.0_224.



		
## Getting started

`$ npm install rn-mlkit-custom-model --save`

### Mostly automatic installation

`$ react-native link rn-mlkit-custom-model`


### *Don't forget to ...*

- *add google-services.json to the appropriate folder (/android/app/) __(Android only)__*
- *add GoogleService-Info.plist to the appropriate folder (/ios/) __(iOS only)__*
- *install [CocoaPods](https://cocoapods.org/) in your react-native project and add the following line to your Podfile then run `pod install` __(iOS only)__*
   
	 ```
  	pod 'Firebase/Analytics'
  	pod 'Firebase/MLModelInterpreter'

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



## Usage
```javascript
import RNMlkitCustomModel from 'rn-mlkit-custom-model';

//init the model
RNMlkitCustomModel.initModel()

//run the model on the provided image
RNMlkitCustomModel.runModelInference(IMAGE_URI).then(results => {
	console.log(results)
})
```
  