//
//  AboutViewController.swift
//  Eventure
//
//  Created by appa on 8/23/19.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class AboutViewController: UIViewController, IndicatorInfoProvider {

    var textView: UITextView!
    
    required init(text: String) {
        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .init(white: 0.92, alpha: 1)
        
        textView = {
            let tv = UITextView()
            tv.attributedText = text.attributedText()
            tv.textContainerInset = .init(top: 30, left: 30, bottom: 40, right: 30)
            tv.backgroundColor = .clear
            tv.dataDetectorTypes = [.link, .phoneNumber]
            tv.linkTextAttributes[.foregroundColor] = LINK_COLOR
            tv.isEditable = false
            tv.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(tv)
            
            tv.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
            tv.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
            tv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            
            let bottomConstraint = tv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            bottomConstraint.priority = .defaultHigh
            bottomConstraint.isActive = true
            
            return tv
        }()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "About")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}