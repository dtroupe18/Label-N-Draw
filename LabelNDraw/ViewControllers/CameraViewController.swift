//
//  CameraViewController.swift
//  SnapChatCamera
//
//  Created by Dave on 9/18/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    
    
    var captureSession: AVCaptureSession!
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var captureDeviceInputBack: AVCaptureDeviceInput!
    var captureDeviceInputFront: AVCaptureDeviceInput!
    var imageCaptured: UIImage!
    var cameraState: Bool = true
    var flashOn: Bool = false
    var usingBackCamera: Bool = true
    
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            self.navigationController?.setToolbarHidden(true, animated: false)
        }
        canAccessCamera()
    }
    
    @IBAction func changeFlash(_ sender: Any) {
        flashOn = !flashOn
        if flashOn {
            self.flashButton.setImage(#imageLiteral(resourceName: "FlashOn"), for: .normal)
        }
        else {
            self.flashButton.setImage(#imageLiteral(resourceName: "FlashOff"), for: .normal)
        }
        toggleTorch()
    }
    
    func toggleTorch() {
        if backCamera == nil {
            return
        }
        
        if backCamera.hasTorch {
            do {
                try backCamera.lockForConfiguration()
                
                if flashOn {
                    backCamera.torchMode = .on
                }
                else {
                    backCamera.torchMode = .off
                }
                
                backCamera.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.captureSession.isRunning {
                return
            }
            else {
                let settings = AVCapturePhotoSettings()
                let previewPixelType = settings.__availablePreviewPhotoPixelFormatTypes.first!
                let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                                     kCVPixelBufferWidthKey as String: 160,
                                     kCVPixelBufferHeightKey as String: 160]
                settings.previewPhotoFormat = previewFormat
                self.cameraOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    // delgate method
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            DispatchQueue.main.async {
                self.imageCaptured = UIImage(data: imageData)
                self.captureSession.stopRunning()
                self.performSegue(withIdentifier: "toAnnotate", sender: nil)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPoint = touches.first
        let x = (touchPoint?.location(in: self.view).x)! / self.view.bounds.width
        let y = (touchPoint?.location(in: self.view).y)! / self.view.bounds.height
        
        let realX = (touchPoint?.location(in: self.view).x)!
        let realY = (touchPoint?.location(in: self.view).y)!
        
        let focusPoint = CGPoint(x: x, y: y)
        
        let k = DrawSquare(frame: CGRect(
            origin: CGPoint(x: realX - 75, y: realY - 75),
            size: CGSize(width: 150, height: 150)))
        
        
        if backCamera != nil {
            do {
                try backCamera.lockForConfiguration()
                self.previewView.addSubview(k)
            }
            catch {
                print("Can't lock back camera for configuration")
            }
            if backCamera.isFocusPointOfInterestSupported {
                backCamera.focusPointOfInterest = focusPoint
            }
            if backCamera.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                backCamera.focusMode = AVCaptureDevice.FocusMode.autoFocus
            }
            if backCamera.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose) {
                backCamera.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            }
            backCamera.unlockForConfiguration()
            
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            k.removeFromSuperview()
        }
    }
    
    @IBAction func pinchToZoom(_ sender: UIPinchGestureRecognizer) {
        if backCamera != nil {
            if sender.state == .changed {
                
                let maxZoomFactor = backCamera.activeFormat.videoMaxZoomFactor
                let pinchVelocityDividerFactor: CGFloat = 35.0
                
                do {
                    try backCamera.lockForConfiguration()
                    defer { backCamera.unlockForConfiguration() }
                    
                    let desiredZoomFactor = backCamera.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                    backCamera.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
    func canAccessCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                // print("can access camera")
                self.loadCamera()
                
            } else {
                self.askPermission()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        if self.previewLayer != nil {
            previewLayer.frame = self.view.bounds
        }
    }
    
    func loadCamera() {
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            self.captureSession.startRunning()
            self.cameraOutput = AVCapturePhotoOutput()
            
            if self.captureSession.canSetSessionPreset(AVCaptureSession.Preset.high) {
                self.captureSession.sessionPreset = AVCaptureSession.Preset.high
            }
            
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
            
            for device in deviceDiscoverySession.devices {
                if (device as AnyObject).position == AVCaptureDevice.Position.back {
                    self.backCamera = device
                }
                else if (device as AnyObject).position == AVCaptureDevice.Position.front {
                    self.frontCamera = device
                }
            }
            
            
            do {
                self.captureDeviceInputBack = try AVCaptureDeviceInput(device: self.backCamera)
            }
            catch {
                print("Error setting captureDeviceInputBack")
            }
            do {
                self.captureDeviceInputFront = try AVCaptureDeviceInput(device: self.frontCamera)
            }
            catch {
                print("Error setting captureDeviceInputFront")
            }
            
            if (self.captureSession.canAddInput(self.captureDeviceInputBack)) {
                self.captureSession.addInput(self.captureDeviceInputBack)
                if (self.captureSession.canAddOutput(self.cameraOutput)) {
                    self.captureSession.addOutput(self.cameraOutput)
                    
                    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.previewLayer.frame = self.previewView.layer.bounds
                    self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    self.previewView.layer.insertSublayer(self.previewLayer, at: 0)
                }
            }
            else {
                print("can't add input")
            }
        }
    }
    
    @IBAction func switchCameraPressed(_ sender: Any) {
        usingBackCamera = !usingBackCamera
        if usingBackCamera {
            displayBackCamera()
            switchCameraButton.setImage(#imageLiteral(resourceName: "FrontCamera"), for: .normal)
        }
        else {
            displayFrontCamera()
            switchCameraButton.setImage(#imageLiteral(resourceName: "RearCamera"), for: .normal)
        }
    }
    
    private func displayFrontCamera() {
        DispatchQueue.main.async {
            if self.captureSession.canAddInput(self.captureDeviceInputFront) {
                self.captureSession.addInput(self.captureDeviceInputFront)
            }
            else {
                self.captureSession.removeInput(self.captureDeviceInputBack)
                if self.captureSession.canAddInput(self.captureDeviceInputFront) {
                    self.captureSession.addInput(self.captureDeviceInputFront)
                }
            }
        }
    }
    
    private func displayBackCamera() {
        DispatchQueue.main.async {
            if self.captureSession.canAddInput(self.captureDeviceInputBack) {
                self.captureSession.addInput(self.captureDeviceInputBack)
            }
            else {
                self.captureSession.removeInput(self.captureDeviceInputFront)
                if self.captureSession.canAddInput(self.captureDeviceInputBack) {
                    self.captureSession.addInput(self.captureDeviceInputBack)
                }
            }
        }
    }
    
    func askPermission() {
        let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if cameraPermissionStatus != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                [weak self]
                (granted :Bool) -> Void in
                
                if granted == true {
                    // User granted
                    DispatchQueue.main.async(){
                        self?.loadCamera()
                    }
                }
                else {
                    // User Rejected
                    DispatchQueue.main.async(){
                        let alert = UIAlertController(title: "Camera Access Denied" , message: "Without permission to use the camera this app won't be very useful. You can grant access at anytime in settings.", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alert.addAction(action)
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            });
        }
        else {
            loadCamera()
        }
    }
    
    @IBAction func photoLibraryPressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toSavedPhotos", sender: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAnnotate" {
            if let controller = segue.destination as? AnnotateViewController {
                controller.originalImage = self.imageCaptured
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.captureSession != nil && self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
}






