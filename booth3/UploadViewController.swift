import UIKit
import AWSS3

class UploadViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!

    let bucketHost = "https://s3.amazonaws.com/booth36e1d9234676048918259805cfd637ee8-dev/"
    var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var progressBlock: AWSS3TransferUtilityProgressBlock?
    
    let imagePicker = UIImagePickerController()
    let transferUtility = AWSS3TransferUtility.default()
    
    let nm = NetworkManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
                    self.statusLabel.text = "Success"
                    
                    let key = self.uploadKeyForImage
                    let url = self.bucketHost + key
                    let ps = PhotoStack(id: nil, urls: [url], userID: self.userID)
                    do {
                        try self.nm.postPhotoStack(photoStack: ps, callback: { photoStack in
                            print("photo stack uploaded ---- \n\n")
                        })
                    } catch {
                        print(error)
                    }
                }
            })
        }
    }

    @IBAction func selectAndUpload(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func uploadImage(with data: Data, key: String) {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = progressBlock

        DispatchQueue.main.async {
            self.statusLabel.text = ""
            self.progressView.progress = 0
        }
        
        transferUtility.uploadData(
            data,
            key: uploadKeyForImage,
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

extension UploadViewController {
    var uploadKeyForImage: String {
        get {
            return "public/\(userID)/\(UUID()).jpeg"      // PublicORPrivate / UserID / UUID .filetype
        }
    }
    var userID: Int {
        get {
            let storedObject: Data = UserDefaults.standard.object(forKey: kUserDefaultsKey) as! Data
            let storedUser: User = try! PropertyListDecoder().decode(User.self, from: storedObject)
            return storedUser.id
        }
    }
    
}

extension UploadViewController: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if "public.image" == info[.mediaType] as? String {
            let image: UIImage = info[.originalImage] as! UIImage
        self.uploadImage(with: image.jpegData(compressionQuality: 1)!, key: uploadKeyForImage)
        }
        dismiss(animated: true, completion: nil)
    }
}
