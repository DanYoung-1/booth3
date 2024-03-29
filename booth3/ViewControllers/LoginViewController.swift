//
//  ViewController.swift
//  booth2
//
//  Created by Daniel Young on 3/26/19.
//  Copyright © 2019 Daniel Young. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func didSubmit(_ sender: UIButton) {
        
        if (!isValidEmail(email: emailTextField.text!)) {
            emailTextField.text = "invalid email"
            return
        }
        
        let email = emailTextField!.text!
        
        do {
            try nm.postUser(with: email, callback: { user in
                UserDefaults.standard.set(try! PropertyListEncoder().encode(user), forKey: kUserDefaultsKey)
                DispatchQueue.main.async {
                    let cvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
                    self.present(cvc, animated: false, completion: nil)
                }
            })
        } catch {
            print(error)
        }
    }
    
    let nm = NetworkManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 6
    }
}

extension LoginViewController {
    func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
