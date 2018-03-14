//
//  RoomViewController.swift
//  CabuChatApp
//
//  Created by Tam Tran on 3/7/18.
//  Copyright © 2018 Tam Tran. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class RoomViewController: UIViewController {
    
    @IBOutlet weak var RoomTableView: UITableView!
    var senderDisplayName: String = ""
    var senderId: String = ""
    
    private var roomRefHandle: DatabaseHandle?
    private var users: [Room] = []
    
    private lazy var roomRef : DatabaseReference  = Database.database().reference().child("room")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        RoomTableView.delegate = self
        RoomTableView.dataSource = self
        observeListUsers()
        
        // Do any additional setup after loading the view.
    }
    
    func observeListUsers() {
        roomRefHandle = roomRef.observe(.childAdded, with: { (snapshot) in
            let roomData = snapshot.value as! Dictionary<String, Any>
            let id = snapshot.key
            if let name = roomData["name"] as! String! {
                if self.senderId != id {
                    self.users.append(Room(id: id, name: name))
                    self.RoomTableView.reloadData()
                }
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    @IBAction func btnClicked(_ sender: Any) {
        let chatVC = storyboard?.instantiateViewController(withIdentifier: "chatVC")
        self.navigationController?.pushViewController(chatVC!, animated: true)
    }
}

extension RoomViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let roomCell = tableView.dequeueReusableCell(withIdentifier: "RoomCell", for: indexPath) as! RoomTableViewCell
        roomCell.lbRoomName.text = users[indexPath.row].name
        return roomCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatVC = storyboard?.instantiateViewController(withIdentifier: "chatVC") as! ChatViewController
        chatVC.sendToId = users[indexPath.row].id
        chatVC.sendToName = users[indexPath.row].name
        chatVC.senderId = senderId
        chatVC.senderDisplayName = senderDisplayName
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
}
