//
//  OtherViewController.swift
//  Eventure
//
//  Created by appa on 8/23/19.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class OtherViewController: UIViewController, IndicatorInfoProvider {
    
    var event: Event!
    var detailPage: EventDetailPage!
    
    private var canvas: UIScrollView!
    private var hostLabel: UILabel!
    private var hostLink: UIButton!
    
    private var locationLabel: UILabel!
    private var locationText: UILabel!

    required init(detailPage: EventDetailPage) {
        super.init(nibName: nil, bundle: nil)
        
        self.event = detailPage.event
        self.detailPage = detailPage
        view.backgroundColor = detailPage.view.backgroundColor
        
        event.fetchHostInfo { org in
            print(org)
        }
        
        canvas = {
            let canvas = UIScrollView()
            canvas.alwaysBounceVertical = true
            canvas.contentInsetAdjustmentBehavior = .always
            canvas.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(canvas)
            
            canvas.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            canvas.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            canvas.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            canvas.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            return canvas
        }()
        
        
        hostLabel = {
            let label = UILabel()
            label.text = "Host: "
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(label)
            
            label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
            label.topAnchor.constraint(equalTo: canvas.topAnchor, constant: 35).isActive = true
            
            return label
        }()
        
        hostLink = {
            let button = UIButton(type: .system)
            button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .right
            button.setTitle(event.hostTitle, for: .normal)
            button.setTitleColor(LINK_COLOR, for: .normal)
            button.contentHorizontalAlignment = .right
            button.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(button)
            
            button.leftAnchor.constraint(equalTo: hostLabel.rightAnchor, constant: 15).isActive = true
            button.titleLabel?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
            button.titleLabel?.topAnchor.constraint(equalTo: hostLabel.topAnchor).isActive = true
            
            button.addTarget(self, action: #selector(openOrganization), for: .touchUpInside)
            
            return button
        }()
        
        locationLabel = {
            let label = UILabel()
            label.text = "Location: "
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(label)
            
            label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
            label.topAnchor.constraint(equalTo: hostLink.bottomAnchor, constant: 15).isActive = true
            
            label.layoutIfNeeded()
            label.widthAnchor.constraint(equalToConstant: label.frame.width).isActive = true
            
            return label
        }()
        
        locationText = {
            let label = UILabel()
            label.textAlignment = .right
            label.numberOfLines = 0
            label.text = event.location
            label.font = .systemFont(ofSize: 17)
            label.textColor = .darkGray
            label.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(label)
            
            label.leftAnchor.constraint(equalTo: locationLabel.leftAnchor, constant: 10).isActive = true
            label.topAnchor.constraint(equalTo: locationLabel.topAnchor).isActive = true
            label.rightAnchor.constraint(equalTo: hostLink.titleLabel!.rightAnchor).isActive = true
            
            return label
        }()
        
    }
    
    @objc private func openOrganization() {
        if let org = event.hostInfo {
            let info = OrgDetailPage(organization: org)
            info.hidesBottomBarWhenPushed = true
            detailPage.navigationController?.pushViewController(info, animated: true)
        } else {
            let alert = UIAlertController(title: "Organization info is still loading", message: "We are yet to fetch the information for the host organization \"\(event.hostTitle)\". Please try again later.", preferredStyle: .alert)
            alert.addAction(.init(title: "Dismiss", style: .cancel))
            detailPage.present(alert, animated: true)
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Detail")
    }
    
}
