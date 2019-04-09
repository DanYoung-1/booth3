import UIKit
import AWSS3

public struct ImageInfo {
    let image: UIImage
    var uploadKey: String = ""
    var url: String = ""
    
    init(image: UIImage) {
        self.image = image
    }
}

class UploadViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!

    let bucketHost = "https://s3-us-west-2.amazonaws.com/booth36e1d9234676048918259805cfd637ee8-dev/"
    var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var progressBlock: AWSS3TransferUtilityProgressBlock?
    
    let imagePicker = UIImagePickerController()
    let transferUtility = AWSS3TransferUtility.default()

    var imagesInfo = [ImageInfo]()
    
    let nm = NetworkManager.sharedInstance
    var nUploadSuccesses = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for (i, _) in imagesInfo.enumerated() {
            imagesInfo[i].uploadKey = "public/\(userID)/\(UUID()).jpeg"
            imagesInfo[i].url = bucketHost + imagesInfo[i].uploadKey
        }
        
        progressView.progress = 0.0;
        statusLabel.text = "Ready"
        imagePicker.delegate = self

        self.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                if (self.progressView.progress < Float(progress.fractionCompleted)) {
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
            })
        }

        self.completionHandler = { (task, error) -> Void in
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
    }

    @IBAction func selectAndUpload(_ sender: UIButton) {
        self.uploadImages()
    }
    
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
                completionHandler: completionHandler).continueWith { (task) -> AnyObject? in
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

extension UploadViewController: UIImagePickerControllerDelegate {
    @objc public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if "public.image" == info[.mediaType] as? String {
            let image: UIImage = info[.originalImage] as! UIImage
            
        }
        dismiss(animated: true, completion: nil)
    }
}
