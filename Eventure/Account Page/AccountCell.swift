//
//  AccountCell.swift
//  Eventure
//
//  Created by jeffhe on 2019/8/22.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//


import UIKit
import QuartzCore

class AccountCell: UITableViewCell {
    
    var functionImage: UIImageView!
    var function: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
        
        functionImage = {
            let iv = UIImageView()
            iv.translatesAutoresizingMaskIntoConstraints = false
            addSubview(iv)
            
            iv.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
            iv.widthAnchor.constraint(equalToConstant: 32).isActive = true
            iv.heightAnchor.constraint(equalTo: iv.widthAnchor).isActive = true
            iv.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            return iv
        }()
        
        function = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 17)
            label.numberOfLines = 3
            label.lineBreakMode = .byTruncatingTail
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            
            label.leftAnchor.constraint(equalTo: functionImage.rightAnchor, constant: 20).isActive = true
            label.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            return label
        }()
    }
    
    func setup(sectionNum: Int, rowNum: Int) {
        if (sectionNum == 0 && rowNum == 0) {
            functionImage = {
                let iv = UIImageView()
                iv.translatesAutoresizingMaskIntoConstraints = false
                iv.layer.cornerRadius = 20.0
                iv.
                clipsToBounds = true
                addSubview(iv)
                
                iv.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
                iv.widthAnchor.constraint(equalToConstant: 80).isActive = true
                iv.heightAnchor.constraint(equalTo: iv.widthAnchor).isActive = true
                iv.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                return iv
            }()
            functionImage.image = UIImage(named: "name")
            function.text = ""
        } else if (sectionNum == 1 && rowNum == 0) {
            functionImage.image = UIImage(named: "name")
            function.text = "Name"
        } else if (sectionNum == 1 && rowNum == 1) {
            functionImage.image = UIImage(named: "password")
            function.text = "Password"
        } else if (sectionNum == 1 && rowNum == 2) {
            functionImage.image = UIImage(named: "email")
            function.text = "Email"
        } else if (sectionNum == 1 && rowNum == 3) {
            functionImage.image = UIImage(named: "gender")
            function.text = "Gender"
        } else if (sectionNum == 3 && rowNum == 0) {
            functionImage.image = UIImage(named: "settings")
            if UserDefaults.standard.string(forKey: KEY_ACCOUNT_TYPE) == nil {
                function.text = "Sign In"
            } else {
                function.text = "Log Off"
            }
        } else {
            functionImage.image = UIImage(named: "done")
            function.text = String(rowNum)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

