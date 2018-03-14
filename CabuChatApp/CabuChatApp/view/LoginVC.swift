//
//  LoginVC.swift
//  CabuChatApp
//
//  Created by Tam Tran on 3/7/18.
//  Copyright © 2018 Tam Tran. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginVC: UIViewController {

    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        loadLocal()
        //set up textfield
        txtName.keyboardType = .emailAddress
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadLocal() {
        txtName.text =  UserDefaults.standard.string(forKey: "email")
        txtPassword.text =  UserDefaults.standard.string(forKey: "password")

    }
    
    
    
    @IBAction func btnLoginClicked(_ sender: Any) {
        if txtName.text != "" {
            Auth.auth().signIn(withEmail: txtName.text!, password: txtPassword.text!, completion: { (user, error) in
                if let error: Error = error {
                    print(error.localizedDescription)
                    return
                } else {
                    print(user?.email)
                    self.gotoRoomVC(uuid: (user?.uid)!, name: (user?.email)!)
                    self.saveLocal()
                    
                }
            })
        }
    }
    
    func saveLocal() {
        UserDefaults.standard.set(txtName.text, forKey: "email")
        UserDefaults.standard.set(txtPassword.text, forKey: "password")
    }
    
    func gotoRoomVC(uuid: String, name: String) {
        
        let rootNaVC: UIViewController = (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RoomNavVC") as? UINavigationController)!
        let roomVC = rootNaVC.childViewControllers.first as! RoomViewController
        roomVC.senderId = uuid
        roomVC.senderDisplayName = name
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = rootNaVC
        
    }
    
    @IBAction func btnRegisterClicked(_ sender: Any) {
        let registerVC = storyboard?.instantiateViewController(withIdentifier: "registerVC")
        self.present(registerVC!, animated: true, completion: nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showAlert(with message: String) {
        let alertController = UIAlertController(title: "Warning", message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
}
