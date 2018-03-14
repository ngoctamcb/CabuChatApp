//
//  RoomTableViewCell.swift
//  CabuChatApp
//
//  Created by Tam Tran on 3/12/18.
//  Copyright © 2018 Tam Tran. All rights reserved.
//

import UIKit

class RoomTableViewCell: UITableViewCell {

    @IBOutlet weak var lbRoomName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
