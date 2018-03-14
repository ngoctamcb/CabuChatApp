//
//  Room.swift
//  CabuChatApp
//
//  Created by Tam Tran on 3/12/18.
//  Copyright © 2018 Tam Tran. All rights reserved.
//

import Foundation

class Room: NSObject {
    
    var id: String = ""
    var name: String = ""
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
