

import UIKit
import AWSS3
import AWSMobileClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        
        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            guard error == nil else {
                print("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            print("AWSMobileClient initialized.")
        }
        
        //provide the completionHandler to the TransferUtility to support background transfers.
        AWSS3TransferUtility.interceptApplication(application,
                                                  handleEventsForBackgroundURLSession: identifier,
                                                  completionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
