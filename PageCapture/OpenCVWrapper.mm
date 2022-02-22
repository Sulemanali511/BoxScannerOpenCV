//
//  CVWrapper.mm
//  OpenCVSwiftLineDetection
//
//  Created by Pieter Meiresone on 09/10/2020.
//  Copyright © 2020 Pieter Meiresone. All rights reserved.
//
#ifdef __cplusplus
#   include <opencv2/opencv.hpp>
#   include <opencv2/imgproc.hpp>
//#   include <opencv2/stitching/detail/blenders.hpp>
//#   include <opencv2/stitching/detail/exposure_compensate.hpp>
#endif
#import "OpenCVWrapper.h"
#import "UIImage+OpenCV.h"
#import "UIImage+Rotate.h"



@implementation OpenCVWrapper

+ (imageReturnModel*) processImageWithOpenCV: (UIImage*) inputImage
{
    
        cv::Mat srcBitMap = [inputImage CVMat];
        
        cv::Mat imgSource = [inputImage CVMat];
        cv::Mat matCopy = srcBitMap.clone();
    cv::Mat matCopyNS = srcBitMap.clone();
        cv::cvtColor(srcBitMap, imgSource, cv::COLOR_RGB2GRAY, 4);
        cv::GaussianBlur(imgSource, imgSource, cv::Size(5.0, 5.0), 0.0);
        cv::Canny(imgSource, imgSource, 60.0, 50.0);
        // NSArray *contours   = [[NSArray alloc] init][[NSArray alloc] init];
        std::vector<std::vector<cv::Point> > contours;
        cv::findContours(imgSource, contours,matCopyNS, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
        cv::cvtColor(imgSource, srcBitMap, cv::COLOR_GRAY2RGB, 4);
        double maxArea = (inputImage.size.width * 1.4 ) ;
        cv::Mat approxCurve = cv::Mat();
    
        for( int i = 0; i< contours.size(); i++ )
        {
            
            std::vector<cv::Point_<int>> contour =  contours[i];
            double contourarea = cv::contourArea( contour);
            if (contourarea > 0
                && contourarea > maxArea
                ) {
                NSLog(@"getLargestContour: contourarea: %f",contourarea);
                
                //check if this contour is a square
                
                
                cv::Mat new_mat = cv::Mat(contour);
                size_t contourSize = contour.size();
                cv::Mat approxCurve_temp = cv::Mat();
                cv::approxPolyDP(new_mat, approxCurve_temp, contourSize * 0.1, true);
                cv::approxPolyDP(new_mat, approxCurve_temp, contourSize * 0.1, true);
                //                Imgproc.approxPolyDP(new_mat, approxCurve_temp, contourSize * 0.05, true)
                if (approxCurve_temp.total() == 4L) {
                    double maxCosine = 0.0;
                    
                    std::vector<cv::Point> array;
                    if (approxCurve_temp.isContinuous()) {
                        // array.assign((float*)mat.datastart, (float*)mat.dataend); // <- has problems for sub-matrix like mat = big_mat.row(i)
                        array.assign((cv::Point*)approxCurve_temp.data, (cv::Point*)approxCurve_temp.data + approxCurve_temp.total()*approxCurve_temp.channels());
                    } else {
                        for (int i = 0; i < approxCurve_temp.rows; ++i) {
                            array.insert(array.end(), approxCurve_temp.ptr<cv::Point>(i), approxCurve_temp.ptr<cv::Point>(i)+approxCurve_temp.cols*approxCurve_temp.channels());
                        }
                    }
                    
                    for (int j=2;j<=4;j++) {
                        // find the maximum cosine of the angle between joint edges
                        
                        double cosine = abs([OpenCVWrapper angle:array[j % 4] :array[j - 2] :array[j - 1]]);
                        
                        
                        maxCosine = fmax(maxCosine, cosine);
                    }
                    if (maxCosine < 0.3) {
                        
                        approxCurve = approxCurve_temp;
                        
                    }
                }
            }
        }
        
        cv::Mat points = cv::Mat(approxCurve);
        

            cv::Rect  rect = cv::boundingRect(points);
    

       //        drawRectangle(rect,matCopy)
       //                    Utils.matToBitmap(srcMat,srcBitmap)
        [UIImage imageWithCVMat:srcBitMap];
              

             
    bool isSquare = false;
    if (rect.height > 0)
        isSquare = true;
    imageReturnModel * box = [[imageReturnModel alloc] init];
    box.isSquare = isSquare;
    CGRect newrect = CGRectMake(rect.x, rect.y, rect.width, rect.height);
    box.rect = newrect;
    return box;
}


+(UIImage*) drawRectangle:(CGRect)rect :(UIImage*)inputImage
{

        cv::Mat mat = [inputImage CVMat];
    cv::Point p1 = cv::Point(rect.origin.x,rect.origin.y);
//    rect!!.x.toDouble() + rect!!.width.toDouble(),
//                    rect!!.y.toDouble() + rect!!.height.toDouble()
    cv::Point p2 = cv::Point(rect.origin.x + rect.size.width ,rect.origin.y + rect.size.height);
    cv::rectangle(mat, p1, p2, cv::Scalar(0.0, 255.0, 0.0, 0.0));
    
    return [UIImage imageWithCVMat:mat];
   }

+ (double) angle:(cv::Point)pt1  :(cv::Point)pt2  :(cv::Point)pt0 {
     double dx1  = pt1.x - pt0.x;
     double dy1 = pt1.y - pt0.y;
     double dx2 = pt2.x - pt0.x;
     double dy2 = pt2.y - pt0.y;
     return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10);
 }


+(UIImage*) perspectiveCorrection:(CGPoint)ocvPIn1  :(CGPoint)ocvPIn2  :(CGPoint)ocvPIn3 :(CGPoint)ocvPIn4 :(UIImage*)image
{
    double resultWidth = ocvPIn4.x  ;
    double resultHeight = ocvPIn3.y;
   
    cv::Mat inputMat = image.CVMat_CV_8UC4;
    cv::Mat outputMat = image.CVMat_CV_8UC4;
    std::vector<cv::Point> source = std::vector<cv::Point>();
    source.push_back(cv::Point(ocvPIn1.x,ocvPIn1.y));
    source.push_back(cv::Point(ocvPIn2.x,ocvPIn2.y));
    source.push_back(cv::Point(ocvPIn3.x,ocvPIn3.y));
    source.push_back(cv::Point(ocvPIn4.x,ocvPIn4.y));
   
    cv::Mat startM =  cv::Mat(source);
    cv::Point ocvPOut1 = cv::Point(0.0, 0.0);
    cv::Point ocvPOut2 = cv::Point(0.0, resultHeight);
    cv::Point ocvPOut3 = cv::Point(resultWidth, resultHeight);
    cv::Point ocvPOut4 = cv::Point(resultWidth, 0.0);
    std::vector<cv::Point> dest = std::vector<cv::Point>();
    dest.push_back(ocvPOut1);
    dest.push_back(ocvPOut2);
    dest.push_back(ocvPOut3);
    dest.push_back(ocvPOut4);
    
    cv::Mat endM =  cv::Mat(dest);
    cv::Size size =  cv::Size(resultWidth, resultHeight);
    cv::Mat perspectiveTransform =  cv::getPerspectiveTransform(startM, endM);
    cv::warpPerspective(inputMat,outputMat,perspectiveTransform,size,cv::INTER_CUBIC);
    return [UIImage imageWithCVMat:outputMat];
    }


@end
