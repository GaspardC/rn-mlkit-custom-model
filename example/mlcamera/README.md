# react-native-mlkit-custom-models-starter


<p align="center">
  <img  src="https://user-images.githubusercontent.com/9252579/58023322-d2085c80-7b0f-11e9-83af-db2281047e5c.png">
</p>



Starter to run MLKit custom model on Android / iOS with React Native.
The starter is using a mobilenet_v1_1.0_224.tflite. You can use the quant or normal version.


Don't forget to ...*
- *add google-services.json to the appropriate folder (/android/app/) __(Android only)__*
- *add GoogleService-Info.plist to the appropriate folder (/ios/) __(iOS only)__*
- *install [CocoaPods](https://cocoapods.org/) in your react-native project and add the following line to your Podfile then run `pod install` __(iOS only)__*
   
	 ```
  	pod 'Firebase/Analytics'
  	pod 'Firebase/MLModelInterpreter'

    pod 'react-native-image-editor', :path => '../node_modules/@react-native-community/image-editor'

More instruction on how to setup Firebase on iOS / Android - requiered to run the project: 

https://firebase.google.com/docs/ios/setup.

https://firebase.google.com/docs/android/setup.


The starter is using [react-native-camera](https://github.com/react-native-community/react-native-camera) and [rn-mlkit-custom-model](https://github.com/GaspardC/rn-mlkit-custom-model).
