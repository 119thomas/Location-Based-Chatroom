//
//  ViewController.swift
//  assign5
//
//  Created by Eitan Prince on 4/22/19.
//  Copyright © 2019 Eitan Prince. All rights reserved.
//

import UIKit
import Firebase

class MessagingUIController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {

    @IBOutlet weak var LeaveRoomButton: UIBarButtonItem!
    let menuVC = MenuController()
    
    // MARK: VARIABLES
    // reference to database
    var ref: DatabaseReference!
    var messages: [chatMessage] = []
    let model = Model()
    var chatroom = "default"
    
    let randomNum = Int.random(in: 0 ... 10000000)
    var user = UserDefaults.standard.string(forKey: "userName") ?? ""
    let cellId = "cellId"
    
    let inputField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let defaults = UserDefaults.standard
    
    // MARK: METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        self.inputField.becomeFirstResponder()
        
        // observe when a chatroom is joined
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(switchChatroom),
            name: NSNotification.Name("switchChatroom"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(leaveRoom),
            name: NSNotification.Name("appClosed"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(makeFirstResponder),
            name: NSNotification.Name("FirstResponder"),
            object: nil)
        
        self.LeaveRoomButton.isEnabled = false
        self.LeaveRoomButton.tintColor = UIColor.red.withAlphaComponent(0)
        
        // sets the reference to the database
        ref = Database.database().reference()
        user = UserDefaults.standard.string(forKey: "userName") ?? "anon\(randomNum)"
        
        collectionView?.register(MessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 90, right: 0)
        collectionView?.keyboardDismissMode = .interactive
        
        self.inputField.delegate = self
        
        setupKeyboardListener()
        listenForMessages()
    }
    
    @objc private func switchChatroom() {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleSideMenu"), object: nil)
        let chatroomName = UserDefaults.standard.string(forKey: "chatroom") ?? "default"
        
        // check if we are switching to the default chatroom (on app start)
        if chatroomName == "default" {
            self.LeaveRoomButton.isEnabled = false
            self.LeaveRoomButton.tintColor = UIColor.red.withAlphaComponent(0)
            self.navigationItem.title = ""
            NotificationCenter.default.post(name: NSNotification.Name("showWelcomeMessage"), object: nil)
        }
        else {
            self.LeaveRoomButton.isEnabled = true
            self.LeaveRoomButton.tintColor = UIColor.red
            self.navigationItem.title = chatroomName
            NotificationCenter.default.post(name: NSNotification.Name("removeWelcomeMessage"), object: nil)
        }
        
        chatroom = chatroomName
        self.messages = []
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
        listenForMessages()
    }
    
    private func setupCell(_ cell: MessageCell, _ message: chatMessage) {
        if message.name == self.user {
            cell.bubbleView.backgroundColor = UIColor.init(red:0.25, green:0.88, blue:0.82, alpha:1.0)
            cell.textView.textColor = UIColor.white
            cell.profileNameHeightAnchor?.constant = 20
            cell.profileName.text = ""
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        } else {
            cell.bubbleView.backgroundColor = UIColor.init(red:0.94, green:0.94, blue:0.94, alpha:1.0)
            cell.textView.textColor = UIColor.black
            cell.profileName.text = message.name
            cell.profileName.textColor = UIColor.black
            cell.profileNameHeightAnchor?.constant = 20
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    private func estimateFrame(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(
            with: size,
            options: options,
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0)],
            context: nil
        )
    }
    
    func listenForMessages() {
        self.ref.child("chatrooms/\(chatroom)/messages").observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let data = dictionary
                let msg = data["message"] as? String
                let name = data["name"] as? String
                let chatMsg = chatMessage(msg!,name!)
              
                self.messages.append(chatMsg)
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
                self.scrollToBottom()
            }
        })
    }
    
    @objc func handleSend() {
        if chatroom == "default" {
            let alertController = UIAlertController(title: "You are not currently in a Chatroom", message: "Please create or join one from the menu.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true)
        }
        else {
            let msg: String! = inputField.text
            if msg != "" {
                model.createMessage(message: msg, ref: self.ref, name: user, chatRoomId: chatroom)
                self.inputField.text = nil
            }
        }
    }
    
    private func scrollToBottom() {
        let lastSectionIndex = (collectionView?.numberOfSections)! - 1
        let lastItemIndex = (collectionView?.numberOfItems(inSection: lastSectionIndex))! - 1
        let indexPath = NSIndexPath(item: lastItemIndex, section: lastSectionIndex)
        
        collectionView!.scrollToItem(
            at: indexPath as IndexPath,
            at: UICollectionView.ScrollPosition.bottom,
            animated: true)
    }
    
    var containterViewBottomAnchor: NSLayoutConstraint?
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 10, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        //Send Button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        //Send Button constraints
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //Input Field
        containerView.addSubview(self.inputField)
        
        //Input Field constraints
        self.inputField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //Line separator
        let viewLine = UIView()
        viewLine.backgroundColor = UIColor.init(red:0.86, green:0.86, blue:0.86, alpha:1.0)
        viewLine.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(viewLine)
        
        //Line separator constraints
        viewLine.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        viewLine.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        viewLine.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        viewLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func makeFirstResponder() {
        self.becomeFirstResponder()
        user = UserDefaults.standard.string(forKey: "userName") ?? user
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func setupKeyboardListener() {
        NotificationCenter.default.addObserver(self,selector: #selector(handleKeyboardWillShow),name: UIResponder.keyboardWillShowNotification,object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(handleKeyboardWillHide),name: UIResponder.keyboardWillHideNotification,object: nil)
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        containterViewBottomAnchor?.constant = -keyboardFrame.height+35
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
        containterViewBottomAnchor?.constant = 0
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func leaveRoom() {
        let alertController = UIAlertController(title: "Are you sure you want to leave?", message: nil, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            // remove from DB and chatroom
            let senderId:[String : String] = ["chatroomName": self.chatroom]
            NotificationCenter.default.post(name: NSNotification.Name("leave"), object: nil, userInfo: senderId)
            self.LeaveRoomButton.isEnabled = false
            self.LeaveRoomButton.tintColor = UIColor.red.withAlphaComponent(0)
            self.messages = []
            self.chatroom = "default"
            UserDefaults.standard.set("default", forKey: "chatroom")
            self.navigationItem.title = ""
            NotificationCenter.default.post(name: NSNotification.Name("showWelcomeMessage"), object: nil)
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
        
        let noAction = UIAlertAction(title: "No", style: .default, handler: nil)
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.present(alertController, animated: true)
    }
    
    // MARK: COLLECTIONVIEW DELEGATES
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessageCell
        let message = messages[indexPath.item]
        cell.textView.text = message.message
        setupCell(cell, message)
        cell.bubbleWidthAnchor?.constant = estimateFrame(text: message.message).width + 35
        cell.profileNameWidthAnchor?.constant = estimateFrame(text: message.message).width + 120
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = messages[indexPath.item].message
        let height = estimateFrame(text: text).height + 15
        let width = view.safeAreaLayoutGuide.layoutFrame.size.width
        return CGSize(width: width, height: height)
    }
    
    // MARK: ACTIONS
    @IBAction func MenuButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleSideMenu"), object: nil)
    }
    
    @IBAction func LeaveRoomButtonPressed(_ sender: UIBarButtonItem) {
        leaveRoom()
    }
    
    @IBAction func ChangeName(_ sender: Any) {
        let alertController = UIAlertController(title: "Anonymous Name", message:
            "Please enter an anonymous name for your chat.", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Anonymous Name"
        }
        
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: {
            (action: UIAlertAction) in
            let anonName = alertController.textFields![0] as UITextField

            self.defaults.set(anonName.text, forKey: "name")
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        
        self.present(alertController, animated: true, completion: nil)
    }
}
