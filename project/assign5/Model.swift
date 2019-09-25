//
//  Model.swift
//  assign5
//
//  Created by Jeffrey Mercedes on 5/4/19.
//  Copyright © 2019 Eitan Prince. All rights reserved.
//

import Foundation
import Firebase

class chatMessage {
    var message: String
    var name: String
    
    init(_ newMessage: String, _ currName: String) {
        message = newMessage
        name = currName
    }
}

class Model {
    func createMessage(message: String, ref: DatabaseReference, name: String, chatRoomId: String) {
        let chat = [
            "name": name,
            "message": message,
            "chatRoomId": chatRoomId
        ]
        ref.child("chatrooms/\(chatRoomId)/messages/").childByAutoId().setValue(chat)
    }
}
