//
//  Chatroom.swift
//  assign5
//
//  Created by William Thomas on 5/3/19.
//  Copyright © 2019 Eitan Prince. All rights reserved.
//

import Foundation
import CoreLocation

/* We will define a Chatroom as having a name, group of Users, location, and owner (for deletion).
    Each chatroom will store it's messages to be displayed in the MessagingUI */
class Chatroom {
    var name: String
    var members = [String : String]()
    var location: CLLocation
    var chatMessages: [chatMessage] = []
    var owner: String?
    
    init(name: String, members: [String : String], location: CLLocation) {
        self.name = name
        self.members = members
        self.location = location
        self.owner = (UserDefaults.standard.string(forKey: "uniqueId"))
    }
}
