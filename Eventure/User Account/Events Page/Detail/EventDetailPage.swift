//
//  EventDetailPage.swift
//  Eventure
//
//  Created by Jia Rui Shan on 2019/8/10.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class EventDetailPage: UIViewController {
    
    static let standardAttributes: [NSAttributedString.Key : Any] = {
        
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineSpacing = 5.0
        pStyle.paragraphSpacing = 12.0
        
        return [
            NSAttributedString.Key.paragraphStyle: pStyle,
            NSAttributedString.Key.foregroundColor: UIColor.darkGray,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.5),
            NSAttributedString.Key.kern: 0.2
        ]
    }()
    
    /// The event which the current view controller displays.
    var event: Event!
    
    var orgEventView: OrgEventViewController?
    
    private var hideBlankImages = true
    
    private var canvas: UIScrollView!
    private var coverImage: UIImageView!
    private var eventTitle: UILabel!
    private var rightButton: UIBarButtonItem!
    private var tabStrip: ButtonBarPagerTabStripViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Event Details"
        view.backgroundColor = .white
        
        if Organization.current == nil {
            rightButton = UIBarButtonItem(image: #imageLiteral(resourceName: "heart_empty"), style: .plain, target: self, action: #selector(changedFavoriteStatus))
            rightButton.isEnabled = User.current != nil
            navigationItem.rightBarButtonItem = rightButton
        } else if Organization.current?.id == event.hostID {
            rightButton = UIBarButtonItem(image: #imageLiteral(resourceName: "edit"), style: .plain, target: self, action: #selector(editEvent))
            navigationItem.rightBarButtonItem = rightButton
        }

        canvas = {
            let canvas = UIScrollView()
            canvas.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(canvas)
            canvas.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            canvas.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            canvas.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            canvas.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            canvas.contentInsetAdjustmentBehavior = .always
            
            return canvas
        }()
        
        
        coverImage = {
            let iv = UIImageView(image: event.eventVisual)
            if hideBlankImages && event.eventVisual == nil {
                iv.isHidden = true
            }
            iv.backgroundColor = MAIN_DISABLED
            iv.contentMode = .scaleAspectFill
            iv.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(iv)
            
            iv.topAnchor.constraint(lessThanOrEqualTo: canvas.topAnchor).isActive = true
            iv.widthAnchor.constraint(equalTo: iv.heightAnchor, multiplier: 1.5).isActive = true
            iv.centerXAnchor.constraint(equalTo: canvas.centerXAnchor).isActive = true
            iv.widthAnchor.constraint(lessThanOrEqualToConstant: 400).isActive = true
            let left = iv.leftAnchor.constraint(equalTo: canvas.safeAreaLayoutGuide.leftAnchor)
            left.priority = .defaultHigh
            left.isActive = true
            
            let right = iv.rightAnchor.constraint(equalTo: canvas.safeAreaLayoutGuide.rightAnchor)
            right.priority = .defaultHigh
            right.isActive = true
            
            return iv
        }()
        
        eventTitle = {
            let label = UILabel()
            label.numberOfLines = 10
            label.lineBreakMode = .byWordWrapping
            label.text = event.title
            label.font = .systemFont(ofSize: 20, weight: .semibold)
            label.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(label)
            
            label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
            label.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
            
            if coverImage.isHidden {
                label.topAnchor.constraint(equalTo: canvas.topAnchor, constant: 25).isActive = true
            } else {
                label.topAnchor.constraint(equalTo: coverImage.bottomAnchor, constant: 25).isActive = true
            }

            return label
        }()
        
        let line: UIView = {
            let line = UIView()
            line.backgroundColor = LINE_TINT
            line.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(line)
            
            line.leftAnchor.constraint(equalTo: eventTitle.leftAnchor).isActive = true
            line.topAnchor.constraint(equalTo: eventTitle.bottomAnchor, constant: 15).isActive = true
            line.widthAnchor.constraint(equalToConstant: 80).isActive = true
            line.heightAnchor.constraint(equalToConstant: 1).isActive = true
            
            return line
        }()
        
        /*eventDescription = {
            let tv = UITextView()
            tv.attributedText = event.eventDescription.attributedText()
            tv.textContainerInset = .zero
            tv.textContainer.lineFragmentPadding = 0
            tv.dataDetectorTypes = [.link, .phoneNumber]
            tv.linkTextAttributes[.foregroundColor] = LINK_COLOR
            tv.isEditable = false
            tv.isScrollEnabled = false
            tv.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(tv)
            
            tv.leftAnchor.constraint(equalTo: canvas.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
            tv.rightAnchor.constraint(equalTo: canvas.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
            tv.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 15).isActive = true
            tv.bottomAnchor.constraint(equalTo: canvas.bottomAnchor, constant: -40).isActive = true
            
            return tv
        }()*/
        
        
        tabStrip = {
            let tabStrip = EventDetailTabStrip(event : event)
            tabStrip.view.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(tabStrip.view)
            
            tabStrip.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            tabStrip.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            tabStrip.view.topAnchor.constraint(equalTo: line.bottomAnchor).isActive = true
            tabStrip.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            addChild(tabStrip)
            tabStrip.didMove(toParent: self)
            
            return tabStrip
        }()
        
    }
    
    @objc private func changedFavoriteStatus() {
        
        guard let currentUser = User.current else {
            return
        }
        
        // If the current user exists, then the right button is the favorite button
        
        let isFavoriteOriginally = currentUser.favoritedEvents.contains(event.uuid)
        
        func toggle(_ update: Bool = true) {
            if rightButton.image == #imageLiteral(resourceName: "heart_empty") {
                rightButton.image = #imageLiteral(resourceName: "heart")
            } else {
                rightButton.image = #imageLiteral(resourceName: "heart_empty")
            }
            if update {
                if isFavoriteOriginally {
                    currentUser.favoritedEvents.remove(event.uuid)
                } else {
                    currentUser.favoritedEvents.insert(event.uuid)
                }
            } else {
                if isFavoriteOriginally {
                    currentUser.favoritedEvents.insert(event.uuid)
                } else {
                    currentUser.favoritedEvents.remove(event.uuid)
                }
            }
        }
        
        toggle()
        
        let parameters = [
            "userId": String(currentUser.uuid),
            "eventId": event.uuid,
            "favorited": rightButton.image == #imageLiteral(resourceName: "heart") ? "1" : "0"
        ]
        
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "events/MarkEvent",
                           parameters: parameters)!
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    internetUnavailableError(vc: self) { toggle() }
                }
                return
            }
            
            let msg = String(data: data!, encoding: .utf8) ?? INTERNAL_ERROR
            
            if msg == INTERNAL_ERROR {
                DispatchQueue.main.async {
                    serverMaintenanceError(vc: self) { toggle() }
                }
            }
        }
        
        task.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.eventTitle.text = event.title
    }
    

    @objc private func editEvent() {
        let editor = EventDraft(event: event)
        editor.orgEventView = self.orgEventView
        editor.isEditingExistingEvent = true
        let nav = UINavigationController(rootViewController: editor)
        nav.navigationBar.tintColor = MAIN_TINT
        nav.navigationBar.barTintColor = .white
        nav.navigationBar.shadowImage = UIImage()
        present(nav, animated: true, completion: nil)
    }

}
