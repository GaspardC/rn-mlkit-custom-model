
#import "RNMlkitCustomModel.h"
#import <React/RCTLog.h>

//@import Firebase;
//@import FirebaseMLCommon;
#import <Firebase/Firebase.h>
#import <FirebaseMLCommon/FirebaseMLCommon.h>


@implementation RNMlkitCustomModel {
   FIRModelInterpreter *interpreter;
   FIRModelInputOutputOptions *ioOptions;
}



- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(initModel)
{
    RCTLogInfo(@"initmodel");
    
    FIRModelDownloadConditions *initialConditions = [[FIRModelDownloadConditions alloc]
                                                     initWithAllowsCellularAccess:YES
                                                     allowsBackgroundDownloading:YES];
    FIRModelDownloadConditions *updateConditions = [[FIRModelDownloadConditions alloc]
                                                    initWithAllowsCellularAccess:NO
                                                    allowsBackgroundDownloading:YES];
    
    FIRRemoteModel *remoteModel = [[FIRRemoteModel alloc] initWithName:@"my_remote_model"
                                                    allowsModelUpdates:YES
                                                     initialConditions:initialConditions
                                                      updateConditions:updateConditions];
    [[FIRModelManager modelManager] registerRemoteModel:remoteModel];
    
    NSString *modelPath = [NSBundle.mainBundle pathForResource:@"mobilenet_v1_1.0_224"
                                                        ofType:@"tflite"];
    
    FIRLocalModel *localModel = [[FIRLocalModel alloc] initWithName:@"my_local_model"
                                                               path:modelPath];
    [[FIRModelManager modelManager] registerLocalModel:localModel];
    
    
    FIRModelOptions *options = [[FIRModelOptions alloc] initWithRemoteModelName:nil
                                                                 localModelName:@"my_local_model"];
    interpreter = [FIRModelInterpreter modelInterpreterWithOptions:options];
    
    ioOptions = [[FIRModelInputOutputOptions alloc] init];
    NSError *error;
    [ioOptions setInputFormatForIndex:0
                                 type:FIRModelElementTypeFloat32
                           dimensions:@[@1, @224, @224, @3]
                                error:&error];
    if (error != nil) { return; }
    [ioOptions setOutputFormatForIndex:0
                                  type:FIRModelElementTypeFloat32
                            dimensions:@[@1, @1001]
                                 error:&error];
    if (error != nil) { return; }
    
}



RCT_REMAP_METHOD(runModelInference, runModelInference:(NSString *)imagePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    
    @try {
    if (!imagePath) {
        resolve(@NO);
        return;
    }
    RCTLogInfo(@"path is , %@", imagePath);
    
    
    //allocate data
    NSData *imageNSData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]];

    UIImage *uiImage = [UIImage imageWithData:imageNSData];
    UIImage *scaledImage = [self scaleImage:uiImage toWidth:224 toHeight:224];
    

    CGImageRef image  = [scaledImage CGImage];
    long imageWidth = CGImageGetWidth(image);
    long imageHeight = CGImageGetHeight(image);
    CGContextRef context = CGBitmapContextCreate(nil,
                                                 imageWidth, imageHeight,
                                                 8,
                                                 imageWidth * 4,
                                                 CGColorSpaceCreateDeviceRGB(),
                                                 kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image);
    UInt8 *imageData = CGBitmapContextGetData(context);
    
    FIRModelInputs *inputs = [[FIRModelInputs alloc] init];
    NSMutableData *inputData = [[NSMutableData alloc] initWithCapacity:0];
    
    for (int row = 0; row < 224; row++) {
        for (int col = 0; col < 224; col++) {
            long offset = 4 * (col * imageWidth + row);
            // Normalize channel values to [0.0, 1.0]. This requirement varies
            // by model. For example, some models might require values to be
            // normalized to the range [-1.0, 1.0] instead, and others might
            // require fixed-point values or the original bytes.
            // (Ignore offset 0, the unused alpha channel)
            Float32 red = imageData[offset+1] / 255.0f;
            Float32 green = imageData[offset+2] / 255.0f;
            Float32 blue = imageData[offset+3] / 255.0f;
            
            [inputData appendBytes:&red length:sizeof(red)];
            [inputData appendBytes:&green length:sizeof(green)];
            [inputData appendBytes:&blue length:sizeof(blue)];
        }
    }
    
    [inputs addInput:inputData error:nil];
   
        
    [interpreter runWithInputs:inputs
                       options:ioOptions
                    completion:^(FIRModelOutputs * _Nullable outputs,
                                 NSError * _Nullable error) {
                        if (error != nil || outputs == nil) {
                            return;
                        }
                        // Process outputs
                        // Get first and only output of inference with a batch size of 1
                        NSError *outputError;
                        NSArray *probabilites = [outputs outputAtIndex:0 error:&outputError][0];
                        
                        NSError *labelReadError = nil;
                        NSString *labelPath = [NSBundle.mainBundle pathForResource:@"mobilenet_v1_1.0_224"
                                                                            ofType:@"txt"];
                        NSString *fileContents = [NSString stringWithContentsOfFile:labelPath
                                                                           encoding:NSUTF8StringEncoding
                                                                              error:&labelReadError];
                        if (labelReadError != nil || fileContents == NULL) { return; }
                        NSArray<NSString *> *labels = [fileContents componentsSeparatedByString:@"\n"];
                        for (int i = 0; i < labels.count; i++) {
                            NSString *label = labels[i];
                            NSNumber *probability = probabilites[i];
                            NSLog(@"%@: %f", label, probability.floatValue);
                        }
                        
                        NSMutableArray *results = ([self process:outputs topResultsCount:5 labels:labels]);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            resolve(results);
                        });
                        
                    }];
        
    }
        @catch (NSException *exception) {
            NSLog(@"%@", exception.reason);
        }
}


- (NSMutableArray *) process:(FIRModelOutputs *)outputs
topResultsCount:(int)topResultsCount labels:(NSArray<NSString *>*)labels
      {
    
    // Get the output for the first batch, since `dimensionBatchSize` is 1.
    NSError *error;
    NSArray <NSArray<NSNumber *> *>*outputArrayOfArrays = [outputs outputAtIndex:0 error:&error];
    if (error) {
        NSLog(@"Failed to process detection outputs with error: %@", error.localizedDescription);
    }
    
    // Get the first output from the array of output arrays.
    if(outputArrayOfArrays == nil || outputArrayOfArrays.firstObject == nil || ![outputArrayOfArrays.firstObject isKindOfClass:[NSArray class]] || outputArrayOfArrays.firstObject.firstObject == nil || ![outputArrayOfArrays.firstObject.firstObject isKindOfClass:[NSNumber class]]) {
        NSLog(@"%@", @"Failed to get the results array from output.");
    }
    
    NSArray<NSNumber *> *firstOutput = outputArrayOfArrays.firstObject;
    NSMutableArray<NSNumber *> *confidences = [[NSMutableArray alloc] initWithCapacity:firstOutput.count];
    
    
    
    // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
    NSMutableArray *zippedResults = [[NSMutableArray alloc] initWithCapacity:firstOutput.count];
    for (int i = 0; i < firstOutput.count; i++) {
        [zippedResults addObject:@[
                                   [NSNumber numberWithInt:i],
                                   firstOutput[i],
                                   ]];
    }
    
    // Sort the zipped results by confidence value in descending order.
    [zippedResults sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        float confidenceValue1 = ((NSNumber *)((NSArray *)obj1)[1]).floatValue;
        float confidenceValue2 = ((NSNumber *)((NSArray *)obj2)[1]).floatValue;
        return confidenceValue1 < confidenceValue2;
    }];
    
    // Resize the sorted results array to match the `topResultsCount`.
    NSArray<NSArray *> *sortedResults =[zippedResults subarrayWithRange:NSMakeRange(0, topResultsCount)];
    
    // Create an array of tuples with the results as [(label: String, confidence: Float)].
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:topResultsCount];
    for (NSArray *sortedResult in sortedResults) {
        int labelIndex = ((NSNumber *)sortedResult[0]).intValue;
        NSString *res = [labels[labelIndex] stringByAppendingString: @" "];
//        NSNumber* a = sortedResult[1];
        res = [res stringByAppendingString:  [NSString stringWithFormat:@"%@", sortedResult[1]] ];
        [results addObject: res];
    }
    return results;
}



- (UIImage *) scaleImage:(UIImage*)image toWidth:(NSInteger)width toHeight:(NSInteger)height
{
    //  width /= [UIScreen mainScreen].scale; // prevents image from being incorrectly resized on retina displays
    //  float scaleRatio = (float) width / (float) image.size.width;
    CGSize size = CGSizeMake(width, height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [UIImage imageWithCGImage:[newImage CGImage]  scale:1.0 orientation:(newImage.imageOrientation)];
}
RCT_EXPORT_MODULE()

@end

