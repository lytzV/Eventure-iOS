//
//  Organization.swift
//  Eventure
//
//  Created by Jia Rui Shan on 2019/8/9.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit
import SwiftyJSON

class Organization: CustomStringConvertible {
    
    static var current: Organization? {
        didSet {
            if current?.writeToFile(path: CURRENT_USER_PATH) == false {
                print("WARNING: cannot write user to \(CURRENT_USER_PATH)")
            } else {
                print("successfully wrote user data to \(CURRENT_USER_PATH)")
            }
        }
    }
    
    var id: String
    var title: String
    var orgDescription: String
    var website: String
    var members = [Int: MemberRole]()
    var password_MD5: String
    var tags = Set<String>()
    var contactName: String
    var contactEmail: String
    var active: Bool
    var dateRegistered: String
    var logoImage: UIImage?
    var hasLogo: Bool
    var subscribers = Set<Int>()
    
    static var empty: Organization {
        return Organization(title: "")
    }
    
    /// Whether the app is in the middle of a sync session and is waiting for a response.
    static var waitingForSync = false
    
    /// Whether the changes made locally are yet to be uploaded.
    static var needsUpload = false
    
    init(title: String) {
        id = title
        self.title = title
        orgDescription = ""
        website = ""
        members = [:]
        password_MD5 = ""
        tags = []
        contactName = ""
        contactEmail = ""
        active = true
        dateRegistered = ""
        hasLogo = false
    }
    
    init(orgInfo: JSON) {
        let dictionary = orgInfo.dictionary!
        
        id = dictionary["ID"]?.string ?? ""
        title = dictionary["Title"]?.string ?? ""
        orgDescription = dictionary["Description"]?.string ?? ""
        website = dictionary["Website"]?.string ?? ""
        
        if let members_raw = dictionary["Members"]?.string {
            for pair in JSON(parseJSON: members_raw).dictionaryValue {
                members[Int(pair.key)!] = MemberRole(rawValue: pair.value.stringValue)
            }
        }
        
        if let tags_raw = dictionary["Tags"]?.string {
            let tagsArray = (JSON(parseJSON: tags_raw).arrayObject as? [String]) ?? [String]()
            tags = Set(tagsArray)
        } else {
            tags = []
        }
        
        password_MD5 = dictionary["Password MD5"]?.string ?? ""
        contactName = dictionary["Contact name"]?.string ?? ""
        contactEmail = dictionary["Email"]?.string ?? ""
        active = (dictionary["Active"]?.int ?? 1) == 1
        dateRegistered = dictionary["Date registered"]?.string ?? ""
        hasLogo = (dictionary["Has logo"]?.int ?? 0) == 1
        
        if let subscribers_raw = dictionary["Subscribers"]?.string {
            if let subArray = JSON(parseJSON: subscribers_raw).arrayObject as? [Int] {
                subscribers = Set(subArray)
            }
        }
    }
    
    var description: String {
        var str = "Organization \"\(String(describing: title))\":\n"
        str += "  id = \(String(describing: id))\n"
        str += "  website = \(String(describing: website))\n"
        str += "  tags = \(tags.description)\n"
        str += "  date registered = \(String(describing: dateRegistered))\n"
        str += "  # of subscribers = \(subscribers.count)"
        
        return str
    }
    
    static func cachedOrgAccount(at path: String) -> Organization? {
        if let data = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Data {
            guard let decrypted = NSData(data: data).aes256Decrypt(withKey: AES_KEY) else {
                print("WARNING: Cannot decrypt cached organization account data!")
                return nil
            }
            
            if let json = try? JSON(data: decrypted) {
                return Organization(orgInfo: json)
            }
        }
        
        return nil
    }
    
    func writeToFile(path: String) -> Bool {
        var json = JSON()
        json.dictionaryObject?["ID"] = self.id
        json.dictionaryObject?["Title"] = self.title
        json.dictionaryObject?["Description"] = self.orgDescription
        json.dictionaryObject?["Website"] = self.website
        
        var membersMap = [String : String]()
        for (key, value) in members {
            membersMap[String(key)] = value.rawValue
        }
        
        let membersEncoded = JSON(membersMap)
        json.dictionaryObject?["Members"] = membersEncoded.description
        
        json.dictionaryObject?["Tags"] = self.tags.description
        json.dictionaryObject?["Password MD5"] = self.password_MD5
        json.dictionaryObject?["Contact name"] = self.contactName
        json.dictionaryObject?["Email"] = self.contactEmail
        json.dictionaryObject?["Active"] = self.active ? 1 : 0
        json.dictionaryObject?["Date registered"] = self.dateRegistered
        json.dictionaryObject?["Has logo"] = self.hasLogo ? 1 : 0
        
        try? FileManager.default.createDirectory(at: ACCOUNT_DIR, withIntermediateDirectories: true, attributes: nil)
        
        let encrypted = NSData(data: try! json.rawData()).aes256Encrypt(withKey: AES_KEY)!
        return NSKeyedArchiver.archiveRootObject(encrypted, toFile: CURRENT_USER_PATH)
    }
    
    
    /// Sync the local organization account data with the server's.
    static func syncFromServer() {
        if Organization.current == nil { return }
        Organization.waitingForSync = true
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "account/GetOrgInfo",
                           parameters: ["orgId": String(Organization.current!.id)])!
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            Organization.waitingForSync = false
            
            guard error == nil else {
                print(error!)
                NotificationCenter.default.post(name: ORG_SYNC_FAILED, object: nil)
                return
            }
            
            if let json = try? JSON(data: data!) {
                Organization.current = Organization(orgInfo: json)
                NotificationCenter.default.post(name: ORG_SYNC_SUCCESS, object: nil)
            } else {
                print("WARNING: cannot parse '\(String(data: data!, encoding: .utf8)!)'")
                NotificationCenter.default.post(name: ORG_SYNC_FAILED, object: nil)
            }
        }
        
        task.resume()
    }
    
}


extension Organization {
    enum MemberRole: String {
        case member = "Member"
        case president = "President"
    }
}
