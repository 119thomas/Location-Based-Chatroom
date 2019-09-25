//
//  MessageCell.swift
//  assign5
//
//  Created by Jeffrey Mercedes on 5/4/19.
//  Copyright © 2019 Eitan Prince. All rights reserved.
//

import UIKit

class MessageCell: UICollectionViewCell {
    let textView: UITextView = {
        let tv = UITextView()
        tv.text = ""
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = UIColor.clear
        return tv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(red:0.25, green:0.88, blue:0.82, alpha:1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        return view
    }()
    
    let profileName: UITextView = {
        let name = UITextView()
        name.text = "Temp Name"
        name.font = UIFont.systemFont(ofSize: 10)
        name.translatesAutoresizingMaskIntoConstraints = false
        name.textColor = UIColor.black
        name.backgroundColor = UIColor.clear
        return name
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var profileNameWidthAnchor: NSLayoutConstraint?
    var profileNameHeightAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileName)
        
        profileName.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        profileName.bottomAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        profileName.leftAnchor.constraint(equalTo: self.rightAnchor, constant: 8)
        profileNameHeightAnchor = profileName.heightAnchor.constraint(equalToConstant: 20)
        profileNameHeightAnchor?.isActive = true
        profileNameWidthAnchor = profileName.widthAnchor.constraint(equalToConstant: 200)
        profileNameWidthAnchor?.isActive = true

        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleViewRightAnchor?.isActive = true
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8)
        bubbleView.topAnchor.constraint(equalTo: profileName.bottomAnchor).isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: profileName.bottomAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
