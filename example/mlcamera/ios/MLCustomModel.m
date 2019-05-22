//
//  MLCustomModel.m
//  mlcamera
//
//  Created by Gaspard Chevassus on 15/05/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_REMAP_MODULE(RNCustomModel, MLCustomModel, NSObject)

RCT_EXTERN_METHOD(
                  initModel
                  )

RCT_EXTERN_METHOD(
                  runModel: (NSString *) filePath
                  resolver: (RCTPromiseResolveBlock) resolve
                  rejecter: (RCTPromiseRejectBlock) reject
                  )

@end
