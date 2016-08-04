//  Created by Pouria Sanae on 7/4/16
//  Copyright © 2016 Pouria Sanae. All rights reserved
// for Pod install: https://www.raywenderlich.com/97014/use-cocoapods-with-swift
// for SwiftJason: https://github.com/SwiftyJSON/SwiftyJSON

import UIKit
import AVFoundation
import SwiftyJSON


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
   
    
    //* * * IO & Variables * * *
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var zoomImage: UIImageView!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var myTextLabel: UILabel!
    @IBOutlet weak var getFileFromLib_Outlet: UIButton!
    
    @IBOutlet weak var objectButton: UIBarButtonItem!
    @IBOutlet weak var textButton: UIBarButtonItem!
    @IBOutlet weak var colorButton: UIBarButtonItem!
    @IBOutlet weak var burstButton: UIBarButtonItem!
    @IBOutlet weak var faceButton: UIBarButtonItem!
    @IBOutlet weak var locationButton: UIBarButtonItem!
    @IBOutlet weak var logoButton: UIBarButtonItem!
    
    let API_KEY = "AIzaSyA9ODXoXFNnFEb7vN-oZNRHpR30dMl4H_Q"  //my Google API key
    let picker = UIImagePickerController()
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var hasAlreadyStarted : Bool = false
    var busyWaiting : Bool = false
    var imgH : CGFloat = 0.0
    var imgW : CGFloat = 0.0
    
    enum searchTypes : Int {
        case object
        case text
        case color
        case face
        case logo
        case burst
        case location
    }
    enum modeDirection : Int {
        case left
        case right
    }
    var searchSetting = searchTypes.object
    
    //* * * Main Functions * * *
    override func viewDidLoad() {
        super.viewDidLoad()
        // --- Capture swipe gesture ---
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        //let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(_:)))
        //swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        //self.view.addGestureRecognizer(swipeUp)
        //let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(_:)))
        //swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        //self.view.addGestureRecognizer(swipeDown)
        
        picker.delegate = self  //Delegate is used to segaue back to its self
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {welcomeIntroCamera()}else{welcomeIntroNoCamera()}
    }
    override func viewDidAppear(animated: Bool) {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
            
            //Using the previewView is placeholder for camera view
            previewLayer!.frame = previewView.bounds
        } else {
            print("No Camera")
        }
    }
    override func viewWillAppear(animated: Bool) {
       if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) == nil { return } //no Camera
        //AVCaptureSessionPresetPhoto //Original //AVCaptureSessionPresetLow //AVCaptureSessionPresetMedium
        //AVCaptureSessionPresetHigh //AVCaptureSessionPreset352x288 //AVCaptureSessionPreset640x480
        //AVCaptureSessionPresetiFrame960x540 //AVCaptureSessionPreset1280x720
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset1280x720 //changed on Aug 3 AVCaptureSessionPreset640x480
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) //Select camer, defaul=rear-camera
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession!.canAddInput(input) {
                captureSession!.addInput(input)
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                if captureSession!.canAddOutput(stillImageOutput) {
                    captureSession!.addOutput(stillImageOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    //previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                    previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait //LandscapeLeft
                    previewView.layer.addSublayer(previewLayer!)
                    captureSession!.startRunning()
                }
            }
        } catch let error as NSError {  print(error)   }
    }
    
    //* * * Actions * * *
    @IBAction func getFileFromLib(sender: UIButton) {
        picker.allowsEditing = false       //Tell the picker we want a whole picture, not an edited version.
        picker.sourceType = .PhotoLibrary  //Set the source type to the photo library
        picker.modalPresentationStyle = .Popover  // use for IPAD style
        presentViewController(picker, animated: true, completion: nil)//4
        //picker.popoverPresentationController?.barButtonItem = sender  //not sure what this does
    }
    @IBAction func didPressTakePhoto(sender: UIButton) {
        takePhoto()
    }
    @IBAction func objectClick(sender: UIBarButtonItem)  { objectMode() }
    @IBAction func textClick(sender: UIBarButtonItem)    { textMode()     }
    @IBAction func colorClick(sender: UIBarButtonItem)   { colorMode()    }
    @IBAction func burstClick(sender: UIBarButtonItem)   { burstMode()    }
    @IBAction func faceClick(sender: UIBarButtonItem) { faceMode() }
    @IBAction func locationClick(sender: UIBarButtonItem){ locationMode() }
    @IBAction func logoClick(sender: UIBarButtonItem) { logoMode() }
    
    func setFeaturestate(myButton: UIBarButtonItem) {
        //hasAlreadyStarted = true
        clearAllButtons()
        myButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: UIControlState())
    }
    func clearAllButtons() {
        self.capturedImage.image = nil
        //textButton.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "Arial", size: 14)!], forState: UIControlState.Normal)
        objectButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
        textButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
        colorButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
        burstButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
        faceButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
        locationButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
        logoButton.setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.grayColor()], forState: UIControlState())
    }
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                stateChanged(modeDirection.right)
            case UISwipeGestureRecognizerDirection.Left:
                stateChanged(modeDirection.left)
            //case UISwipeGestureRecognizerDirection.Up:   print("Swiped up")
            //case UISwipeGestureRecognizerDirection.Down: print("Swiped down")
            default:
                break
            }
        }
    }
    
    func stateChanged(modeChangeDirection: modeDirection) {
        hasAlreadyStarted = true // stops the welcome mesage text output
        if modeChangeDirection == .right {
            if self.searchSetting == .location {
                self.searchSetting = searchTypes.object
            } else {
                self.searchSetting = searchTypes(rawValue: self.searchSetting.rawValue + 1)!
            }
        } else{
            if self.searchSetting == .object {
                self.searchSetting = searchTypes.location
            } else {
                self.searchSetting = searchTypes(rawValue: self.searchSetting.rawValue - 1)!
            }
        }
        switch self.searchSetting {
            case .object:   objectMode()
            case .text:     textMode()
            case .color:    colorMode()
            case .burst:    burstMode()
            case .face:     faceMode()
            case .location: locationMode()
            case .logo:     logoMode()
            break
        }
    }
    
    //* * * DDifferent features and modes * * *
    func objectMode() {
        setFeaturestate(self.objectButton)
        getFileFromLib_Outlet.hidden = false
        self.searchSetting = .object
        self.outputTextAndVoice("Objects", speechRate :0.42, textEnable : true)
    }
    func textMode() {
        setFeaturestate(self.textButton)
        getFileFromLib_Outlet.hidden = false
        self.searchSetting = .text
        self.outputTextAndVoice("Text", speechRate :0.42, textEnable : true)
    }
    func colorMode() {
        setFeaturestate(self.colorButton)
        getFileFromLib_Outlet.hidden = false
        self.searchSetting = .color
        self.outputTextAndVoice("Colors", speechRate :0.42, textEnable : true)
    }
    func faceMode() {
        setFeaturestate(self.faceButton)
        getFileFromLib_Outlet.hidden = false
        self.searchSetting = .face
        self.outputTextAndVoice("Faces", speechRate :0.42, textEnable : true)
    }
    func burstMode() {
        setFeaturestate(self.burstButton)
        getFileFromLib_Outlet.hidden = true
        self.searchSetting = .burst
        self.outputTextAndVoice("Burst mode", speechRate :0.42, textEnable : true)
    }
    func locationMode() {
        setFeaturestate(self.locationButton)
        getFileFromLib_Outlet.hidden = true
        self.searchSetting = .location
        self.outputTextAndVoice("Location and more...", speechRate :0.42, textEnable : true)
    }
    func logoMode() {
        setFeaturestate(self.logoButton)
        getFileFromLib_Outlet.hidden = false
        self.searchSetting = .logo
        self.outputTextAndVoice("Logos", speechRate :0.42, textEnable : true)
    }

    
    //* * * Delegates for Photo Library * * *
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    //func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        // need to change the isze of the image here
        //http://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
        dismissViewControllerAnimated(true, completion:{
            self.capturedImage.contentMode = .ScaleAspectFit
            self.capturedImage.image = chosenImage
            //self.cropAndSend(chosenImage)
            //self.sendImagePOST(chosenImage)
            self.visionAPIrequest(chosenImage)
        })
    }
   
    //* * * Take picture action * * *
    func takePhoto(){
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) == nil { return } // no Camera
        hasAlreadyStarted = true // stops the welcome mesage text output
        if self.busyWaiting == false {
            self.takePictureButton.enabled = false
            self.busyWaiting = true
            self.zoomImage.hidden = true
             if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
                //stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
                stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                    if (sampleBuffer != nil) {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            //let dataProvider = CGDataProvider(data: imageData!)
                        let dataProvider = CGDataProviderCreateWithCFData(imageData)
                        
            //var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
            //let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                        let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                        
                        //UIImageOrientationUp,            // default orientation
                        //UIImageOrientationDown,          // 180 deg rotation
                        //UIImageOrientationLeft,          // 90 deg CCW
                        //UIImageOrientationRight,         // 90 deg CW
                        //UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
                        //UIImageOrientationDownMirrored,  // horizontal flip
                        //UIImageOrientationLeftMirrored,  // vertical flip
                        //UIImageOrientationRightMirrored, // vertical flip
                        let myimage = UIImage(CGImage: cgImageRef!, scale: 1, orientation: UIImageOrientation.Right)
                        self.capturedImage.image = myimage
                        //UIImageWriteToSavedPhotosAlbum(myimage, nil, nil, nil); //Save image
                        self.visionAPIrequest(myimage)

                        // temp ......
                        self.takePictureButton.enabled = true
                        self.busyWaiting = false
                        self.zoomImage.hidden = false
                        self.myTextLabel.text = ""
                        //self.outputTextAndVoice(". . .", speechRate :0.47, textEnable : true)
                    }
                })
            }
            
        }
    }

    //* * * Google Vision API request  * * *
    func visionAPIrequest(myimage: UIImage) {
        let binaryImageData = self.base64EncodeImage(myimage)
        self.createRequest(binaryImageData)
    }
    func base64EncodeImage(image: UIImage) -> String {
        self.imgH = image.size.height
        self.imgW = image.size.width
        
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.length > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSizeMake(800, oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedStringWithOptions(.EncodingEndLineWithCarriageReturn)
    }
    func resizeImage(imageSize: CGSize, image: UIImage) -> NSData {
        UIGraphicsBeginImageContext(imageSize)
        image.drawInRect(CGRectMake(0, 0, imageSize.width, imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    func createRequest(imageData: String) {
        // Create our request URL
        let request = NSMutableURLRequest(
            URL: NSURL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(API_KEY)")!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(
            NSBundle.mainBundle().bundleIdentifier ?? "",
            forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        
        // Build our API request
        let jsonRequest: [String: AnyObject]
        switch self.searchSetting {
        case .object:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "LABEL_DETECTION", "maxResults": 3]  //Execute Image Content Analysis on the entire image
                    ]
                ]
            ]
        case .text:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "TEXT_DETECTION", "maxResults": 1]
                    ]
                ]
            ]
        case .color:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "IMAGE_PROPERTIES", "maxResults": 3 ]
                    ]
                ]
            ]
        case .burst:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "LABEL_DETECTION",    "maxResults": 10 ]
                    ]
                ]
            ]
        case .face:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "FACE_DETECTION",     "maxResults": 10 ]
                    ]
                ]
            ]
        case .logo:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "LOGO_DETECTION",     "maxResults": 3 ]
                    ]
                ]
            ]
        case .location:
            jsonRequest = [
                "requests": [
                    "image": [ "content": imageData],
                    "features": [
                        [ "type": "LANDMARK_DETECTION", "maxResults": 10 ]
                    ]
                ]
            ]
            break
        }
        // Serialize the JSON
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonRequest, options: [])
      
        // Run the request on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.runRequestOnBackgroundThread(request)
        });
        
    }
    func runRequestOnBackgroundThread(request: NSMutableURLRequest) {
        let session = NSURLSession.sharedSession()
        
        // run the request
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print(".......................................")
            print(response)
            print(error)
           
            self.analyzeResults(data!)
        })
        task.resume()
    }
    func analyzeResults(dataToParse: NSData) {
        // Update UI on the main thread
        dispatch_async(dispatch_get_main_queue(), {
            //self.takePictureButton.enabled = true
            //self.busyWaiting = false
            //self.zoomImage.hidden = false
            
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"] // Use SwiftyJSON to parse results
            
            if (errorObj.dictionaryValue != [:]) { // Check for errors
                //!! make error more freindly
                self.outputTextAndVoice("Error code \(errorObj["code"]): \(errorObj["message"])", speechRate :0.40, textEnable : true)
            } else { // Parse the response
                print(json)
                var labelResultsText:String = ""
                let responses: JSON = json["responses"][0]
                var labels: Array<String> = []
                var text_annotations = false
                var face_annotations = false
                
                
               
                //---  Get face annotations --------------------------------------------------------
                let faceAnnotations: JSON = responses["faceAnnotations"]
                let numPeopleDetected:Int = faceAnnotations.count
                if numPeopleDetected > 0 {
                    face_annotations = true
                    if numPeopleDetected == 1 {
                        labels.append("One face. ")
                    } else {
                        labels.append("\(numPeopleDetected) faces. ")
                    }
                    
                    let emotions: Array<String> = [ "joy", "sorrow", "surprise", "anger", "headwear"]
                    var facenumber = 1
                    var face_pos_text = ""
                    var face_emotion_text = ""
                    var face_headwear_text = ""
                    for index in 0..<numPeopleDetected {
                        let personData:JSON = faceAnnotations[index]
  
                        //Get face position
                        let faceLandmarks = personData["landmarks"]
                        let faceLandmarksCounts:Int = faceLandmarks.count
                        for fLandmark in 0..<faceLandmarksCounts {
                           
                            if faceLandmarks[fLandmark]["type"].stringValue == "MIDPOINT_BETWEEN_EYES" {
                                let faceX = CGFloat(NSNumberFormatter().numberFromString(faceLandmarks[fLandmark]["position"]["x"].stringValue)!)
                                let faceY = CGFloat(NSNumberFormatter().numberFromString(faceLandmarks[fLandmark]["position"]["y"].stringValue)!)
                                
                                // -- get x --
                                var fPosX = ""
                                if faceX < self.imgW/3.4 {
                                    fPosX = "left"
                                } else if faceX > (self.imgW-(self.imgW/3.4)){
                                    fPosX = "right"
                                } else {
                                    fPosX = "middle"
                                }
                                
                                // -- get Y --
                                var fPosY = ""
                                if faceY < self.imgH/3.4 {
                                    fPosY = "top"
                                } else if faceY > (self.imgH-(self.imgH/3.4)){
                                    fPosY = "bottom"
                                  
                                } else {
                                    fPosY = "middle"
                                }
                              
                                //Get position on the screen
                                if fPosX == "left" && fPosY == "top" {
                                    face_pos_text = "is located on top left"
                                } else if  fPosX == "left" && fPosY == "middle"{
                                    face_pos_text = "is located on the left"
                                } else if  fPosX == "left" && fPosY == "bottom"{
                                    face_pos_text = "is located on bottom left"
                                } else if  fPosX == "right" && fPosY == "top"{
                                    face_pos_text = "is located on top right"
                                } else if  fPosX == "right" && fPosY == "bottom"{
                                    face_pos_text = "is located on bottom right"
                                } else if  fPosX == "right" && fPosY == "middle"{
                                    face_pos_text = "is located on the right"
                                } else if  fPosX == "middle" && fPosY == "top"{
                                    face_pos_text = "is located on the top"
                                } else if  fPosX == "middle" && fPosY == "bottom"{
                                    face_pos_text = "is located on the bottom"
                                } else if  fPosX == "middle" && fPosY == "middle"{
                                    face_pos_text = "is located in the middle"
                                } else {
                                    face_pos_text = ""
                                }
                            }
                        }
                        
                        //Get face emotion
                        for emotion in emotions {
                            let lookup = emotion + "Likelihood"
                            let result:String = personData[lookup].stringValue
                            if result=="VERY_LIKELY" || result=="LIKELY" || result=="POSSIBLE" {
                                switch emotion {
                                    case ("headwear"): face_headwear_text = "\"wears a headwear\""
                                    case ("joy"):      face_emotion_text = "and looks happy. "
                                    case ("sorrow"):   face_emotion_text = "and looks sad. "
                                    case ("surprise"): face_emotion_text = "and looks surprise. "
                                    case ("anger"):    face_emotion_text = "and looks angry. "
                                    default: break
                                }
                            }
                        }
                        let face_Output_text = "Face \(facenumber) \(face_pos_text) \(face_headwear_text) \(face_emotion_text)"
                        labels.append(face_Output_text)
                        facenumber = facenumber+1
                    }
                }
  
                
                //---  Get IMAGE_PROPERTIES annotations --------------------------------------------------------
                //http://gauth.fr/2011/09/get-a-color-name-from-any-rgb-combination/
                let imagePropertiesAnnotations: JSON = responses["imagePropertiesAnnotation"]
                let numColors: Int = imagePropertiesAnnotations["dominantColors"]["colors"].count
                print(numColors)
                if numColors > 0 {
                    for index in 0..<numColors {
                        let myColor = imagePropertiesAnnotations["dominantColors"]["colors"][index]
                        let scoreValue = CGFloat(NSNumberFormatter().numberFromString(myColor["score"].stringValue)!)
                        let redColor = CGFloat(NSNumberFormatter().numberFromString(myColor["color"]["red"].stringValue)!)
                        let greenColor = CGFloat(NSNumberFormatter().numberFromString(myColor["color"]["green"].stringValue)!)
                        let blueColor = CGFloat(NSNumberFormatter().numberFromString(myColor["color"]["blue"].stringValue)!)
                        if scoreValue > 0.1 {
                            print ("-----")
                            print ("red " + myColor["color"]["red"].stringValue)
                            print ("green " + myColor["color"]["green"].stringValue)
                            print ("blue " + myColor["color"]["blue"].stringValue)
                            let label = self.rgbToColorName(redColor, greenColor: greenColor, blueColor: blueColor)
                            labels.append(label)
                        }
                    }
                }
            
                //--- Get label annotations --------------------------------------------------------
                let labelAnnotations: JSON = responses["labelAnnotations"]
                let numLabels: Int = labelAnnotations.count
                if numLabels > 0 {
                    for index in 0..<numLabels {
                        let label = labelAnnotations[index]["description"].stringValue
                        labels.append(label)
                    }
                }
                
                //---  Get Logo annotations --------------------------------------------------------
                let logoAnnotations: JSON = responses["logoAnnotations"]
                let numLogos: Int = logoAnnotations.count
                if numLogos > 0 {
                    for index in 0..<numLogos {
                        let mylogo = logoAnnotations[index]["description"].stringValue
                        labels.append(mylogo)
                    }
                }
                
                //---  Get Landmark annotations --------------------------------------------------------
                let LandmarkAnnotations: JSON = responses["landmarkAnnotations"]
                let numLandmarks: Int = LandmarkAnnotations.count
                if numLandmarks > 0 {
                    for index in 0..<numLandmarks {
                        let mylandmark = LandmarkAnnotations[index]["description"].stringValue
                        labels.append(mylandmark)
                    }
                }
                
                //---  Get Text annotations ------------------------------------------------------------
                let textAnnotations: JSON = responses["textAnnotations"]
                let numTexts: Int = textAnnotations.count
                if numTexts > 0 {
                    for index in 0..<numTexts {
                        let mytext = textAnnotations[index]["description"].stringValue
                        if mytext.rangeOfString("\n") != nil{
                            //if mytext.range(of: "\n") != nil{
                                
                            labels.append(mytext)
                        }
                    }
                    text_annotations = true
                }
                
                //--- Out put text result --------------------------------------------------------------
                if labels.count > 0 {
                    //if text_annotations { labelResultsText = "Text: " } else{ labelResultsText = "I see " }
                    for labelraw in labels {
                        //Repalce line breaks with dot
                        let label1 = labelraw.stringByReplacingOccurrencesOfString("\\", withString: ". ")
                        let label = label1.stringByReplacingOccurrencesOfString("\\n", withString: ". ")
                        if text_annotations {
                            labelResultsText += "\(label)"
                        } else if face_annotations{
                            labelResultsText += "\(label)"
                        }else {
                            if labels.count == 1 {
                                labelResultsText += "\(label)"  // onlye one result
                            } else{
                                if labels[labels.count - 1] != label {
                                    labelResultsText += "\(label), "  // if it's not the last item add a comma
                                } else {
                                    labelResultsText += "and \(label)."
                                }
                            }
                        }
                    }
                    self.outputTextAndVoice(labelResultsText, speechRate :0.40, textEnable : true)
                }else{
                    self.outputTextAndVoice("Nothing found. Try again.", speechRate :0.40, textEnable : true)
                }
            }
        })
    }
    
    
    //* * * Welcome messages * * *
    func welcomeIntroNoCamera() {
        //self.takePictureButton.enabled = false
        //self.zoomImage.hidden = true
        self.myTextLabel.text = "Hello... "
        self.outputTextAndVoice("Hello, ... ", speechRate :0.50, textEnable : false)
        self.delay(1) {
            if self.hasAlreadyStarted==false {
                self.myTextLabel.text = "Point your phone in the direction that you would like to see..."
                self.outputTextAndVoice("Point your phone in the direction that you would like to see", speechRate :0.47, textEnable : false)
            }
            self.delay(2) {
                if self.hasAlreadyStarted==false {
                    self.myTextLabel.text = "...and tap on the screen."
                    self.outputTextAndVoice("and tap on the screen", speechRate :0.47, textEnable : false)
                }
                self.delay(1.9) {
                    if self.hasAlreadyStarted==false {
                        self.myTextLabel.text = "You can also swipe left and right for different options."
                        self.outputTextAndVoice("You can also swipe left and right for different options.", speechRate :0.47, textEnable : false)
                    }
                }
            }
        }
        
    }
    func welcomeIntroCamera() {
        //self.myTextLabel.text = "Hello... "
        //self.outputTextAndVoice("Hello", speechRate :0.50, textEnable : false)
        self.delay(1.8) {
            if self.hasAlreadyStarted==false {
                self.myTextLabel.text = "Point your phone in the direction that you would like to see..."
                self.outputTextAndVoice("Point your phone in the direction that you would like to see", speechRate :0.47, textEnable : false)
            }
            self.delay(2.9) {
                if self.hasAlreadyStarted==false {
                    self.myTextLabel.text = "...and tap on the screen."
                    self.outputTextAndVoice("and tap on the screen", speechRate :0.47, textEnable : false)
                }
                self.delay(1.9) {
                    if self.hasAlreadyStarted==false {
                        self.myTextLabel.text = "Swipe left and right for different options."
                        self.outputTextAndVoice("Swipe left and right for different options.", speechRate :0.47, textEnable : false)
                    }
                }
            }
        }
    }
    
    
    //* * * Delay function * * *
   // func delay(delay:Double, closure:()->()) {
   //     DispatchQueue.main.asyncAfter(
   //         deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
   // }
    //func delay1(delay:Double, closure:()->()) {
    //    DispatchQueue.main.after(
    //        when: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    //}
    
    func delay(delay: NSTimeInterval, block: dispatch_block_t) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), block)
    }
    
    //* * * Output text and Vocie * * *
    var synth = AVSpeechSynthesizer()
    func outputTextAndVoice (myText : String, speechRate : Float = 0.50, textEnable : Bool = true) {
        //enum AVSpeechBoundary : Int { case Immediate    case Word  }
        let mySpeechStoper = AVSpeechBoundary.Immediate
        //synth.stopSpeaking(at: mySpeechStoper)
        synth.stopSpeakingAtBoundary(mySpeechStoper)
        if textEnable {  self.myTextLabel.text = myText }
        var myUtterance = AVSpeechUtterance(string: "")
        myUtterance = AVSpeechUtterance(string: myText)
        //myUtterance.rate = speechRate + 0.1
        myUtterance.rate = 0.49
        myUtterance.voice = AVSpeechSynthesisVoice(language: "en-US") // IE
        //synth.speak(myUtterance)
        synth.speakUtterance(myUtterance)
    }
    
    
    
    //* * * color fucntions * * *
    func rgbToColorName(redColor : CGFloat, greenColor : CGFloat, blueColor : CGFloat) -> String {
   /*     let colorClass = ColorNames()
        let colorNames = colorClass.nameArray

        
        let rHex = String(format:"%02X", Int(redColor))
        let gHex = String(format:"%02X", Int(greenColor))
        let bHex = String(format:"%02X", Int(blueColor))
        let colorHex = "002E10" //rHex+gHex+bHex
        let myColorDec = UInt64(strtoul(colorHex, nil, 16))
        
        var colorOutput : String = ""
        for index in 0..<colorNames.count {
            let colorNameDec = UInt64(strtoul(colorNames[index][0], nil, 16))
            print ("__________________________")
            print(colorNameDec)
            print(myColorDec)
            
            if colorNameDec > myColorDec {
                break
            } else {
                colorOutput = colorNames[index][1]
            }
            
            //print (colorNames[index])
            //print (colorNames[index][0])
            /*
            let myHex = colorNames[index][0]
            let firstChar = myHex[myHex.startIndex.advancedBy(0)]
            let secondChar = myHex[myHex.startIndex.advancedBy(1)]
            let firstHext = "\(myHex[myHex.startIndex.advancedBy(0)])\(myHex[myHex.startIndex.advancedBy(1)])"
            let secondHex = "\(myHex[myHex.startIndex.advancedBy(2)])\(myHex[myHex.startIndex.advancedBy(3)])"
            let thirdHex  = "\(myHex[myHex.startIndex.advancedBy(4)])\(myHex[myHex.startIndex.advancedBy(5)])"
            let firstDec = UInt8(strtoul(firstHext, nil, 16))
            let secondDec = UInt8(strtoul(secondHex, nil, 16))
            let thirdDec = UInt8(strtoul(thirdHex, nil, 16))
            */
            
            
           // print ("--r")
           // print (firstDec)
           // print (UInt8(redColor))
           // print ("--g")
           // print (secondDec)
           // print (UInt8(greenColor))
           // print ("--b")
           // print (thirdDec)
           // print (UInt8(blueColor))
           // print("--")
            
           /* if UInt8(redColor) > firstDec {
                print("b1")
                continue
            } else {
                if UInt8(greenColor) > secondDec {
                    print("b2")
                    continue
                } else {
                    if UInt8(blueColor) > thirdDec {
                        print("b3")
                        continue
                    } else {
                         colorOutput = colorNames[index][1]
                        print (colorNames[index][0])
                        print (colorNames[index][1])
                    }
                }
            } */
            
        }
        print("--")
        print(redColor)
        print(greenColor)
        print(blueColor)
        
        print(colorOutput)
        */
        
      return "aaa" //colorOutput
        
    }
    
    
}







