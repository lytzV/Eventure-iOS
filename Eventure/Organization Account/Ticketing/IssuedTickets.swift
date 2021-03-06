//
//  IssuedTickets.swift
//  Eventure
//
//  Created by Jia Rui Shan on 2019/9/19.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit
import SwiftyJSON
import XLPagerTabStrip
import MessageUI

class IssuedTickets: UITableViewController, IndicatorInfoProvider {

    private(set) var event: Event!
    private(set) var parentVC: TicketManagerMain!
    var admissionType: AdmissionType {
        return parentVC.admissionType
    }
    
    /// Incomplete registrant information, only using it as a data structure to hold partial information
    var tickets = [Ticket]()
    
    private var rc = UIRefreshControl()
    private var emptyLabel: UILabel!
    private var loadingBG: UIView!
    
    required init(parentVC: TicketManagerMain) {
        super.init(nibName: nil, bundle: nil)
        
        self.event = parentVC.event
        self.parentVC = parentVC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        parentVC.navigationItem.backBarButtonItem = .init(title: "Issued Tickets", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.contentInset.top = 6
        tableView.contentInset.bottom = 6
        tableView.backgroundColor = AppColors.background
        tableView.register(IssuedTicketCell.classForCoder(), forCellReuseIdentifier: "ticket")
        
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(showMore)))
                
        loadingBG = view.addLoader()
        loadingBG.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        loadingBG.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        emptyLabel = {
            let label = UILabel()
            label.textColor = .gray
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            
            label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 30).isActive = true
            label.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -30).isActive = true
            label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
            
            return label
        }()
        
        rc.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        loadTickets()
    }
    
    @objc private func refresh() {
        loadTickets(pulled: true)
    }
    
    func sortAndReload() {
        tickets.sort { (t1, t2) -> Bool in
            (t1.creationDate ?? .distantPast) >= (t2.creationDate ?? .distantPast)
        }
        tableView.reloadData()
    }
    
    func loadTickets(pulled: Bool = false) {
        
        emptyLabel.text = ""
        
        let parameters = [
            "eventId": event.uuid,
            "admissionId": admissionType.id
        ]
        
        if !pulled {
            loadingBG.isHidden = false
        }
        
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "events/ListPurchases",
                           parameters: parameters)!
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            DispatchQueue.main.async {
                if !pulled {
                    self.loadingBG.isHidden = true
                    self.tableView.refreshControl = self.rc
                } else {
                    self.rc.endRefreshing()
                }
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    self.emptyLabel.text = CONNECTION_ERROR
                    internetUnavailableError(vc: self)
                }
                return
            }
            
            if let json = try? JSON(data: data!), json.array != nil {
                var newRecords = [Ticket]()
                for purchase in json.array! {
   	                 let newTicket = Ticket(ticketInfo: purchase)
                    if newTicket.paymentType == .issued && newTicket.admissionID == self.admissionType.id {
                        newRecords.append(newTicket)
                    }
                }
                DispatchQueue.main.async {
                    self.tickets = newRecords
                    self.emptyLabel.text = self.tickets.isEmpty ? "No issued tickets" : ""
                    self.sortAndReload()
                }
            } else {
                DispatchQueue.main.async {
                    self.emptyLabel.text = SERVER_ERROR
                }
                print("Unable to parse '\(String(data: data!, encoding: .utf8)!)'")
            }
        }
        
        task.resume()
    }
    
    @objc private func showMore(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint), tickets[indexPath.row].transactionDate == nil {
                let alert = UIAlertController(title: "More actions", message: nil, preferredStyle: .actionSheet)
                alert.addAction(.init(title: "Copy Redeem Code", style: .default, handler: { _ in
                    UIPasteboard.general.string = self.tickets[indexPath.row].redeemCode ?? ""
                }))
                alert.addAction(.init(title: "Save QR Image", style: .default, handler: { _ in
                    self.saveQRCode(ticket: self.tickets[indexPath.row])
                }))
                alert.addAction(.init(title: "Email Ticket", style: .default, handler: { _ in
                    self.mailTicket(ticket: self.tickets[indexPath.row])
                }))
                alert.addAction(.init(title: "Delete", style: .destructive, handler: { _ in
                    self.deleteRow(indexPath: indexPath)
                }))
                alert.addAction(.init(title: "Cancel", style: .cancel))
                
                if let popoverController = alert.popoverPresentationController {
                    popoverController.sourceView = tableView
                    let cellRect = tableView.rectForRow(at: indexPath)
                    popoverController.sourceRect = CGRect(x: cellRect.midX, y: cellRect.midY, width: 0, height: 0)
                }
                
                present(alert, animated: true)
            }
        }
    }
    
    private func generateCode(from ticket: Ticket) -> UIView? {
        
        guard let qrCode = generateQRCode(from: APP_DOMAIN + "ticket?id=" + ticket.ticketID) else {
            let alert = UIAlertController(title: "Error generating QR code", message: "You device does not support QR code generation!", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .cancel))
            present(alert, animated: true)
            return nil
        }
        
        if event.ticketStyle == .standard {
            let formatted = TicketCodeView()
            formatted.titleLabel.text = event.title
            if let startTime = event.startTime {
                formatted.subtitleLabel.text = Date.readableFormatter.string(from: startTime) + " | " + event.location
            } else {
                formatted.subtitleLabel.text = "TBA | " + event.location
            }
            formatted.qrCode.image = qrCode
            let noun = ticket.quantity == 1 ? "Ticket" : "Tickets"
            formatted.ticketType.text = "\(ticket.quantity) × \(ticket.typeName) " + noun
            formatted.redeemCode.text = "Redeem code: \(ticket.redeemCode ?? "Unavailable")"
            formatted.translatesAutoresizingMaskIntoConstraints = false
            formatted.layoutIfNeeded()
            
            if let logo = Organization.current?.logoImage {
                formatted.orgLogo.image = logo
            }
            
            return formatted
        } else if event.ticketStyle == .imageBelow {
            
            guard event.hasBannerImage else {
                let alert = UIAlertController(title: "No custom image was specified", message: "You have configured your event to generate QR codes with a custom layout that requires an embedded image. However, you never provided that image in the event editor. Please first go there and add your image.", preferredStyle: .alert)
                alert.addAction(.init(title: "Dismiss", style: .cancel))
                present(alert, animated: true)
                return nil
            }
            
            guard let banner = event.bannerImage else {
                event.getBanner(nil)
                let alert = UIAlertController(title: "No custom image was found", message: "Our records indicate that you have provided a custom image for QR code generation, but this image isn't locally available on your device right now. We've just sent an request to fetch the image from our server. Please wait a few seconds and try again.", preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel))
                present(alert, animated: true)
                return nil
            }
            
            let qr = TicketImageBelowQR(banner: banner)
            qr.qrCode.image = qrCode
            qr.redeemCode.text = "Redeem code: \(ticket.redeemCode ?? "Unavailable")"
            qr.translatesAutoresizingMaskIntoConstraints = false
            qr.layoutIfNeeded()
            
            if let logo = Organization.current?.logoImage {
                qr.orgLogo.image = logo
            }
            
            return qr
        }
        return nil
    }
    
    private func mailTicket(ticket: Ticket) {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        
        guard let formatted = generateCode(from: ticket) else {
            return
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: formatted.bounds)
        let qr = renderer.image { context in
            formatted.layer.render(in: context.cgContext)
        }
        
        let body = """
        <a style="float:right" href="\(APP_STORE_LINK)"><img src="\(APP_DOMAIN)static/assets/logo.jpg" style="width:60px; height:60px" title="Eventure app" alt="Eventure"></a><br><div style="clear:both">
        Hi there!<br><br>Thank you for supporting <em>\(event.title)</em>. Here is your digital ticket, which contains detailed information about when and where it will take place. If you have an iOS device, we recommend that you <b>scan this QR code</b> with <a href="\(APP_STORE_LINK)">Eventure</a>, which will automatically validate your ownership and sync the ticket to your account. Otherwise, please take a moment to visit <a href="https://eventure-app.com/ticket?id=\(ticket.ticketID)">this link</a> and fill out your contact information. This will help us to assign ownership to this ticket, which is <b>essential</b> for its validation. We hope to see you at the event:)<br><br>Best regards,<br> \(event.hostTitle)</div>
"""
        
        let composer = MFMailComposeViewController()
        composer.setMessageBody(body, isHTML: true)
        composer.setSubject("Ticket receipt for “\(event.title)”")
        composer.addAttachmentData(qr.pngData()!, mimeType: "image/png", fileName: "ticket")
        composer.mailComposeDelegate = self
        
        present(composer, animated: true)
        
    }
    
    private func saveQRCode(ticket: Ticket) {
        
        guard let formatted = generateCode(from: ticket) else {
            return
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: formatted.bounds)
        let qr = renderer.image { context in
            formatted.layer.render(in: context.cgContext)
        }

        UIImageWriteToSavedPhotosAlbum(qr, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "The QR Code has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticket", for: indexPath) as! IssuedTicketCell
        
        cell.setup(ticket: tickets[indexPath.row])
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        parentVC.navigationItem.backBarButtonItem = .init(title: "Issued Tickets", style: .plain, target: nil, action: nil)
        let editor = CreateNewTicket(parentVC: self, ticketToEdit: tickets[indexPath.row])
        navigationController?.pushViewController(editor, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard tickets[indexPath.row].transactionDate == nil else { return [] }

        let action = UITableViewRowAction(style: .destructive, title: "Delete", handler: { action, indexPath in
            self.deleteRow(indexPath: indexPath)
        })

        action.backgroundColor = AppColors.fatal
        return [action]
    }
    
    private func deleteRow(indexPath: IndexPath) {
        let ticket = tickets[indexPath.row]
        
        loadingBG.isHidden = false
        (loadingBG.subviews.last as? UILabel)?.text = "Deleting..."
        
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "events/DeleteTicket",
                           parameters: ["ticketId": ticket.ticketID])!
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            DispatchQueue.main.async {
                self.loadingBG.isHidden = true
                (self.loadingBG.subviews.last as? UILabel)?.text = "Loading..."
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    internetUnavailableError(vc: self)
                }
                return
            }
            
            let msg = String(data: data!, encoding: .utf8)
            
            switch msg {
            case INTERNAL_ERROR:
                DispatchQueue.main.async {
                    serverMaintenanceError(vc: self)
                }
            case "success":
                DispatchQueue.main.async {
                    self.tickets.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            default:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                    alert.addAction(.init(title: "Dismiss", style: .cancel))
                    self.present(alert, animated: true)
                }
            }
        }
        
        task.resume()
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Issued")
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

extension IssuedTickets: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
