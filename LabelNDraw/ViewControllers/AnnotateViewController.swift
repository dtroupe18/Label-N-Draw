//
//  AnnotateViewController.swift
//  SnapChatCamera
//
//  Created by Dave on 9/23/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import AVKit
import ColorSlider
import CoreData
import Photos

class AnnotateViewController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    // Images
    var originalImage: UIImage?
    
    // Buttons
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    
    // TextViews
    @IBOutlet weak var tvOne: UITextView!
    @IBOutlet weak var tvTwo: UITextView!
    @IBOutlet weak var tvThree: UITextView!
    
    
    // TextView Wrappers
    @IBOutlet weak var wrapperOne: UIView!
    @IBOutlet weak var wrapperTwo: UIView!
    @IBOutlet weak var wrapperThree: UIView!
    
    
    // TextView Wrapper Constraints
    @IBOutlet weak var wrapperOneCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperOneCenterY: NSLayoutConstraint!
    @IBOutlet weak var wrapperTwoCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperTwoCenterY: NSLayoutConstraint!
    @IBOutlet weak var wrapperThreeCenterX: NSLayoutConstraint!
    @IBOutlet weak var wrapperThreeCenterY: NSLayoutConstraint!
    
    
    var activeTextView = UITextView()
    var textColor = UIColor.black
    
    // Drawing
    var drawing: Bool! {
        didSet {
            changePencilImage()
        }
    }
    
    var lastPoint = CGPoint.zero
    var fromPoint = CGPoint()
    var toPoint = CGPoint()
    var brushWidth: CGFloat = 4.0
    var opacity: CGFloat = 1.0
    var strokeColor: CGColor = UIColor.red.cgColor
    let screenSize = UIScreen.main.bounds
    var previousDrawings = [UIImage]()
    
    // ColorSlider
    var colorSlider: ColorSlider!
    
    // UISlider
    @IBOutlet weak var slider: UISlider!
    
    // Filtering
    let filterNames = [
        "NONE",
        "CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer",
        "CISepiaTone"
    ]
    
    var ciContext: CIContext?
    var filter: CIFilter?
    var orientation: UIImageOrientation = .up
    var swipeRight: UISwipeGestureRecognizer!
    var swipeLeft: UISwipeGestureRecognizer!
    var swipeCount: Int = 0 {
        didSet {
            displaySlider()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    // MARKER: COLOR SLIDER!
    private func createColorSlider() {
        let previewView = DefaultPreviewView()
        previewView.side = .left
        previewView.animationDuration = 0.2
        previewView.offsetAmount = 50
        
        colorSlider = ColorSlider(orientation: .vertical, previewView: previewView)
        colorSlider.frame = CGRect(x: 100, y: 150, width: 12, height: 300)
        colorSlider.translatesAutoresizingMaskIntoConstraints = false
        colorSlider.addTarget(self, action: #selector(self.changedColor(_:)), for: .valueChanged)
        imageView.addSubview(colorSlider)
        
        // Constraints for colorSlider
        // 1. Center it with the draw button
        // 2. Add some space at the top
        // 3. Give it a fixed size
        colorSlider.widthAnchor.constraint(equalToConstant: 12).isActive = true
        colorSlider.heightAnchor.constraint(equalToConstant: 290).isActive = true
        NSLayoutConstraint(item: colorSlider, attribute: .centerX, relatedBy: NSLayoutRelation.equal, toItem: drawButton, attribute: .centerX, multiplier: 1.0, constant: 1.0).isActive = true
        NSLayoutConstraint(item: colorSlider, attribute: .top, relatedBy: .equal, toItem: drawButton, attribute: .bottom, multiplier: 1.0, constant: 15.0).isActive = true
    }
    
    @objc func changedColor(_ slider: ColorSlider) {
        if !drawing {
            activeTextView.textColor = slider.color
        }
        strokeColor = slider.color.cgColor
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if tvOne.isFirstResponder {
            tvOne.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else if tvTwo.isFirstResponder {
            tvTwo.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else if tvThree.isFirstResponder {
            tvThree.backgroundColor = UIColor.lightGray.withAlphaComponent(CGFloat(slider.value))
        }
        else {
            imageView.alpha = CGFloat(slider.value)
        }
    }
    
    private func displaySlider() {
        if swipeCount != 0 {
            slider.isHidden = false
        }
        else {
            slider.isHidden = true
        }
    }
    
    // MARKER: DRAWING
    @IBAction func drawPressed(_ sender: Any) {
        drawing = !drawing
        trashButton.isHidden = true
        undoButton.isHidden = !undoButton.isHidden
        
        if drawing {
            swipeLeft.isEnabled = false
            swipeRight.isEnabled = false
            // topImageView.isUserInteractionEnabled = true
        }
        else {
            swipeLeft.isEnabled = true
            swipeRight.isEnabled = true
        }
        
        if !wrapperOne.isHidden {
            wrapperOne.isUserInteractionEnabled = !drawing
        }
        if !wrapperTwo.isHidden {
            wrapperTwo.isUserInteractionEnabled = !drawing
        }
        if !wrapperThree.isHidden {
            wrapperThree.isUserInteractionEnabled = !drawing
        }
    }
    
    // Flip the drawbutton image so the user knows if they are drawing
    private func changePencilImage() {
        if drawing {
            drawButton.setBackgroundImage(#imageLiteral(resourceName: "BlackPencil"), for: .normal)
        }
        else {
            drawButton.setBackgroundImage(#imageLiteral(resourceName: "Pencil"), for: .normal)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing {
            if let touch = touches.first {
                lastPoint = touch.preciseLocation(in: self.imageView)
            }
        }
        else {
            slider.isHidden = true
            if tvOne.isFirstResponder {
                tvOne.resignFirstResponder()
            }
            else if tvTwo.isFirstResponder {
                tvTwo.resignFirstResponder()
            }
            else if tvThree.isFirstResponder {
                tvThree.resignFirstResponder()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing {
            if let touch = touches.first {
                let currentPoint = touch.preciseLocation(in: imageView)
                drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
                lastPoint = currentPoint
            }
        }
    }
    
    
    // all drawing has to occur on an image without an applied filter (i.e. the original image)
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContextWithOptions(topImageView.bounds.size, false, 0.0)
        topImageView.image?.draw(in: imageView.frame)
        
        let context = UIGraphicsGetCurrentContext()
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(strokeColor)
        context?.setBlendMode(CGBlendMode.normal)
        context?.strokePath()
        
        topImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        topImageView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if drawing {
            if let drawing = topImageView.image {
                previousDrawings.append(drawing)
            }
        }
    }
    
    //MARKER: UNDO DRAWING
    @IBAction func undoPressed(_ sender: Any) {
        if !previousDrawings.isEmpty {
            previousDrawings.remove(at: previousDrawings.count - 1)
            if let lastDrawing = previousDrawings.last {
                topImageView.image = lastDrawing
            }
            else {
                // empty
                topImageView.image = nil
            }
        }
    }
    
    @IBAction func addText(_ sender: Any) {
        drawing = false
        // swipeLeft.isEnabled = true
        // swipeRight.isEnabled = true ?? False ??
        undoButton.isHidden = true
        trashButton.isHidden = false
        
        //QWE
        
        if wrapperOne.isHidden {
            wrapperOne.isHidden = false
            tvOne.isHidden = false
            wrapperOne.isUserInteractionEnabled = true
            tvOne.becomeFirstResponder()
        }
        else if wrapperTwo.isHidden {
            wrapperTwo.isHidden = false
            tvTwo.isHidden = false
            wrapperTwo.isUserInteractionEnabled = true
            tvTwo.becomeFirstResponder()
        }
        else if wrapperThree.isHidden {
            wrapperThree.isHidden = false
            tvThree.isHidden = false
            wrapperThree.isUserInteractionEnabled = true
            tvThree.becomeFirstResponder()
        }
    }
    
    @IBAction func trashPressed(_ sender: Any) {
        if activeTextView.tag == 11 {
            tvOne.text = ""
            wrapperOne.isHidden = true
        }
        else if activeTextView.tag == 12 {
            tvTwo.text = ""
            wrapperTwo.isHidden = true
        }
        else if activeTextView.tag == 13 {
            tvThree.text = ""
            wrapperThree.isHidden = true
        }
    }
    
    // MARKER: GESTURE RECOGNIZERS
    func createGestureRecognizers() {
        // Pan Gestures
        let wrapperOnePanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperOne.addGestureRecognizer(wrapperOnePanGesture)
        wrapperOnePanGesture.delegate = self

        let wrapperTwoPanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperTwo.addGestureRecognizer(wrapperTwoPanGesture)
        wrapperTwoPanGesture.delegate = self
        
        let wrapperThreePanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        wrapperThree.addGestureRecognizer(wrapperThreePanGesture)
        wrapperThreePanGesture.delegate = self
        
        // Pinch Gestures
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        imageView.addGestureRecognizer(pinchGesture)
        imageView.isUserInteractionEnabled = true
        pinchGesture.delegate = self

        let wrapperOnePinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperOne.addGestureRecognizer(wrapperOnePinchGesture)
        wrapperOnePinchGesture.delegate = self

        let wrapperTwoPinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperTwo.addGestureRecognizer(wrapperTwoPinchGesture)
        wrapperTwoPinchGesture.delegate = self
        
        let wrapperThreePinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(recognizer:)))
        wrapperThree.addGestureRecognizer(wrapperThreePinchGesture)
        wrapperThreePinchGesture.delegate = self
        
        // Rotate Gestures
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        imageView.addGestureRecognizer(rotateGesture)
        rotateGesture.delegate = self

        let wrapperOneRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperOne.addGestureRecognizer(wrapperOneRotate)
        wrapperOneRotate.delegate = self

        let wrapperTwoRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperTwo.addGestureRecognizer(wrapperTwoRotate)
        wrapperTwoRotate.delegate = self

        let wrapperThreeRotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        wrapperThree.addGestureRecognizer(wrapperThreeRotate)
        wrapperThreeRotate.delegate = self

        // Swipe Gesture
        swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(recognizer:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.right // backwards like apple always does
        imageView.addGestureRecognizer(swipeLeft)

        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(recognizer:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.left
        imageView.addGestureRecognizer(swipeRight)
    }
    
    @objc func handleRotate(recognizer: UIRotationGestureRecognizer) {
        var lastRotation: CGFloat = 0
        let location = recognizer.location(in: recognizer.view)
        let rotation = lastRotation + recognizer.rotation
        
        if recognizer.state == .ended {
            lastRotation = 0.0
        }
        
        // Rotate detected on imageView
        if wrapperOne.frame.contains(location) {
            wrapperOne.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if wrapperTwo.frame.contains(location) {
            wrapperTwo.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if wrapperThree.frame.contains(location) {
            wrapperThree.transform = CGAffineTransform(rotationAngle: rotation)
        }
        else if let view = recognizer.view {
            if view.tag != 37 && view.tag != 38 {                
                view.transform = CGAffineTransform(rotationAngle: rotation)
            }
        }
    }
    
    // HANDLE RIGHT / LEFT SWIPES
    @objc func handleSwipe(recognizer: UISwipeGestureRecognizer) {
        if !drawing {
            let location = recognizer.location(in: recognizer.view)
            if !wrapperOne.frame.contains(location) && !wrapperTwo.frame.contains(location) && !wrapperThree.frame.contains(location) {
                
                if recognizer.direction == UISwipeGestureRecognizerDirection.right {
                    if swipeCount < filterNames.count - 1 {
                        swipeCount += 1
                        applyFilter()
                    }
                }
                else if recognizer.direction == UISwipeGestureRecognizerDirection.left {
                    if swipeCount > 0 {
                        swipeCount -= 1
                        if swipeCount > -1 {
                            applyFilter()
                        }
                    }
                }
            }
        }
    }
    
    // Apply Filters as the user swipes
    func applyFilter() {
        if swipeCount > -1 && swipeCount < filterNames.count && originalImage != nil {
            if swipeCount == 0 {
                imageView.image = originalImage!
                return
            }
            else if let filter = CIFilter(name: filterNames[swipeCount]) {
                let ciImage = CIImage(cgImage: originalImage!.cgImage!)
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                ciContext = CIContext(options: nil)
                let imageRef = ciContext!.createCGImage(filter.outputImage!, from: ciImage.extent)
                let imageTurned = UIImage(cgImage: imageRef!, scale: CGFloat(1.0), orientation: originalImage!.imageOrientation)
                imageView.image = imageTurned
            }
        }
    }
    
    // HANDLE PINCH GESTURES ON TEXT FIELDS
    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        let location = recognizer.location(in: recognizer.view)
        let pinchScale: CGFloat = recognizer.scale
        
        // PINCH DETECTED ON IMAGEVIEW
        if wrapperOne.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: wrapperOne)
        }
        else if wrapperTwo.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: wrapperTwo)
        }
        else if wrapperThree.frame.contains(location) {
            adjustTextViewFontSize(pinchScale: pinchScale, view: wrapperThree)
        }

        // PINCH DETECTED IN TEXTVIEW
        else if let view = recognizer.view {
            adjustTextViewFontSize(pinchScale: pinchScale, view: view)
        }
        recognizer.scale = 1.0
    }
    
    // FUNCTION TO DETERMINE HOW TO SCALE THE FONT SIZE OF A TEXTVIEW BASED ON A PINCH GESTURE
    private func adjustTextViewFontSize(pinchScale: CGFloat, view: UIView) {
        let minFontSize: CGFloat = 15
        let maxFontSize: CGFloat = 100
        var textview: UITextView?
        
        if view.tag == 1 {
            textview = tvOne
        }
        else if view.tag == 2 {
            textview = tvTwo
        }
        else if view.tag == 3 {
            textview = tvThree
        }
        
        if textview != nil {
            if let currentFontSize = textview!.font?.pointSize {
                let size = CGFloat(currentFontSize * pinchScale)
                if size > maxFontSize {
                    textview!.font = UIFont.systemFont(ofSize: maxFontSize)
                }
                else if size < minFontSize {
                    textview!.font = UIFont.systemFont(ofSize: minFontSize)
                }
                else {
                    textview!.font = UIFont.systemFont(ofSize: CGFloat(currentFontSize * pinchScale))
                }
            }
        }
    }
    
    // TEXTFIELD PAN GESTURES HANDLED HERE
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        if let uiView = recognizer.view {
            var translation = recognizer.translation(in: self.view)
            
            translation.x = max(translation.x, imageView.frame.minX - uiView.frame.minX)
            translation.x = min(translation.x, imageView.frame.maxX - uiView.frame.maxX)
            translation.y = max(translation.y, imageView.frame.minY - uiView.frame.minY)
            translation.y = min(translation.y, imageView.frame.maxY - uiView.frame.maxY)
            
            if let view = recognizer.view {
                view.center = CGPoint(x:view.center.x + translation.x,
                                      y:view.center.y + translation.y)
                switch recognizer.state {
                case .changed:
                    if uiView.tag == 1 {
                        wrapperOneCenterX.constant = wrapperOneCenterX.constant + translation.x
                        wrapperOneCenterY.constant = wrapperOneCenterY.constant + translation.y
                    }
                    else if uiView.tag == 2 {
                        wrapperTwoCenterX.constant = wrapperTwoCenterX.constant + translation.x
                        wrapperTwoCenterY.constant = wrapperTwoCenterY.constant + translation.y
                    }
                    else if uiView.tag == 3 {
                        wrapperThreeCenterX.constant = wrapperThreeCenterX.constant + translation.x
                        wrapperThreeCenterY.constant = wrapperThreeCenterY.constant + translation.y
                    }
                default:
                    break
                }
                recognizer.setTranslation(CGPoint.zero , in: view)
            }
        }
    }
    
    // ALLOWS MULTIPLE GESTURES AT THE SAME TIME
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPinchGestureRecognizer || gestureRecognizer is UISwipeGestureRecognizer) && (otherGestureRecognizer is UIPinchGestureRecognizer || otherGestureRecognizer is UISwipeGestureRecognizer) {
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // KEEP TRACK OF THE LAST TOUCHED TEXTVIEW
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeTextView = textView
        swipeLeft.isEnabled = false
        swipeRight.isEnabled = false
        
        // if a textview is touched and becomes first responder than
        // the trash icon should be displayed
        trashButton.isHidden = false
        slider.isHidden = false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        swipeLeft.isEnabled = true
        swipeRight.isEnabled = true
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toCamera", sender: nil)
        }
    }
    
    // MARKER: SAVING IMAGE
    @IBAction func savePressed(_ sender: Any) {
        let otherAlert = UIAlertController(title: "Save Photo", message: "Where would you like to save this photo?", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let saveToLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default) { _ in
            if let imageToSave = self.captureScreen() {
                UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
        
        let saveLocally = UIAlertAction(title: "Save in App", style: UIAlertActionStyle.destructive, handler: savePhotoInApp)
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        // relate actions to controllers
        otherAlert.addAction(saveToLibrary)
        otherAlert.addAction(saveLocally)
        otherAlert.addAction(cancel)
        
        if let popover = otherAlert.popoverPresentationController {
            let viewForSource = sender as! UIView
            popover.sourceView = viewForSource
            popover.sourceRect = viewForSource.bounds
        }
        present(otherAlert, animated: true, completion: nil)
    }
    
    func savePhotoInApp(alert: UIAlertAction) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let time = Date().millisecondsSince1970
        let relativePath = String("\(time).png")
        let filePath = documentsURL.appendingPathComponent(relativePath)
        
        // check if a file already exists at this path
        // this should never happen, but just to be safe
        if fileManager.fileExists(atPath: filePath.path) {
            // remove the file
            do {
                try fileManager.removeItem(atPath: filePath.path)
                saveImageToDisk(filePath: filePath, relativePath: relativePath)
            }
            catch {
                print("unable to delete file")
            }
        }
        else {
            // we can save right away
            saveImageToDisk(filePath: filePath, relativePath: relativePath)
            
        }
    }
    
    func saveImageToDisk(filePath: URL, relativePath: String) {
        do {
            if let screenShot = captureScreen() {
                if let pngImageData = UIImagePNGRepresentation(screenShot) {
                    try pngImageData.write(to: filePath, options: .atomic)
                    saveToCoreData(relativePath: relativePath)
                }
            }
        }
        catch {
            print("Failed to save image")
        }
    }
    
    private func saveToCoreData(relativePath: String) {
        // App Delegate For CoreData
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let container = appDelegate.persistentContainer
        let context = container.viewContext
        let entity = Image(context: context)
        entity.filePath = relativePath
        appDelegate.saveContext()
        showImageSavedAlert()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let status = PHPhotoLibrary.authorizationStatus()
            if status != PHAuthorizationStatus.authorized {
                requestPhotoLibraryAccess()
                return
            }
            // Error saving image, nothing we can do but alert the user
            let ac = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            DispatchQueue.main.async {
                self.present(ac, animated: true)
            }
        }
        else {
            showImageSavedAlert()
        }
    }
    
    private func showImageSavedAlert() {
        let ac = UIAlertController(title: "Image Saved", message: "Your image was successfully saved", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }
    
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization({ (newStatus) in
            if (newStatus != PHAuthorizationStatus.authorized) {
                let ac = UIAlertController(title: "Access Error", message: "You will not be able to save photos to your library until you grant access. You can change this at anytime in settings.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                DispatchQueue.main.async {
                    self.present(ac, animated: true)
                }
            }
        })
    }
    
    // MARKER: CAPTURING THE SCREEN
    private func captureScreen() -> UIImage? {
        if !wrapperOne.isHidden {
            imageView.addSubview(wrapperOne)
        }
        if !wrapperTwo.isHidden {
            imageView.addSubview(wrapperTwo)
        }
        if !wrapperThree.isHidden {
            imageView.addSubview(wrapperThree)
        }
        if topImageView.image != nil {
            imageView.addSubview(topImageView)
        }
        colorSlider.isHidden = true
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        imageView.layer.render(in: context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        colorSlider.isHidden = false
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func initialize() {
        if originalImage != nil {
            self.imageView.image = originalImage
            self.imageView.contentMode = UIViewContentMode.scaleAspectFill // or fit?
        }
        wrapperOne.isHidden = true
        tvOne.isHidden = true
        tvOne.delegate = self
        
        wrapperTwo.isHidden = true
        tvTwo.isHidden = true
        tvTwo.delegate = self
        
        wrapperThree.isHidden = true
        tvThree.isHidden = true
        tvThree.delegate = self


        tvOne.isMultipleTouchEnabled = true
        tvTwo.isMultipleTouchEnabled = true
        tvThree.isMultipleTouchEnabled = true
        imageView.isMultipleTouchEnabled = true
        
        drawing = false
        createGestureRecognizers()
        createColorSlider()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // comment to update git
}



