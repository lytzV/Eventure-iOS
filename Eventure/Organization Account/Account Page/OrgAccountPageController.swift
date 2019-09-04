//
//  OrgAccountPageController.swift
//  Eventure
//
//  Created by Prince Wang on 2019/8/31.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit

class OrgAccountPageController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var myTableView: UITableView!
    
    
    private var currentImageView: UIImageView!
    private var profilePicture: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Do any additional setup after loading the view.
        title = Organization.waitingForSync ? "Syncing..." : "Org Settings"
        view.backgroundColor = .init(white: 0.92, alpha: 1)
        
        myTableView = UITableView(frame: .zero, style: .grouped)
        myTableView.dataSource = self
        myTableView.delegate = self
        myTableView.backgroundColor = UIColor.init(white: 0.95, alpha: 1)
        self.view.addSubview(myTableView)
        
        
        //set location constraints of the tableview
        myTableView.translatesAutoresizingMaskIntoConstraints = false
        myTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        myTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        myTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        myTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(orgUpdated), name: ORG_SYNC_SUCCESS, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orgUpdated), name: ORG_SYNC_FAILED, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.performWithoutAnimation {
            self.myTableView.beginUpdates()
            self.myTableView.endUpdates()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// New account data has been synced from the server and are reflected in the new `Organization.current` instance. Make appropriate changes to the dashboard page accordingly, e.g. reload certain row cells.
    @objc private func orgUpdated() {
        DispatchQueue.main.async {
            self.title = "Org Settings"
            self.navigationController?.navigationBar.setNeedsDisplay()
            UIView.performWithoutAnimation {
                print("function incomplete")
            }
        }
    }
    
    //when table view is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        //Write for cases for all cells on the page
        switch (indexPath.section, indexPath.row) {
            
        case (1,0): //if the user tries to change account information
            let orgInfo = OrgSettingInfoPage()
            orgInfo.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(orgInfo, animated: true)
        case (1,1):
            print(indexPath)

            let orgProfile = OrgProfilePage()
            orgProfile.parentVC = self
            orgProfile.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(orgProfile, animated: true)
        case (2, 0):
            let orgEvent = OrgEventBriefPage()
            orgEvent.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(orgEvent, animated: true)
        case (2, 1):
            print(indexPath)
            //commented for TEST
//            let subscriber = SubscriberListPage()
//            subscriber.hidesBottomBarWhenPushed = true
//            navigationController?.pushViewController(subscriber, animated:true)
        case(3, 0):
            let aboutPage = AboutEventure()
            aboutPage.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(aboutPage, animated: true)
        case (3,1):
            //if the log out/sign in button is clicked
            //Note: Do not need to imeplement the case where Organization.current == nil
            //because we have already logged in for Org
            let alert = UIAlertController(title: "Do you want to log out?", message: "Changes you've made have been saved.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { action in
                UserDefaults.standard.removeObject(forKey: KEY_ACCOUNT_TYPE)
                Organization.current = nil
                MainTabBarController.current.openScreen()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true)
        default:
            break
        }
        
    }

    
    //create a cell for each table view row
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = SettingsItemCell()
        
        switch (indexPath.section, indexPath.row) {
        
        
            
        case (0, 0):
            cell.icon.image = Organization.current?.logoImage
            if cell.icon.image == nil {
                cell.icon.image = #imageLiteral(resourceName: "group")
            }
            cell.imageWidthConstraint.constant = 65
            cell.heightConstraint.constant = 100
            cell.spacingConstraint.constant = 18
            cell.titleLabel.text = "Organization Logo"
        case (1, 0):
            cell.icon.image = #imageLiteral(resourceName: "resume")
            cell.titleLabel.text = "Manage Account"
        case (1, 1):
            cell.icon.image = #imageLiteral(resourceName: "organization_profile")
            cell.titleLabel.text = "Organization Profile"
            cell.valueLabel.text = Organization.current?.profileStatus
        case (2, 0):
            cell.icon.image = #imageLiteral(resourceName: "tag")
            cell.titleLabel.text = "Our Events"
        case (2, 1):
            cell.icon.image = #imageLiteral(resourceName: "surprised")
            cell.titleLabel.text = "Our Subscribers"
        case(3, 0):
            let cell = UITableViewCell()
            cell.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            let label = UILabel()
            label.text = "About Eventure"
            label.font = .systemFont(ofSize: 17)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            
            label.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
            
            return cell
            
        case (3, 1):
            let cell = UITableViewCell()
            cell.heightAnchor.constraint(equalToConstant: 50).isActive = true

            let label = UILabel()
            label.text = "Log Out"
            label.font = .systemFont(ofSize: 17)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)

            label.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true

            return cell

        default:
            break
        }
        
        return cell
    }
        
    //number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    //section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return [
            "",
            "Organization Information",
            "Event and Subscriptions",
            nil
            ][section]
    }
    
    //rows in sections
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [1, 2, 2, 2][section]
    }
    
    //eliminate first section header
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return [0, 30, 30, 30, 30][section]
    }
    
    //full screen profile picture when tapped
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        let fullScreen = ImageFullScreenPage(image: profilePicture)
        present(fullScreen, animated: true, completion: nil)
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
        currentImageView = nil
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return currentImageView
    }
    
    
    
    
}
