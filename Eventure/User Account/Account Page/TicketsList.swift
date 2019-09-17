//
//  TicketsList.swift
//  Eventure
//
//  Created by Jia Rui Shan on 2019/9/15.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit
import SwiftyJSON
import XLPagerTabStrip

class TicketsList: UIViewController, IndicatorInfoProvider {
    
    private let refreshControl = UIRefreshControl()
    private let refreshControlAttributes: [NSAttributedString.Key: Any] = [
        NSMutableAttributedString.Key.foregroundColor: UIColor.gray,
        .font: UIFont.systemFont(ofSize: 16, weight: .medium)
    ]
    
    private var ticketsTable: UITableView!
    private var loadingBG: UIVisualEffectView!
    private var spinner: UIActivityIndicatorView!
    private var spinnerLabel: UILabel!
    private var emptyLabel: UILabel!
    
    var emptyText = "No tickets"
    
    var tickets = [Ticket]()
    var filter: ((Ticket) -> Bool)?
    
    var logoCache = [String : UIImage]()
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(stringLiteral: self.title ?? "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .init(white: 0.93, alpha: 1)
        
        let allTickets = Ticket.userTickets.sorted { t1, t2 in
            if t1.transactionDate == nil { return false }
            if t2.transactionDate == nil { return true }
            return t1.transactionDate!.timeIntervalSince(t2.transactionDate!) >= 0
        }
        if filter != nil {
            tickets = allTickets.filter { filter!($0) }
        } else {
            tickets = allTickets
        }
        
        emptyLabel = {
            let label = UILabel()
            label.textColor = .darkGray
            label.font = .systemFont(ofSize: 17)
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            
            label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
            
            return label
        }()
        
        loadingBG = {
            let v = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            v.layer.cornerRadius = 12
            v.isHidden = true
            v.layer.masksToBounds = true
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
            
            v.widthAnchor.constraint(equalToConstant: 110).isActive = true
            v.heightAnchor.constraint(equalTo: v.widthAnchor).isActive = true
            v.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            v.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
            
            return v
        }()
        
        spinner = {
            let spinner = UIActivityIndicatorView(style: .whiteLarge)
            spinner.color = .gray
            spinner.startAnimating()
            spinner.translatesAutoresizingMaskIntoConstraints = false
            loadingBG.contentView.addSubview(spinner)
            
            spinner.centerXAnchor.constraint(equalTo: loadingBG.centerXAnchor).isActive = true
            spinner.centerYAnchor.constraint(equalTo: loadingBG.centerYAnchor, constant: -10).isActive = true
            
            return spinner
        }()
        
        spinnerLabel = {
            let label = UILabel()
            label.text = "Loading..."
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15)
            label.textColor = .gray
            label.translatesAutoresizingMaskIntoConstraints = false
            loadingBG.contentView.addSubview(label)
            
            label.centerXAnchor.constraint(equalTo: spinner.centerXAnchor).isActive = true
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 8).isActive = true
            
            return label
        }()
        
        ticketsTable = {
            let tv = UITableView()
            tv.backgroundColor = .clear
            tv.dataSource = self
            tv.delegate = self
            tv.contentInset.top = 10
            tv.contentInset.bottom = 10
            tv.separatorStyle = .none
            tv.tableFooterView = UIView()
            tv.register(TicketCell.classForCoder(), forCellReuseIdentifier: "ticket")
            tv.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(tv)
            
            tv.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            tv.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            tv.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            tv.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            
            return tv
        }()
        
        refreshControl.addTarget(self, action: #selector(pullDownRefresh), for: .valueChanged)
        
        getTickets()
    }
    
    @objc private func pullDownRefresh() {
        getTickets(pulled: true)
    }
    
    func getTickets(pulled: Bool = false) {
        
        emptyLabel.text = ""
        
        if !pulled {
            loadingBG.isHidden = false
        }
        
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "events/GetTickets",
                           parameters: ["userId": String(User.current!.userID)])!
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            DispatchQueue.main.async {
                self.loadingBG.isHidden = true
                if !pulled && self.refreshControl.isRefreshing { return }
                if self.ticketsTable.refreshControl == nil {
                    self.ticketsTable.refreshControl = self.refreshControl
                } else {
                    self.refreshControl.endRefreshing()
                }
            }
            
            guard error == nil else {
                DispatchQueue.main.async {
                    self.emptyLabel.text = CONNECTION_ERROR
                    internetUnavailableError(vc: self)
                }
                return
            }
            
            if let json = try? JSON(data: data!), let tickets = json.array {
                var tmp = [Ticket]()
                for ticketData in tickets {
                    let newTicket = Ticket(ticketInfo: ticketData)
                    newTicket.orgLogo = self.logoCache[newTicket.ticketID]
                    tmp.append(newTicket)
                }
                self.tickets = tmp.filter { self.filter == nil || self.filter!($0) }
                DispatchQueue.main.async {
                    self.emptyLabel.text = tmp.isEmpty ? self.emptyText : ""
                    self.ticketsTable.reloadData()
                }
                DispatchQueue.global(qos: .default).async {
                    Ticket.userTickets = Set(tmp)
                    Ticket.writeToFile(userID: User.current!.userID)
                }
            } else {
                DispatchQueue.main.async {
                    self.emptyLabel.text = SERVER_ERROR
                    serverMaintenanceError(vc: self)
                }
            }
        }
        
        task.resume()
    }
    
    /// Load the logo image for an organization.
    func getLogoImage(ticket: Ticket, handler: ((Ticket) -> ())?) {
        if !ticket.hasLogo { return }
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "events/GetLogo",
                           parameters: ["id": ticket.hostID])!
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            guard error == nil else {
                print("WARNING: Get logo image returned error for organization!")
                return // Don't display any alert here
            }
            if let newLogo = UIImage(data: data!) {
                ticket.orgLogo = newLogo
                DispatchQueue.main.async {
                    handler?(ticket)
                }
            }
        }
        
        task.resume()
    }

}


extension TicketsList: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tickets.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticket", for: indexPath) as! TicketCell
        
        let ticket = tickets[indexPath.row]
        
        cell.setup(ticket: ticket)
        
        if ticket.orgLogo != nil {
            logoCache[ticket.ticketID] = ticket.orgLogo
        }
        
        if ticket.orgLogo == nil {
            getLogoImage(ticket: ticket) { [weak cell] ticketWithLogo in
                cell?.setup(ticket: ticketWithLogo)
                self.logoCache[ticket.ticketID] = ticketWithLogo.orgLogo
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}