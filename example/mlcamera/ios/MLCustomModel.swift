//
//  MLCustomModel.swift
//  mlcamera
//
//  Created by Gaspard Chevassus on 15/05/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation
import Firebase
import FirebaseMLCommon
import UIKit

@objc(MLCustomModel)
class MLCustomModel: NSObject {
  
  var interpreter: ModelInterpreter? = nil
  var ioOptions: ModelInputOutputOptions? = nil

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  @objc
  func constantsToExport() -> [AnyHashable : Any]! {
    return ["initialCount": 0]
  }
  
  @objc
  func initModel() -> Void {
    guard let modelPath = Bundle.main.path(forResource: "mobilenet_v1_1.0_224", ofType: "tflite")
      else {
        // Invalid model path
        return
    }
    let localModel = LocalModel(name: "my_local_model", path: modelPath)
    ModelManager.modelManager().register(localModel)
    
    let options = ModelOptions(
      remoteModelName: nil,
      localModelName: "my_local_model")
     self.interpreter = ModelInterpreter.modelInterpreter(options: options)
    
    
    self.ioOptions = ModelInputOutputOptions()
    do {
      try self.ioOptions?.setInputFormat(index: 0, type: .float32, dimensions: [1, 224, 224, 3])
      try self.ioOptions?.setOutputFormat(index: 0, type: .float32, dimensions: [1, 1001])
    } catch let error as NSError {
      return print("Failed to set input or output format with error: \(error.localizedDescription)")
    }
    print("init model successfully")
  }
  
  func createInputData(filePath: String) -> ModelInputs? {
    
    let url = NSURL(string: filePath)
    let data = NSData(contentsOf: url! as URL)
    let uiimageLarge = UIImage(data: data! as Data)!
    let uiimage = resizeImage(image: uiimageLarge, newWidth: 224)
    
    let image: CGImage = (uiimage.cgImage)! // Your input image
    guard let context = CGContext(
      data: nil,
      width: image.width, height: image.height,
      bitsPerComponent: 8, bytesPerRow: image.width * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
      ) else {
        return nil
    }
    
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    guard let imageData = context.data else { return nil  }
    
    let inputs = ModelInputs()
    var inputData = Data()
    do {
      for row in 0 ..< 224 {
        for col in 0 ..< 224 {
          let offset = 4 * (col * context.width + row)
          // (Ignore offset 0, the unused alpha channel)
          let red = imageData.load(fromByteOffset: offset+1, as: UInt8.self)
          let green = imageData.load(fromByteOffset: offset+2, as: UInt8.self)
          let blue = imageData.load(fromByteOffset: offset+3, as: UInt8.self)
          
          // Normalize channel values to [0.0, 1.0]. This requirement varies
          // by model. For example, some models might require values to be
          // normalized to the range [-1.0, 1.0] instead, and others might
          // require fixed-point values or the original bytes.
          var normalizedRed = Float32(red) / 255.0
          var normalizedGreen = Float32(green) / 255.0
          var normalizedBlue = Float32(blue) / 255.0
          
          // Append normalized values to Data object in RGB order.
          let elementSize = MemoryLayout.size(ofValue: normalizedRed)
          var bytes = [UInt8](repeating: 0, count: elementSize)
          memcpy(&bytes, &normalizedRed, elementSize)
          inputData.append(&bytes, count: elementSize)
          memcpy(&bytes, &normalizedGreen, elementSize)
          inputData.append(&bytes, count: elementSize)
          memcpy(&bytes, &normalizedBlue, elementSize)
          inputData.append(&bytes, count: elementSize)
        }
      }
      try inputs.addInput(inputData)
    } catch let error {
//      reject("Error", "Error to add input", error)
      print("Failed to add input: \(error)")
    }
    return inputs
  }
  
  @objc
  func runModel(_ filePath: String,
                 resolver resolve:  @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void  {
    
  
    guard let inputs = createInputData(filePath:filePath ) else { return reject("error input data", "cannot init input data", nil) }
    
    
    self.interpreter!.run(inputs: inputs, options: self.ioOptions!) { outputs, error in
      guard error == nil, let outputs = outputs else { return }
      // Process outputs
      // ...
      // Get first and only output of inference with a batch size of 1
      let output = try? outputs.output(index: 0) as? [[NSNumber]]
      let probabilities: [NSNumber] = (output?[0])!
      
      guard let labelPath = Bundle.main.path(forResource: "mobilenet_v1_1.0_224", ofType: "txt") else { return }
      let fileContents = try? String(contentsOfFile: labelPath)
      guard let labels = fileContents?.components(separatedBy: "\n") else { return }
      
      
      for i in 0 ..< labels.count {
          let probability = probabilities[i]
          print("\(labels[i]): \(probability)")
      }
      
      let topResultsCount = 3;
      // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
      let zippedResults = zip(labels.indices, probabilities)
      
      // Sort the zipped results by confidence value in descending order.
      let sortedResults = zippedResults.sorted { $0.1.floatValue > $1.1.floatValue }.prefix(topResultsCount)
      
      // Create an array of tuples with the results as [(label: String, confidence: Float)].
      let results =  sortedResults.map {(arg) -> String in let (a, b) = arg; return (labels[a] + " " + b.stringValue) }
      
//      let resultsDict = Dictionary(uniqueKeysWithValues: results)
      resolve(results)
    }
  }
  
  func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
//    let scale = newWidth / image.size.width
    let newHeight = newWidth
    UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
    image.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return newImage
  }
  
}
