import UIKit
import AWSS3
import SwiftVideoGenerator

public struct ImageInfo {
    var image: UIImage
    var uploadKey: String = ""
    var url: String = ""
    
    init(image: UIImage) {
        self.image = image
    }
}

public struct VideoInfo {
    var url: String = ""
}

class UploadViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet weak var uploadVideoButton: UIButton!

    
    @IBAction func selectAndUpload(_ sender: UIButton) {
        self.uploadImages()
    }
    
    @IBAction func generateVideo(_ sender: Any) {
        videoFromImages()
    }
    @IBAction func uploadVideoAction(_ sender: Any) {
        uploadVideoFile()
    }
    
    @IBAction func addLogo(_ sender: UIButton) {
        applyLogoImage()
    }

    let bucketHost = "https://s3-us-west-2.amazonaws.com/booth36e1d9234676048918259805cfd637ee8-dev/"
    var imageCompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var videoCompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var progressBlock: AWSS3TransferUtilityProgressBlock?
    
    let imagePicker = UIImagePickerController()
    let transferUtility = AWSS3TransferUtility.default()

    var imagesInfo = [ImageInfo]()
    var videoInfo = VideoInfo()
    var videoFileURL: URL? = nil
    
    let nm = NetworkManager.sharedInstance
    var nUploadSuccesses = 0 // refactor using S3 Library
    
    func addCompletionHandlers() {
        self.imageCompletionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    print("Failed with error: \(error)")
                    self.statusLabel.text = "Failed"
                }
                else if(self.progressView.progress != 1.0) {
                    self.statusLabel.text = "Failed"
                    NSLog("Error: Failed - Likely due to invalid region / filename")
                }
                else {
                    self.nUploadSuccesses += 1
                    if self.nUploadSuccesses < self.imagesInfo.count { return }
                    
                    let urls = self.imagesInfo.map { $0.url }
                    let ps = PhotoStack(id: nil, urls: urls, userID: self.userID)
                    do {
                        try self.nm.postPhotoStack(photoStack: ps, callback: { photoStack in
                            self.nUploadSuccesses = 0
                        })
                    } catch {
                        print(error)
                    }
                }
            })
        }
    
        self.videoCompletionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    print("Failed with error: \(error)")
                    self.statusLabel.text = "Failed"
                }
                else if(self.progressView.progress != 1.0) {
                    self.statusLabel.text = "Failed"
                    NSLog("Error: Failed - Likely due to invalid region / filename")
                }
                else {
                    let vs = Video(id: nil, url: self.videoInfo.url, userID: self.userID)
                    do {
                        try self.nm.postVideo(video: vs, callback: { video in
                            
                        })
                    } catch {
                        print(error)
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // image key and url assignment
        for (i, _) in imagesInfo.enumerated() {
            imagesInfo[i].uploadKey = "public/\(userID)/\(UUID()).jpeg"
            imagesInfo[i].url = bucketHost + imagesInfo[i].uploadKey
        }
        
        progressView.progress = 0.0;
        statusLabel.text = "Ready"

        self.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                if (self.progressView.progress < Float(progress.fractionCompleted)) {
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
            })
        }
        addCompletionHandlers()
    }
    
    // MARK: Process Files
    
    func applyLogoImage() {
        let icon = UIImage(named: "hellobooth.png")!
        for (i, _) in imagesInfo.enumerated() {
            imagesInfo[i].image = imagesInfo[i].image.overlayWith(image: icon, posX: 520, posY: 1130) // need bottom edge view
        }
    }
    
    func videoFromImages() {
        let video = VideoFromImages(
            filename: "GravityGame.mov",
            size: CGSize(width: 720, height: 1280),
            success: { (url) -> Void in
                //Will run when video.finish() is called
                print("SUCCESS: Saved in local file  \(url)")
                print("SUCCESS: Video added to Photos Library")
                
                self.videoFileURL = URL(string: url.absoluteString!)
                DispatchQueue.main.async { [weak self] in
                    self?.uploadVideoButton.isHidden = false
                }
        },
            failure: { (error) -> Void in
                print(error)
        })
        video.start()
        let images = self.imagesInfo.map { $0.image }
        for (i, image) in images.enumerated() {
            video.addImage(image: image, frameLength: Int64(i*3))
        }
        
        video.finish()
    }
    
    // MARK: Upload Files
    
    func uploadImages() {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progressBlock
        DispatchQueue.main.async {
            self.statusLabel.text = ""
            self.progressView.progress = 0
        }
    
        for imageInfo in imagesInfo {
            guard let data = imageInfo.image.jpegData(compressionQuality: 1) else { return }
            transferUtility.uploadData(
                data,
                key: imageInfo.uploadKey,
                contentType: "image/jpeg",
                expression: expression,
                completionHandler: imageCompletionHandler).continueWith { (task) -> AnyObject? in
                    if let error = task.error {
                        print("Error: \(error.localizedDescription)")
                        
                        DispatchQueue.main.async {
                            self.statusLabel.text = "Failed"
                        }
                    }
                    if let _ = task.result {
                        DispatchQueue.main.async {
                            self.statusLabel.text = "Uploading..."
                            print("Upload Starting!")
                        }
                    }
                    return nil;
            }
        }
    }

    func uploadVideoFile() {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progressBlock
        DispatchQueue.main.async {
            self.statusLabel.text = ""
            self.progressView.progress = 0
        }
        guard let videoFileURL = videoFileURL else { return }
        var data: Data
        do { data = try Data(contentsOf: videoFileURL) } catch { return }
        
        let key = "public/\(userID)/\(UUID()).mov"
        videoInfo = VideoInfo(url: "\(bucketHost)\(key)")
        transferUtility.uploadData(
            data,
            key: key,
            contentType: "video/mp4",
            expression: expression,
            completionHandler: videoCompletionHandler).continueWith { (task) -> AnyObject? in
                if let error = task.error {
                    print("Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Failed"
                    }
                }
                if let _ = task.result {
                    DispatchQueue.main.async {
                        self.statusLabel.text = "Uploading..."
                        print("Upload Starting!")
                    }
                }
                return nil;
        }
    }
}

extension UploadViewController {
    var userID: Int {
        get {
            let storedObject: Data = UserDefaults.standard.object(forKey: kUserDefaultsKey) as! Data
            let storedUser: User = try! PropertyListDecoder().decode(User.self, from: storedObject)
            return storedUser.id
        }
    }
}
