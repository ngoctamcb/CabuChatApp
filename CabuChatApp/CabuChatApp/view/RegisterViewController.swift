//
//  RegisterViewController.swift
//  CabuChatApp
//
//  Created by Tam Tran on 3/7/18.
//  Copyright © 2018 Tam Tran. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class RegisterViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtComfirmPassword: UITextField!
    
    private lazy var roomRef : DatabaseReference  = Database.database().reference().child("room")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
    }
    
    func createNewUser(id: String, name: String) {
        print(id)
        let newRoomRef = roomRef.child(id)
        let roomItem = [
            "name": name
        ]
        newRoomRef.setValue(roomItem)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnRegisterClicked(_ sender: Any) {
        Auth.auth().createUser(withEmail: txtEmail.text!, password: txtPassword.text!) { (user, error) in
            if let error: Error = error {
                print(error.localizedDescription)
                return
            }
            self.createNewUser(id: (user?.uid)!, name: (user?.email)!)
            self.dismiss(animated: true, completion: nil)
        }
    }

}
