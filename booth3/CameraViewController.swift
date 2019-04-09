//
//  CameraViewController.swift
//  booth3
//
//  Created by Daniel Young on 4/1/19.
//  Copyright © 2019 Daniel Young. All rights reserved.
//

import UIKit
import SwiftyCam
import Spring

class CameraViewController: SwiftyCamViewController, SwiftyCamViewControllerDelegate{
    
    @IBOutlet weak var buttonRect: UIView!
    
    let maxPhotoCount = 3
    var currentPhotoCount = 0
    
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureButton = SwiftyCamButton(frame: buttonRect.frame)
        captureButton.delegate = self
        cameraDelegate = self
        self.view.addSubview(captureButton)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        images.append(photo)
        currentPhotoCount += 1
        if currentPhotoCount >= maxPhotoCount {
            let uvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UploadViewController") as! UploadViewController
            for image in images {
                uvc.imagesInfo.append(ImageInfo(image: image))
            }
            self.present(uvc, animated: false, completion: nil)
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        // Called when a user initiates a tap gesture on the preview layer
        // Will only be called if tapToFocus = true
        // Returns a CGPoint of the tap location on the preview layer
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        // Called when a user initiates a pinch gesture on the preview layer
        // Will only be called if pinchToZoomn = true
        // Returns a CGFloat of the current zoom level
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        // Called when user switches between cameras
        // Returns current camera selection
    }
}

// MARK: SwiftyCamViewControllerDelegate Methods

extension CameraViewController {
    
}
