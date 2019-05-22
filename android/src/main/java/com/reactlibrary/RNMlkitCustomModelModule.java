
package com.reactlibrary;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.PriorityQueue;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.SystemClock;
import android.support.annotation.NonNull;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.ml.common.FirebaseMLException;
import com.google.firebase.ml.common.modeldownload.FirebaseLocalModel;
import com.google.firebase.ml.common.modeldownload.FirebaseModelDownloadConditions;
import com.google.firebase.ml.common.modeldownload.FirebaseModelManager;
import com.google.firebase.ml.common.modeldownload.FirebaseRemoteModel;
import com.google.firebase.ml.custom.FirebaseModelDataType;
import com.google.firebase.ml.custom.FirebaseModelInputOutputOptions;
import com.google.firebase.ml.custom.FirebaseModelInputs;
import com.google.firebase.ml.custom.FirebaseModelInterpreter;
import com.google.firebase.ml.custom.FirebaseModelOptions;
import com.google.firebase.ml.custom.FirebaseModelOutputs;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.AbstractMap;
import java.util.ArrayList;


import static com.facebook.react.views.textinput.ReactTextInputManager.TAG;

public class RNMlkitCustomModelModule extends ReactContextBaseJavaModule {


  /**
   * Name of the model file hosted with Firebase.
   */
  private static final boolean QUANT = false;
  private static final String HOSTED_MODEL_NAME = null;
  private static final String LOCAL_MODEL_ASSET = QUANT?"mobilenet_v1_1.0_224_quant.tflite": "mobilenet_v1_1.0_224.tflite";
  /**
   * Name of the label file stored in Assets.
   */
  private static final String LABEL_PATH = "mobilenet.txt";
  /**
   * Number of results to show in the UI.
   */
  private static final int RESULTS_TO_SHOW = 3;
  /**
   * Dimensions of inputs.
   */
  private static final int DIM_BATCH_SIZE = 1;
  private static final int DIM_PIXEL_SIZE = 3;
  private static final int DIM_IMG_SIZE_X = 224; //368;
  private static final int DIM_IMG_SIZE_Y = 224;//368;

  private List<String> mLabelList;

  private final PriorityQueue<Map.Entry<String, Float>> sortedLabels =
          new PriorityQueue<>(
                  RESULTS_TO_SHOW,
                  new Comparator<Map.Entry<String, Float>>() {
                    @Override
                    public int compare(Map.Entry<String, Float> o1,
                                       Map.Entry<String, Float> o2) {
                      return (o1.getValue()).compareTo(o2.getValue());
                    }
                  });

  /**
   * An instance of the driver class to run model inference with Firebase.
   */
  private FirebaseModelInterpreter mInterpreter;
  /**
   * Data configuration of input & output data of model.
   */
  private FirebaseModelInputOutputOptions mDataOptions;

  private final ReactApplicationContext reactContext;

  public RNMlkitCustomModelModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @ReactMethod
  public void initModel() {
    System.out.println("RNCustomModel is turn ON");
    mLabelList = loadLabelList(getCurrentActivity());

    int[] inputDims = {DIM_BATCH_SIZE, DIM_IMG_SIZE_X, DIM_IMG_SIZE_Y, DIM_PIXEL_SIZE};
    int[] outputDims = {DIM_BATCH_SIZE, mLabelList.size()};
//      int[] outputDims = {DIM_BATCH_SIZE, DIM_IMG_SIZE_X / 8, DIM_IMG_SIZE_Y / 8, 57};

    try {
      int firebaseModelDataType = QUANT? FirebaseModelDataType.BYTE:FirebaseModelDataType.FLOAT32;
      mDataOptions =
              new FirebaseModelInputOutputOptions.Builder()
                      .setInputFormat(0, firebaseModelDataType, inputDims)
                      .setOutputFormat(0, firebaseModelDataType, outputDims)
                      .build();

      if(HOSTED_MODEL_NAME != null){
        FirebaseModelDownloadConditions conditions = new FirebaseModelDownloadConditions
                .Builder()
                .requireWifi()
                .build();
        FirebaseRemoteModel cloudSource = new FirebaseRemoteModel.Builder
                (HOSTED_MODEL_NAME)
                .enableModelUpdates(true)
                .setInitialDownloadConditions(conditions)
                .setUpdatesDownloadConditions(conditions)  // You could also specify
                // different conditions
                // for updates
                .build();
      }

      FirebaseLocalModel localSource =
              new FirebaseLocalModel.Builder("asset") // Assign a name to this model
                      .setAssetFilePath(LOCAL_MODEL_ASSET).build();

      FirebaseModelManager manager = FirebaseModelManager.getInstance();
//            manager.registerCloudModelSource(cloudSource);
      manager.registerLocalModel(localSource);
      FirebaseModelOptions modelOptions =
              new FirebaseModelOptions.Builder()
//                            .setCloudModelName(HOSTED_MODEL_NAME)
                      .setLocalModelName("asset")
                      .build();
      mInterpreter = FirebaseModelInterpreter.getInstance(modelOptions);
      showToast("Model loaded");
    } catch (FirebaseMLException e) {
      showToast("Error while setting up the model");
      e.printStackTrace();
    }

  }

  @ReactMethod
  private void runModelInference(String uri, final Promise promise) throws FileNotFoundException {
    if (mInterpreter == null) {
      Log.e(TAG, "Image classifier has not been initialized; Skipped.");
      return;
    }
    // Create input data.
    ByteBuffer imgData = convertBitmapToByteBuffer(uri);

    try {
      FirebaseModelInputs inputs = new FirebaseModelInputs.Builder().add(imgData).build();
      // Here's where the magic happens!!
      mInterpreter
              .run(inputs, mDataOptions)
              .addOnFailureListener(new OnFailureListener() {
                @Override
                public void onFailure(@NonNull Exception e) {
                  e.printStackTrace();
                  showToast("Error running model inference");
                  promise.reject("Error running model inference");

                }
              })
              .continueWith(
                      new Continuation<FirebaseModelOutputs, WritableArray>() {
                        @Override
                        public WritableArray then(Task<FirebaseModelOutputs> task) {
                          WritableArray topLabels;
                          if(QUANT){
                            byte[][] labelProbArray = task.getResult()
                                    .<byte[][]>getOutput(0);
                            topLabels = getTopLabels(labelProbArray);


                          }
                          else {
                            float[][] labelProbArray = task.getResult()
                                    .<float[][]>getOutput(0);
                            topLabels = getTopLabels(labelProbArray);


                          }
//                          showToast(topLabels.toString(),  Toast.LENGTH_SHORT);
                          promise.resolve(topLabels);
                          return topLabels;

                        }
                      });
    } catch (FirebaseMLException e) {
      e.printStackTrace();
      showToast("Error running model inference");
      promise.reject("Error running model inference");
    }

  }


  /**
   * Gets the top labels in the results.
   */
  private synchronized WritableArray getTopLabels(byte[][] labelProbArray) {
    for (int i = 0; i < mLabelList.size(); ++i) {
      sortedLabels.add(
              new AbstractMap.SimpleEntry<>(mLabelList.get(i), (labelProbArray[0][i] & 0xff) / 255.0f));
      if (sortedLabels.size() > RESULTS_TO_SHOW) {
        sortedLabels.poll();
      }
    }
    WritableArray result = Arguments.createArray();
    final int size = sortedLabels.size();
    for (int i = 0; i < size; ++i) {
      Map.Entry<String, Float> label = sortedLabels.poll();
      result.pushString(label.getKey() + ":" + label.getValue());
    }
    Log.d(TAG, "labels: " + result.toString());
    return result;
  }

  private synchronized WritableArray getTopLabels(float[][] labelProbArray) {
    for (int i = 0; i < mLabelList.size(); ++i) {
      sortedLabels.add(
              new AbstractMap.SimpleEntry<>(mLabelList.get(i),labelProbArray[0][i]));
      if (sortedLabels.size() > RESULTS_TO_SHOW) {
        sortedLabels.poll();
      }
    }
    WritableArray result = Arguments.createArray();
    final int size = sortedLabels.size();
    for (int i = 0; i < size; ++i) {
      Map.Entry<String, Float> label = sortedLabels.poll();
      result.pushString(label.getKey() + ":" + label.getValue());
    }
    Log.d(TAG, "labels: " + result.toString());
    return result;
  }


  /**
   * Reads label list from Assets.
   */
  private List<String> loadLabelList(Activity activity) {
    List<String> labelList = new ArrayList<>();
    try (BufferedReader reader =
                 new BufferedReader(new InputStreamReader(activity.getAssets().open(LABEL_PATH)))) {
      String line;
      while ((line = reader.readLine()) != null) {
        labelList.add(line);
      }
    } catch (IOException e) {
      Log.e(TAG, "Failed to read label list.", e);
    }
    return labelList;
  }

  /**
   * Writes Image data into a {@code ByteBuffer}.
   */
  private synchronized ByteBuffer convertBitmapToByteBuffer(String path) throws FileNotFoundException {

    int bytesPerChannel = QUANT?1:4;

    InputStream inputStream = new FileInputStream(path.replace("file://",""));
    Bitmap bitmap = BitmapFactory.decodeStream(inputStream);

//        Matrix matrixR = new Matrix();
//        matrixR.postRotate(90.0f);
//        Bitmap bitmapRaw = Bitmap.createBitmap(bitmap, 0, 0,  bitmap.getWidth(),  bitmap.getHeight(), matrixR, true);


    ByteBuffer imgData =
            ByteBuffer.allocateDirect(bytesPerChannel * DIM_BATCH_SIZE * DIM_IMG_SIZE_X * DIM_IMG_SIZE_Y * DIM_PIXEL_SIZE);
    imgData.order(ByteOrder.nativeOrder());
    Bitmap scaledBitmap = Bitmap.createScaledBitmap(bitmap, DIM_IMG_SIZE_X, DIM_IMG_SIZE_Y,
            true);
    imgData.rewind();

    /* Preallocated buffers for storing image data. */
    int[] intValues = new int[DIM_IMG_SIZE_X * DIM_IMG_SIZE_Y];

    scaledBitmap.getPixels(intValues, 0, scaledBitmap.getWidth(), 0, 0,
            scaledBitmap.getWidth(), scaledBitmap.getHeight());
    // Convert the image to int points.
    long startTime = SystemClock.uptimeMillis();

    int pixel = 0;
    for (int i = 0; i < DIM_IMG_SIZE_X; ++i) {
      for (int j = 0; j < DIM_IMG_SIZE_Y; ++j) {
        final int val = intValues[pixel++];

        // Normalize the values according to the model used:
        // Quantized model expects a [0, 255] scale while a float model expects [0, 1].
        if(QUANT){
          imgData.put((byte) ((val >> 16) & 0xFF));
          imgData.put((byte) ((val >> 8) & 0xFF));
          imgData.put((byte) (val & 0xFF));
        }
        else{
          imgData.putFloat(((val >> 16) & 0xFF) / 255.0f);
          imgData.putFloat(((val >> 8) & 0xFF) / 255.0f);
          imgData.putFloat((val & 0xFF) / 255.0f);

//          imgData.putFloat(((val >> 16) & 0xFF) );
//          imgData.putFloat(((val >> 8) & 0xFF) );
//          imgData.putFloat((val & 0xFF));
        }

      }
    }
    long endTime = SystemClock.uptimeMillis();
    Log.d(TAG, "Timecost to put values into ByteBuffer: " + (endTime - startTime));
    return imgData;
  }

  private void showToast(String message) {
    Toast.makeText(getReactApplicationContext(), message, Toast.LENGTH_SHORT).show();
  }
  private void showToast(String message, int duration) {
    Toast.makeText(getReactApplicationContext(), message, duration).show();
  }


  @Override
  public String getName() {
    return "RNMlkitCustomModel";
  }
}