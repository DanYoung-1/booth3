//
//  CameraViewController.swift
//  booth3
//
//  Created by Daniel Young on 4/1/19.
//  Copyright © 2019 Daniel Young. All rights reserved.
//

import UIKit
import SwiftyCam


class CameraViewController: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    @IBOutlet weak var flashView: UIView!
    @IBOutlet weak var promptLabel: UILabel!
    
    let maxPhotoCount = 5
    var currentPhotoCount = 0
    
    var images = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultCamera = .front
        doubleTapCameraSwitch = false
        pinchToZoom = false
        let captureButton = SwiftyCamButton(frame: promptLabel.frame)
        captureButton.delegate = self
        cameraDelegate = self
        
        self.flashView.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPhotoSequence()
    }
    
    func flashScreen() {
        self.flashView.backgroundColor = .white
        UIView.animate(withDuration: 0.5) {
            self.flashView.backgroundColor = .clear
        }
    }
    
    func startPhotoSequence() {
        self.promptLabel.text = "Ready?"
        UIView.animate(withDuration: 2.0, delay: 0, options: .curveEaseIn, animations: {
            self.promptLabel.alpha = 0.0
        }) { (completed) in
            self.startCountDown()
        }
    }
    
    func startCountDown() {
        var count = 3
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if count > 0 {
                self.promptLabel.text = "\(count)"
                self.promptLabel.alpha = 1.0
                UIView.animate(withDuration: 1.0) {
                    self.promptLabel.alpha = 0.0
                }
                count -= 1
            } else {
                self.currentPhotoCount += 1
                timer.invalidate()
                self.flashScreen()
                self.takePhoto()
            }
        }
    }
    
    func presentUploadVC() {
        let uvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UploadViewController") as! UploadViewController
        uvc.imagesInfo = self.images.map { ImageInfo(image: $0) }
        self.present(uvc, animated: false, completion: nil)
    }
    
    // MARK: SwiftyCamViewControllerDelegate Methods
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        images.append(photo)
        if self.currentPhotoCount < self.maxPhotoCount {
            self.promptLabel.alpha = 1.0
            self.startPhotoSequence()
        } else {
            self.presentUploadVC()
        }
    }
}

    
