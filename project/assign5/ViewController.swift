//
//  MenuController.swift
//  assign5
//
//  Created by William Thomas on 5/1/19.
//  Copyright © 2019 Eitan Prince. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var sideMenuConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeMessageTextView: UITextView!
    var sideMenuIsOpen = false
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleSideMenu),
            name: NSNotification.Name("ToggleSideMenu"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(removeWelcomeMessage),
            name: NSNotification.Name("removeWelcomeMessage"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showWelcomeMessage),
            name: NSNotification.Name("showWelcomeMessage"),
            object: nil)
        
        ref = Database.database().reference()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        /* if unique id is null then most likely the iphone was reset, or the user is running
            it for the first time; lets start them off with a username and unique id, then save them to DB */
        if UserDefaults.standard.string(forKey: "uniqueId") == nil || UserDefaults.standard.string(forKey: "userName") == nil {
            let alertController = UIAlertController(title: "Welcome!", message:
                "Please enter an anonymous chatroom name to get started!", preferredStyle: .alert)
            
            alertController.addTextField { (textField) in
                textField.placeholder = "Anonymous Name"
            }
            
            alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: {
                (action: UIAlertAction) in
                let chatroomNameTextField = alertController.textFields![0] as UITextField
                let username = chatroomNameTextField.text
                let uuid = UUID().uuidString
                UserDefaults.standard.set(username, forKey: "userName")
                UserDefaults.standard.set(uuid, forKey: "uniqueId")
                NotificationCenter.default.post(name: NSNotification.Name("setName"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("setDefaultImg"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("track"), object: nil)
            }))
            
            alertController.addAction(UIAlertAction(title: "Default", style: .default, handler: {
                (action: UIAlertAction) in
                let username = "Kevin The BEAST Durant"
                let uuid = UUID().uuidString
                UserDefaults.standard.set(username, forKey: "userName")
                UserDefaults.standard.set(uuid, forKey: "uniqueId")
                NotificationCenter.default.post(name: NSNotification.Name("setName"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("setKevinImg"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("track"), object: nil)
            }))
            self.present(alertController, animated: true, completion: nil)
            UserDefaults.standard.set("default", forKey: "chatroom")
        }
    }
    
    // Either displays or hides the side menu by adjusting the hamburgerMenu's horizontal constraint
    @objc func toggleSideMenu() {
        if(sideMenuIsOpen) {
            sideMenuConstraint.constant = 250
            sideMenuIsOpen = false
        }
        else {
            sideMenuConstraint.constant = 0
            sideMenuIsOpen = true
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
        NotificationCenter.default.post(name: NSNotification.Name("menuOpen"), object: nil)
    }
    
    @objc func removeWelcomeMessage() {
        welcomeMessageTextView.alpha = 0
    }
    
    @objc func showWelcomeMessage() {
        welcomeMessageTextView.alpha = 1
    }
}
