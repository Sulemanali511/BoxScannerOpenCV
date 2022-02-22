//
//  CVWrapper.h
//  OpenCVSwiftLineDetection
//
//  Created by Pieter Meiresone on 09/10/2020.
//  Copyright © 2020 Pieter Meiresone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "imageReturnModel.h"
NS_ASSUME_NONNULL_BEGIN
@interface OpenCVWrapper : NSObject

+ (imageReturnModel*) processImageWithOpenCV: (UIImage*) inputImage;
+(UIImage*) drawRectangle:(CGRect)rect :(UIImage*)inputImage;
+(UIImage*) perspectiveCorrection:(CGPoint)ocvPIn1  :(CGPoint)ocvPIn2  :(CGPoint)ocvPIn3 :(CGPoint)ocvPIn4 :(UIImage*)image;
@end
NS_ASSUME_NONNULL_END
