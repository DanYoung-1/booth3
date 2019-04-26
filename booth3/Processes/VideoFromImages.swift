//
//  VideoFromImages.swift
//
//  Created by Alf Nielsen 29/11/2015
//  Copyright (c) 2015 Alf Nielsen. All rights reserved.
//
//  Base code comes from:
//  https://github.com/justinlevi/imagesToVideo/tree/master

import AVFoundation
import UIKit
import AssetsLibrary
import Photos

let kErrorDomain = "VideoFromImages"
let kFailedToStartAssetWriterError = 0
let kFailedToAppendPixelBufferError = 1

public class VideoFromImages: NSObject {
    
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    var startTime: TimeInterval!
    
    var size = CGSize(width: 320, height: 568)
    var error: NSError!
    var success: ((NSURL) -> Void)
    var failure: ((NSError) -> Void)
    var videoOutputURL: NSURL!
    var frameCount: Int64 = 0
    var filename: String = "";
    
    public init(filename: String, size: CGSize, success: @escaping ((NSURL) -> Void), failure: @escaping ((NSError) -> Void)) {
        self.filename = filename;
        self.size = size
        self.success = success
        self.failure = failure
        super.init()
    }
    ///Create the valid file (delete if exist!), and return the NSURL to the file.
    ///The file is created un the apps document root
    public func createVideoFile(filename: String){
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory: NSURL = urls.first! as NSURL else {
            fatalError("documentDir Error")
        }
        
        videoOutputURL = documentDirectory.appendingPathComponent(filename)! as NSURL
        
        if FileManager.default.fileExists(atPath: videoOutputURL.path!) {
            do {
                try FileManager.default.removeItem(atPath: videoOutputURL.path!)
            }catch{
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
    }
    ///Create the 3 writers that is needed to render video.
    public func createVideoWriters(){
        guard let _videoWriter = try? AVAssetWriter(outputURL: videoOutputURL as URL, fileType: AVFileType.mov) else{
            fatalError("AVAssetWriter error")
        }
        
        let outputSettings = [
            AVVideoCodecKey  : AVVideoCodecType.h264,
            AVVideoWidthKey  : NSNumber(value: Float(size.width)),
            AVVideoHeightKey : NSNumber(value: Float(size.height)),
            ] as [String : Any]
        
        guard _videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        
        let _videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        
        let sourcePixelBufferAttributesDictionary = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(size.height)),
            ]
        videoWriter = _videoWriter
        videoWriterInput = _videoWriterInput;
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary
        )
        videoWriter.add(videoWriterInput)
    }
    
    public func start(){
        startTime = NSDate.timeIntervalSinceReferenceDate
        createVideoFile(filename: filename);
        //create the videowriter elements
        createVideoWriters();
        
        assert(videoWriter.canAdd(videoWriterInput))
        
        if videoWriter.startWriting() {
            videoWriter.startSession(atSourceTime: CMTime.zero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: {})
        } else {
            error = NSError(domain: kErrorDomain, code: kFailedToStartAssetWriterError,
                            userInfo: ["description": "AVAssetWriter failed to start writing"]
            )
        }
        if let error = error {
            failure(error)
        }
        
    }
    
    public func addImage(image: UIImage, frameLength: Int64 ){
        let fps: Int32 = 24
        let frameDuration = CMTimeMake(value: frameLength, timescale: fps)
        while (!videoWriterInput.isReadyForMoreMediaData) {}
        print("\(videoWriterInput.isReadyForMoreMediaData) : \(frameCount)")
        let lastFrameTime = CMTimeMake(value: frameCount, timescale: fps)
        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
        if !self.appendPixelBufferForImage(image: image, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
            error = NSError(domain: kErrorDomain, code: kFailedToAppendPixelBufferError,
                            userInfo: [
                                "description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer",
                                "rawError": videoWriter.error ?? "(none)"
                ])
            
        }
        frameCount += 1
    }
    public func finish(){
        videoWriterInput.markAsFinished()
        videoWriter.finishWriting { () -> Void in
            if self.error == nil {
                UISaveVideoAtPathToSavedPhotosAlbum(self.videoOutputURL.path!, nil, nil, nil)
                //ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(self.videoOutputURL, completionBlock: nil)
                self.success(self.videoOutputURL)
            }
        }
    }
    
    public func appendPixelBufferForImageAtURL(urlString: String, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = true
        
        autoreleasepool {
            
            if let image = UIImage(contentsOfFile: urlString) {
                var pixelBuffer: CVPixelBuffer? = nil
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                
                if let pixelBuffer = pixelBuffer, status == 0 {
                    let managedPixelBuffer = pixelBuffer
                    
                    fillPixelBufferFromImage(image: image, pixelBuffer: managedPixelBuffer, contentMode: UIView.ContentMode.scaleAspectFit)
                    
                    appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    
                } else {
                    NSLog("error: Failed to allocate pixel buffer from pool")
                }
            }
        }
        
        return appendSucceeded
    }
    
    public func appendPixelBufferForImage(image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = true
        autoreleasepool {
            var pixelBuffer: CVPixelBuffer? = nil
            let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
            
            if let pixelBuffer = pixelBuffer, status == 0 {
                let managedPixelBuffer = pixelBuffer
                
                fillPixelBufferFromImage(image: image, pixelBuffer: managedPixelBuffer, contentMode: UIView.ContentMode.scaleAspectFit)
                
                appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                
            } else {
                NSLog("error: Failed to allocate pixel buffer from pool")
            }
        }
        return appendSucceeded
    }
    
    // http://stackoverflow.com/questions/7645454
    
    func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBuffer, contentMode:UIView.ContentMode){
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x: 0, y: 0, width: CGFloat(self.size.width), height: CGFloat(self.size.height)))
        
        let horizontalRatio = CGFloat(self.size.width) / image.size.width
        let verticalRatio = CGFloat(self.size.height) / image.size.height
   
        var ratio: CGFloat = 1
        
        switch(contentMode) {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        default:
            ratio = min(horizontalRatio, verticalRatio)
        }
        
        let newSize:CGSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        
        let x = newSize.width < self.size.width ? (self.size.width - newSize.width) / 2 : 0
        let y = newSize.height < self.size.height ? (self.size.height - newSize.height) / 2 : 0
        context?.draw(image.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
    
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let ms = Int((interval.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        if hours > 0 {
            return NSString(format: "%0.2d:%0.2d:%0.2d.%0.2d", hours, minutes, seconds, ms) as String
        }else if minutes > 0 {
            return NSString(format: "%0.2d:%0.2d.%0.2d", minutes, seconds, ms) as String
        }else {
            return NSString(format: "%0.2d.%0.2d", seconds, ms) as String
        }
    }
    
}

