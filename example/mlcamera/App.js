import React, { Component } from "react";
import { Text, TouchableOpacity, View, ImageEditor, Platform } from "react-native";

import styles from "./styles";
import { RNCamera } from "react-native-camera";
import RNMlkitCustomModel  from "rn-mlkit-custom-model";
import RNCustomModel from "./RNCustomModel.js";

export default class App extends Component {
  state = {
    results: null
  };
  componentDidMount() {
    // RNCustomModel.initModel();
    RNMlkitCustomModel.initModel()
  }

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.containerCamera}>
          <RNCamera
            ref={ref => {
              this.camera = ref;
            }}
            style={styles.preview}
            type={RNCamera.Constants.Type.back}
            flashMode={RNCamera.Constants.FlashMode.off}
            androidCameraPermissionOptions={{
              title: "Permission to use camera",
              message: "We need your permission to use your camera",
              buttonPositive: "Ok",
              buttonNegative: "Cancel"
            }}
            androidRecordAudioPermissionOptions={{
              title: "Permission to use audio recording",
              message: "We need your permission to use your audio",
              buttonPositive: "Ok",
              buttonNegative: "Cancel"
            }}
            onGoogleVisionBarcodesDetected={({ barcodes }) => {
              console.log(barcodes);
            }}
          />
        </View>

        <View style={styles.center}>
          <TouchableOpacity
            onPress={this.takePicture.bind(this)}
            style={styles.capture}
          >
            <Text style={{ fontSize: 14 }}> SNAP </Text>
          </TouchableOpacity>
        </View>
        <View style={styles.center}>{this.renderResults()}</View>
      </View>
    );
  }

  renderResults = () => {
    const res = this.state.results;
    if (res) {
      return <Text>{'last results :\n'}{res.map(r => <Text key={r}>{r + '\n'}</Text>)}</Text>;
    }
    return <Text>no results yet</Text>;
  };

  
  takePicture = async function() {
    if (this.camera) {
      const options = {
        quality: 1.0,
        base64: false,
        fixOrientation: true,
        forceUpOrientation: true
      };
      const data = await this.camera.takePictureAsync(options);
      console.log(data.uri);
      // RnMlCustom.initModel(data.uri)
      const squaredUri = Platform.OS === 'ios'?data.uri: await getCroppedImage(
        data.uri,
        data.width,
        data.height
      );
      // RNCustomModel.runModel(squaredUri).then(results => {
      //  this.setState({results})
      // });
      RNMlkitCustomModel.runModelInference(squaredUri).then(results => {
       this.setState({results})
    })

    }
  };
}

const getCroppedImage = async (uri, width, height) => {
  return new Promise((resolve, reject) => {
    ImageEditor.cropImage(
      uri,
      {
        offset: { x: 0, y: (height - width) / 2 },
        size: { width, height: width }
      },
      newUri => resolve(newUri),
      error => reject(error)
    );
  });
};
