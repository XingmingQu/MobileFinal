//
//  ModuleAViewController.swift
//  ImageLab
//
//  Created by Xingming on 10/24/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

import UIKit

class ModuleAViewController: UIViewController {
    
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    var detector:CIDetector! = nil

    var blinkTimes = 0
    let bridge = OpenCVBridge()
    var eyeMouthFilter=0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil

        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU if possible
            options: optsDetector)
        
        self.bridge.setTransforms(self.videoManager.transform)
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }


    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        self.bridge.setTransforms(self.videoManager.transform)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        if !videoManager.isRunning{
            videoManager.start()
        }
    }
    
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // --------detect faces and high light-----------------------
        let f = getFaces(img: inputImage)
        // if no faces, just return original image
        if f.count == 0 { return inputImage }
        var retImage = inputImage
        
        DispatchQueue.global(qos: .background).async {
          Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
              let randomNumber = Int.random(in: 1...20)
              print("Number: \(randomNumber)")

          }
        }
        //Highlights multiple faces in the scene using CoreImage filters
        for faces in f {
            self.bridge.setImage(retImage, withBounds: faces.bounds, andContext: self.videoManager.getCIContext())
            //High light faces
            self.bridge.processImage()
            
            //-------------display if the user is smiling or blinking (and with which eye)------------
            if(faces.hasSmile){
                self.bridge.addText("Smile", atY: 10)
            }else{
                self.bridge.addText("Not Smile", atY: 10)
            }
            
            if(faces.leftEyeClosed){
                self.bridge.addText("leftEyeClosed", atY: 20)
            }else{
                self.bridge.addText("leftEyeOpen", atY: 20)
            }
            
            if(faces.rightEyeClosed){
                self.bridge.addText("rightEyeClosed", atY: 30)
            }else{
                self.bridge.addText("rightEyeOpen", atY: 30)
            }
            
            if (faces.leftEyeClosed && faces.rightEyeClosed){
                self.bridge.addText("BothClosed", atY: 40)
            }
            //-------------display if the user is smiling or blinking (and with which eye)------------
            
            retImage = self.bridge.getImageComposite()

            
        }
        //------------------------------------------------------
        
        
        
        return retImage
    }
        
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,CIDetectorSmile:true, CIDetectorEyeBlink:true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
        
    @IBAction func switchCamera(_ sender: UIButton) {
        self.videoManager.toggleCameraPosition()
    }
    
    
}
