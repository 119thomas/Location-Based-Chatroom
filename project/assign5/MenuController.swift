//
//  MenuController.swift
//  assign5
//
//  Created by William Thomas on 5/1/19.
//  Copyright © 2019 Eitan Prince. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase

class MenuController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: OUTLETS
    @IBOutlet weak var ChatroomsTableView: UITableView!
    @IBOutlet weak var LocationServicesToggle: UISwitch!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var radiusPickerView: UIPickerView!
    @IBOutlet weak var addChatroomButton: UIButton!
    @IBOutlet weak var profileNameTextView: UITextView!
    @IBOutlet weak var confirmNameChangeButton: UIButton!
    @IBOutlet weak var cancelNameChangeButton: UIButton!
    
    // MARK: VARIABLES
    var locationManager = CLLocationManager()
    var ref = Database.database().reference()
    var chatrooms = [Chatroom]()
    var chatroomsInRange = [Chatroom]()
    var newPicture: Bool?
    var canDelete = false
    var canEditRow = true
    var trackingLocation = false
    var currentRadius = 15
    let distances = [15, 30, 45, 60, 75,
                     90, 105, 120, 135, 150,
                     165, 180, 195, 210, 225,
                     240, 255, 270, 285, 300]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        ChatroomsTableView.delegate = self
        ChatroomsTableView.dataSource = self
        radiusPickerView.delegate = self
        radiusPickerView.dataSource = self
        
        // add functionality to change profile picture when it is tapped
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(changeProfilePicture))
        profilePictureImageView.isUserInteractionEnabled = true
        profilePictureImageView.addGestureRecognizer(singleTap)
        
        // chatroom button becomes a circle; glows on touch
        addChatroomButton.layer.cornerRadius = addChatroomButton.frame.width / 2
        addChatroomButton.showsTouchWhenHighlighted = true
        
        // confirm and cancel buttons for name editing should be off
        toggleConfirmCancelButtons(toggleOn: false)
        
        // display username; remove the scroll effect
        let userName = UserDefaults.standard.string(forKey: "userName")
        profileNameTextView.text = (userName == nil) ? "anonymous" : userName
        profileNameTextView.isScrollEnabled = false
        
        // Observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setNameFirstTime),
            name: NSNotification.Name("setName"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setDefaultImg),
            name: NSNotification.Name("setDefaultImg"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setKevinImg),
            name: NSNotification.Name("setKevinImg"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startTracking),
            name: NSNotification.Name("track"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setUserProfile),
            name: NSNotification.Name("menuOpen"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(leaveChatroom),
            name: NSNotification.Name("leave"),
            object: nil)
        
        /************************** TESTING BEGIN **************************/
        
        /* A few test locations; note: make sure to change the coordinates for
            your simulator! I'm using coordinates: lat = 38.9963, long = -76.9299 */
        
        // hershey park 90.2 miles
/*        let location1 = CLLocation(latitude: 40.285519, longitude: -76.650589)
        
        // six flags 10.5 miles
        let location2 = CLLocation(latitude: 38.9062, longitude: -76.77257)
        
        // virginia beach 155.0
        let location3 = CLLocation(latitude: 36.863140, longitude: -76.015778)
        
        // create a few Chatrooms
        let chatroom1 = Chatroom(name: "Hershey Park", members: [], location: location1)
        let chatroom2 = Chatroom(name: "Six Flags: America", members: [], location: location2)
        let chatroom3 = Chatroom(name: "Virginia Beach", members: [], location: location3)
        chatrooms.append(chatroom1)
        chatrooms.append(chatroom2)
        chatrooms.append(chatroom3)
*/
        /************************** TESTING END **************************/
    }
    
    // MARK: ACTIONS
    @IBAction func EditNameButtonPressed(_ sender: UIButton) {
        UserDefaults.standard.set(profileNameTextView.text, forKey: "userName")
        profileNameTextView.text = ""
        profileNameTextView.isEditable = true
        let newPosition = profileNameTextView.beginningOfDocument
        profileNameTextView.selectedTextRange = profileNameTextView.textRange(from: newPosition, to: newPosition)
        profileNameTextView.becomeFirstResponder()
        toggleConfirmCancelButtons(toggleOn: true)
    }
    
    @IBAction func confirmNameChangePressed(_ sender: UIButton) {
        let newUserName = profileNameTextView.text!
        UserDefaults.standard.set(newUserName, forKey: "userName")
        profileNameTextView.isEditable = false
        toggleConfirmCancelButtons(toggleOn: false)
    }
    
    @IBAction func cancelNameChangePressed(_ sender: UIButton) {
        profileNameTextView.text = UserDefaults.standard.string(forKey: "userName")
        profileNameTextView.isEditable = false
        toggleConfirmCancelButtons(toggleOn: false)
    }
    
    @IBAction func MenuBackButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("ToggleSideMenu"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("FirstResponder"), object: nil)
    }
    
    @IBAction func LocationServicesToggled(_ sender: UISwitch) {
        if sender.isOn {
            startTracking()
            trackingLocation = true
            updateChatroomsInRange(radius: currentRadius)
        }
        else {
            locationManager.stopUpdatingLocation()
            trackingLocation = false
            chatroomsInRange = []
            DispatchQueue.main.async{
                self.ChatroomsTableView.reloadData()
            }
        }
    }
    
    @IBAction func NewChatroomButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "New Chatroom", message:
            "Please enter a name for your chatroom", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Chatroom Name"
        }
        
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: {
            (action: UIAlertAction) in
            let chatroomName = alertController.textFields![0] as UITextField
            let chatroomLocation = self.locationManager.location
            let newChatroom = Chatroom(name: chatroomName.text!, members: [:], location: chatroomLocation!)
            
            if(!self.chatroomExists(chatroom: newChatroom) &&
                !self.localChatroomExists(chatroom: newChatroom)) {
                self.chatroomsInRange.append(newChatroom)
                self.chatrooms.append(newChatroom)
                
                /* save the new chatroom to Firebase */
                
                // save name
                self.ref.child("chatrooms/\(chatroomName.text!)/").setValue(chatroomName.text!)
                
                // save location
                self.ref.child("chatrooms/\(chatroomName.text!)/latitude/").setValue("\(chatroomLocation!.coordinate.latitude)")
                self.ref.child("chatrooms/\(chatroomName.text!)/longitude/").setValue("\(chatroomLocation!.coordinate.longitude)")
                
                // save owner
                self.ref.child("chatrooms/\(chatroomName.text!)/owner/").setValue("\(UserDefaults.standard.string(forKey: "uniqueId")!)")
                
                DispatchQueue.main.async{
                    self.ChatroomsTableView.reloadData()
                }
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: @objc METHODS
    
    /* this method is called the first time the user sets up the app. It sets the
        textfield to the name they chose on startup */
    @objc func setNameFirstTime() {
        profileNameTextView.text = UserDefaults.standard.string(forKey: "userName")
    }
    
    @objc func setKevinImg() {
        let kevin = UIImage(named: "kdProfilePicture")
        profilePictureImageView.image = kevin
    }
    
    @objc func setDefaultImg() {
        let defaultImage = UIImage(named: "anonymousProfilePicture")
        profilePictureImageView.image = defaultImage
    }
    
    @objc func setUserProfile() {
        if trackingLocation {
            LocationServicesToggle.setOn(true, animated: true)
            updateChatroomsInRange(radius: currentRadius)
        }
        else {
            LocationServicesToggle.setOn(false, animated: true)
        }
        
        self.profilePictureImageView.image = getProfilePicture()
    }
    
    @objc func changeProfilePicture() {
        let myAlert = UIAlertController(title: "Select Image From", message: "", preferredStyle: .actionSheet)
        myAlert.popoverPresentationController?.sourceView = self.view
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerController.SourceType.camera
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
                self.newPicture = true
            }
        }
        let cameraRollAction = UIAlertAction(title: "Camera Roll", style: .default) { (action) in
            if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
                self.newPicture = false
            }
        }
        let setAnonymousAction = UIAlertAction(title: "Set Anonymous", style: .default) { (action) in
            self.saveProfilePicture(image: UIImage(named: "anonymousProfilePicture")!, imageName: "profilePicture.jpg")
            self.profilePictureImageView.image = self.getProfilePicture()
            self.newPicture = false
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        myAlert.addAction(cameraAction)
        myAlert.addAction(cameraRollAction)
        myAlert.addAction(setAnonymousAction)
        myAlert.addAction(cancelAction)
        
        self.present(myAlert, animated: true)
    }
    
    @objc func imageError(image: UIImage, error: NSError, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(title: "Save Failed", message: "Failed to save image", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func joinChatroom(sender: UIButton) {
        let chatroomToBeJoined = chatroomsInRange[sender.tag]

        /* check to see if we are already in the chatroom */
        let currentChatroom = UserDefaults.standard.string(forKey: "chatroom")
        if currentChatroom == chatroomToBeJoined.name {
            return
        }
        
        // leave old chatroom
        let username = UserDefaults.standard.string(forKey: "userName")
        print("user name is currently \(username!)")
        let uuid = UserDefaults.standard.string(forKey: "uniqueId")
        self.ref.child("chatrooms/\(currentChatroom!)/members/\(uuid!)").removeValue()
        
        for chatroom in chatrooms {
            if chatroom.name == currentChatroom {
                let members = chatroom.members
                for member in members {
                    if member.key == uuid {
                        chatroom.members.removeValue(forKey: member.key)
                    }
                }
            }
        }
        
        // add user to DB & chatroom members array; save our current chatroom
        self.ref.child("chatrooms/\(chatroomToBeJoined.name)/members/\(uuid!)").setValue(username)
        chatroomToBeJoined.members[uuid!] = username!
        UserDefaults.standard.set(chatroomToBeJoined.name, forKey: "chatroom")
        
        // post notification to messagingUI to switch rooms
        NotificationCenter.default.post(name: NSNotification.Name("switchChatroom"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("FirstResponder"), object: nil)
        
        // update table view
        updateChatroomsInRange(radius: currentRadius)
    }
    
    /* Begin tracking our user or request permission to do so */
    @objc func startTracking() {
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            trackingLocation = true
            locationManager.startUpdatingLocation()
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /* removes the user from the specified chatroom DB & object array */
    @objc func leaveChatroom(notification: NSNotification) {
        if let chatroomName = notification.userInfo?["chatroomName"] as? String {
            let username = UserDefaults.standard.string(forKey: "userName")!
            for chatroom in chatrooms {
                if chatroomName == chatroom.name {
                    chatroom.members.removeValue(forKey: username)
                }
                
            }
            let uuid = UserDefaults.standard.string(forKey: "uniqueId")
            self.ref.child("chatrooms/\(chatroomName)/members/\(uuid!)").removeValue()
            DispatchQueue.main.async{
                self.ChatroomsTableView.reloadData()
            }
        }
    }
    
    // MARK: METHODS
    func requestLocationServices() {
        let alertController = UIAlertController(title: "Location Services", message:
            "Allow us to track your location?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: {
            (action: UIAlertAction) in
            self.trackingLocation = true
            self.locationManager.startUpdatingLocation()
            self.LocationServicesToggle.setOn(true, animated: true)
            self.updateChatroomsInRange(radius: self.currentRadius)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func convertMetersToMiles(meters: Double) -> Int {
        return Int(meters / 1609)
    }
    
    /* Chatrooms in range of each other should not have the same name */
    func chatroomExists(chatroom: Chatroom) -> Bool {
        for room in chatrooms {
            if room.name == chatroom.name {
                return true
            }
        }
        return false
    }
    
    func localChatroomExists(chatroom: Chatroom) -> Bool {
        for room in chatroomsInRange {
            if room.name == chatroom.name {
                return true
            }
        }
        return false
    }
    
    /* Find out which chatrooms are in range of the given radius & update the table view */
    func updateChatroomsInRange(radius: Int) {
        let mylocation = locationManager.location
        chatroomsInRange = []
        
        // retrieve and sync our chatrooms with the DB
        ref.child("chatrooms").observe(.value) { (snapshot) in
            if let dictionary = snapshot.value as? NSDictionary {
                
                // grab the chatroom data from firebase
                for chatroom in dictionary {
                    let chatroomName = chatroom.key as! String
                    if let roomDictionary = dictionary["\(chatroom.key)"] as? NSDictionary {
                        
                        var chatMembers = [String : String]()
                        let chatOwner = roomDictionary["owner"] as? String
                        
                        if let memberDictionary = roomDictionary["members"] as? NSDictionary {
                            for member in memberDictionary {
                                if let memberName = member.value as? String {
                                    let memberUniqueId = member.key as? String
                                    chatMembers[memberUniqueId!] = memberName
                                }
                            }
                        }
                        
                        let latitude = roomDictionary["latitude"] as! String?
                        let longitude = roomDictionary["longitude"] as! String?
                        
                        if(latitude != nil && longitude != nil) {
                            let lat = Double(latitude!); let long = Double(longitude!)
                            let location = CLLocation(latitude: lat!, longitude: long!)
                            let room = Chatroom(name: chatroomName, members: chatMembers, location: location)
                            room.owner = chatOwner
                            if(!self.chatroomExists(chatroom: room)) {
                                self.chatrooms.append(room)
                            }
                        }
                    }
                }
            }
        }
        
        for chatroom in chatrooms {
            let distance = mylocation?.distance(from: chatroom.location)
            if(convertMetersToMiles(meters: distance!) <= radius &&
                !localChatroomExists(chatroom: chatroom)) {
                chatroomsInRange.append(chatroom)
            }
        }
        DispatchQueue.main.async{
            self.ChatroomsTableView.reloadData()
        }
    }
    
    /* We will toggle on confirm and cancel buttons when editing username; off when finished */
    func toggleConfirmCancelButtons(toggleOn: Bool) {
        if toggleOn {
            confirmNameChangeButton.alpha = 1
            confirmNameChangeButton.isEnabled = true
            cancelNameChangeButton.alpha = 1
            cancelNameChangeButton.isEnabled = true
        }
        else {
            confirmNameChangeButton.alpha = 0
            confirmNameChangeButton.isEnabled = false
            cancelNameChangeButton.alpha = 0
            cancelNameChangeButton.isEnabled = false
        }
    }
    
    func getDirectoryPath() -> NSURL {
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("profilePicture.jpg")
        let url = NSURL(string: path)
        return url!
    }
    
    func saveProfilePicture(image: UIImage, imageName: String) {
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        if !fileManager.fileExists(atPath: path) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        let url = NSURL(string: path)
        let imagePath = url!.appendingPathComponent(imageName)
        let urlString: String = imagePath!.absoluteString
        let imageData = image.jpegData(compressionQuality: 1)

        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
    }
    
    func getProfilePicture() -> UIImage {
        let fileManager = FileManager.default
        let imagePath = (self.getDirectoryPath() as NSURL).appendingPathComponent("profilePicture.jpg")
        let urlString: String = imagePath!.absoluteString
        if fileManager.fileExists(atPath: urlString) {
            let image = UIImage(contentsOfFile: urlString)
            return image!
        }
        else {
            return UIImage(named: "anonymousProfilePicture")!
        }
    }
    
    // MARK: PICKERVIEW DELEGATES
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return distances.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(distances[row]) miles"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if LocationServicesToggle.isOn {
            currentRadius = distances[row]
            updateChatroomsInRange(radius: distances[row])
        }
        else {
            requestLocationServices()
        }
    }
    
    // MARK: IMAGEPICKER DELEGATES
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let newProfilePic = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        profilePictureImageView.image = newProfilePic
        
        /* save profile picture to documents */
        saveProfilePicture(image: newProfilePic, imageName: "profilePicture.jpg")
        
        /* new pictures taken from the camera need to be stored in the photo library */
        if newPicture == true {
            UIImageWriteToSavedPhotosAlbum(newProfilePic, self, #selector(imageError), nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: LOCATION DELEGATES
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateChatroomsInRange(radius: currentRadius)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startTracking()
    }
    
    // MARK: TABLEVIEW DELEGATES
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatroomsInRange.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        // create the Join button for the cell; joins specified chatroom on press
        let button = UIButton(frame: CGRect(x: (3.15 * cell.bounds.maxX) / 5, y: cell.bounds.maxY / 4, width: cell.bounds.maxX / 8, height: cell.bounds.maxY / 2))
        button.tag = indexPath.row
        button.backgroundColor = UIColor.green
        button.setTitle("Join", for: .normal)
        button.layer.cornerRadius = 2
        button.addTarget(self, action: #selector(joinChatroom), for: .touchUpInside)
        button.showsTouchWhenHighlighted = true
        
        // create a member label; tracks number members in each chatroom
        let label = UILabel(frame: CGRect(x: cell.bounds.maxX / 2, y: cell.bounds.maxY / 4, width: cell.bounds.maxX / 8, height: cell.bounds.maxY / 2))

        label.text = "👤\(chatroomsInRange[indexPath.row].members.count)"
        
        cell.contentView.addSubview(button)
        cell.contentView.addSubview(label)
        cell.textLabel?.text = chatroomsInRange[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let uuid = UserDefaults.standard.string(forKey: "uniqueId")
        let targetRoomOwner = self.chatroomsInRange[indexPath.row].owner
        
        if uuid == targetRoomOwner {
            return .delete
        }
        else {
            let alertController = UIAlertController(title: "Access Denied", message: "Only the owner may delete this chatroom.", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alertController.addAction(dismissAction)
            self.present(alertController, animated: true)
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let targetRoom = self.chatroomsInRange[indexPath.row].name
            let alertController = UIAlertController(title: "Delete Chatroom", message: "Are you sure you want to delete your chatroom?", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .default, handler: {
                (action: UIAlertAction) in
                self.ref.child("chatrooms/\(targetRoom)").removeValue()

                var index = 0
                for chatroom in self.chatrooms {
                    if chatroom.name == targetRoom {
                        self.chatrooms.remove(at: index)
                    }
                    index += 1
                }

                if UserDefaults.standard.string(forKey: "chatroom") == targetRoom {
                    UserDefaults.standard.set("default", forKey: "chatroom")
                    NotificationCenter.default.post(name: NSNotification.Name("switchChatroom"), object: nil)
                }
                else {
                    self.chatroomsInRange.remove(at: indexPath.row)
                    self.ChatroomsTableView.deleteRows(at: [indexPath], with: .fade)
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true)
        }
    }
}
