//
//  ViewController.swift
//  PageCapture
//
//  Created by safarifone on 15/02/2022.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {
    
    @IBOutlet weak var topSurfaceView: UIImageView!
    @IBOutlet weak var ivCaptured: UIView!
    @IBOutlet weak var bottomRightImageView: UIImageView!
    @IBOutlet weak var bottomLeftImageView: UIImageView!
    @IBOutlet weak var topRightImageView: UIImageView!
    @IBOutlet weak var topLeftImageView: UIImageView!
    
    
    private var boxHash = Dictionary<String, CGRect>()
    private var boxWidth = 100
    private var boxHeight = 100
    
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!checkPermission()) {
            requestPermission()
        } else {
            startCamera()
        }
    }
    
    func  checkPermission() -> Bool{
        return  AVCaptureDevice.authorizationStatus(for: .video) ==  AVAuthorizationStatus.authorized
    }
    override var shouldAutorotate: Bool {
        if (UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft ||
            UIDevice.current.orientation == UIDeviceOrientation.landscapeRight ||
            UIDevice.current.orientation == UIDeviceOrientation.unknown) {
            return false
        }
        else {
            return true
        }
    }
    func processImage() {
        print("Suleman Process")
    }
    
    @IBAction func captureMe(_ sender: UIButton) {
        stopCamera()
    }
    func requestPermission(){
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
            if granted == true {
                self.startCamera()
            } else {
                
            }
        })
        
    }
    @IBAction func retryCapturing(_ sender: UIButton) {
        session.startRunning()
    }
}


    // AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
    func startCamera(){
        session.sessionPreset = .hd1280x720
        guard let device = AVCaptureDevice
                .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                         for: .video,
                         position: AVCaptureDevice.Position.back) else {
                    return
                }
        captureDevice = device
        beginSession()
    }
    
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
            videoDataOutput.connection(with: .video)?.isEnabled = true
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            let rootLayer :CALayer = self.ivCaptured.layer
            previewLayer.frame =  ivCaptured.frame
            rootLayer.addSublayer(self.previewLayer)
            session.startRunning()
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    private func makeImageCroppedToRectOfInterest(from image: UIImage) -> UIImage {

        let outputRect = previewLayer.frame
//        previewLayer.layerRectConverted(fromMetadataOutputRect: frame)
        guard let cgImage = image.cgImage else {
            return image
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let cropRect = CGRect(x: outputRect.origin.x * width,
                              y: outputRect.origin.y * height ,
                              width: outputRect.size.width * width,
                              height: outputRect.size.height * height)

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cropped)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
       
       
            
            
            
            
            DispatchQueue.main.async {[self] in
                if let image =  self.convert(cmage: ciimage).rotated(by: .pi/2) {
                    let ivCamaxY = 1280.0
                    let ivCamaxX = 720.0
                    let boxHeight = ivCamaxY * (50.0 / view.frame.size.height)
                    let boxWidth = ivCamaxX * (50.0 / view.frame.size.width)
                    let tlX = topLeftImageView.frame.origin.x / view.frame.size.width
                    let tlY = topLeftImageView.frame.origin.y / view.frame.size.height
                    let trX = topRightImageView.frame.origin.x / view.frame.size.width
                    let trY = topRightImageView.frame.origin.y / view.frame.size.height
                    let blX = bottomLeftImageView.frame.origin.x / view.frame.size.width
                    let blY = bottomLeftImageView.frame.origin.y / view.frame.size.height
                    let brX = bottomRightImageView.frame.origin.x / view.frame.size.width
                    let brY = bottomRightImageView.frame.origin.y / view.frame.size.height
                    let TopLeftCroped = cropImage(image:image,toRect: CGRect(x:  ivCamaxX * tlX, y:  tlY*ivCamaxY , width: boxWidth, height: boxHeight))
                    let TopRighttCroped = cropImage(image:image,toRect: CGRect(x:  ivCamaxX * trX, y:  trY*ivCamaxY , width: boxWidth, height: boxHeight))
                    let BottomLeftCroped = cropImage(image:image,toRect: CGRect(x:  ivCamaxX * blX, y:  blY*ivCamaxY , width: boxWidth, height: boxHeight))
                    let BottomRightCroped = cropImage(image:image,toRect: CGRect(x:  ivCamaxX * brX, y:  brY*ivCamaxY , width: boxWidth, height: boxHeight))
                topLeftImageView.image = TopLeftCroped
                bottomLeftImageView.image = BottomLeftCroped
                topRightImageView.image = TopRighttCroped
                bottomRightImageView.image = BottomRightCroped
                    
                    
                    let TLFB = OpenCVWrapper.processImage(withOpenCV: TopLeftCroped)
                    let BLFB = OpenCVWrapper.processImage(withOpenCV: BottomLeftCroped)
                    let TRFB = OpenCVWrapper.processImage(withOpenCV: TopRighttCroped)
                    let BRFB = OpenCVWrapper.processImage(withOpenCV: BottomRightCroped)
                    print("TLFB => \(TLFB.isSquare)",
                          "BLFB=> \(BLFB.isSquare)",
                          "TRFB=> \(TRFB.isSquare)",
                          "BRFB=> \(BRFB.isSquare)")
                    if TLFB.isSquare && BLFB.isSquare  && TRFB.isSquare && BRFB.isSquare {
                        stopCamera()
                        topLeftImageView.image = OpenCVWrapper.drawRectangle(TLFB.rect, TopLeftCroped)
                        bottomLeftImageView.image = OpenCVWrapper.drawRectangle(BLFB.rect, BottomLeftCroped)
                        topRightImageView.image = OpenCVWrapper.drawRectangle(TRFB.rect, TopRighttCroped)
                        bottomRightImageView.image = OpenCVWrapper.drawRectangle(BRFB.rect, BottomRightCroped)
                        let TLOrigin = topLeftImageView.frame.origin
                        let BLOrigin = bottomLeftImageView.frame.origin
                        let BROrigin = bottomRightImageView.frame.origin
                        let TROrigin = topRightImageView.frame.origin
                    
                        
                        var ocvPIn1 = CGPoint( x:(TLOrigin.x + TLFB.rect.minX - TLFB.rect.size.width),
                                               y:(TLOrigin.y + TLFB.rect.minY - TLFB.rect.size.width ))
                        
                        var ocvPIn2 = CGPoint( x:(BLOrigin.x + BLFB.rect.minX - BLFB.rect.size.width),
                                               y:(BLOrigin.y + BLFB.rect.minY - (BLFB.rect.size.width * 2) ))
                        var ocvPIn3 = CGPoint( x:(BROrigin.x + BRFB.rect.minX - BRFB.rect.size.width),
                                               y:(BROrigin.y + BRFB.rect.minY - (BRFB.rect.size.width * 2) ))
                        var ocvPIn4 = CGPoint( x:(TROrigin.x + TRFB.rect.minX - TRFB.rect.size.width),
                                               y:(TROrigin.y + TRFB.rect.minY - (TRFB.rect.size.width) ))

                        
//                    let finalcCropedImage =    OpenCVWrapper.perspectiveCorrection(ocvPIn1, ocvPIn2, ocvPIn3, ocvPIn4, image)
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                        
                    }
                //            print(TopLeftCropedProcess,BottomLeftCropedProcess,TopRighttCropedProcess,BottomRightCropedProcess)
                
            }
        }
     
       
    }
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                // we got back an error!
                let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            } else {
                let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
    func cropImage(image:UIImage, toRect rect:CGRect) -> UIImage{
        let imageRef:CGImage = image.cgImage!.cropping(to: rect)!
        let croppedImage:UIImage = UIImage(cgImage:imageRef)
        return croppedImage
    }
    func getCGImage(){
        
    }
    func convert(cmage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
         let image = UIImage(cgImage: cgImage)
         return image
    }
    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
    }
    private func barcodeScanner(bitmap: UIImage){
           
       }
    private func angle(pt1: CGPoint, pt2: CGPoint, pt0: CGPoint)-> Double {
        let dx1: Double = pt1.x - pt0.x
        let dy1: Double = pt1.y - pt0.y
        let dx2: Double = pt2.x - pt0.x
        let dy2: Double = pt2.y - pt0.y
            return (dx1 * dx2 + dy1 * dy2) / sqrt((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 1e-10)
        }
    
   
}
