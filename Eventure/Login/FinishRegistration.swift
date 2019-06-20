//
//  FinishRegistration.swift
//  Eventure
//
//  Created by Jia Rui Shan on 2019/6/19.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit

/// A special view controller that can display an account registration status.

class FinishRegistration: UIViewController {
    
    var userInputs: [String : String]?
    var regVC: RegisterController?
    
    private var spinner: UIActivityIndicatorView!
    private var spinnerCaption: UILabel!
    private var button: UIButton!
    private var completionImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        spinner = makeSpinner()
        spinner.startAnimating()

        spinnerCaption = makeLabel()
        
        button = makeButton()
        button.isHidden = true
        
        completionImage = makeImageView()
        
        createAccount()
    }
    
    private func makeSpinner() -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.color = UIColor(white: 0.75, alpha: 1)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor,
                                         constant: -25).isActive = true
        return spinner
    }
    
    private func makeLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.text = "Creating your Account..."
        label.font = .systemFont(ofSize: 18)
        label.textColor = UIColor(white: 0.3, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        label.topAnchor.constraint(equalTo: spinner.bottomAnchor,
                                   constant: 24).isActive = true
        label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor,
                                    constant: 30).isActive = true
        label.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor,
                                     constant: -30).isActive = true
        
        
        return label
    }
    
    private func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = MAIN_TINT_DARK
        button.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        button.widthAnchor.constraint(equalToConstant: 220).isActive = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                       constant: -29).isActive = true
        
        button.addTarget(self, action: #selector(returnToLogin), for: .touchUpInside)
        
        return button
    }
    
    private func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        imageView.widthAnchor.constraint(equalToConstant: 52).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 56).isActive = true
        imageView.centerXAnchor.constraint(equalTo: spinner.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: spinner.centerYAnchor).isActive = true
        
        return imageView
    }
    
    
    @objc private func returnToLogin(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
        if sender.title(for: .normal) == "Return to Login" {
            self.regVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    
    /**
     Displays a failure message.
     
     - Parameters:
        - msg: The failure message to display to the user.
     */
    
    private func failed(msg: String) {
        spinner.stopAnimating()
        spinnerCaption.text = msg
        button.isHidden = false
        button.setTitle("Return to Registration", for: .normal)
        completionImage.image = #imageLiteral(resourceName: "error")
    }
    
    
    /// Displays the success message.
    
    private func succeeded() {
        spinner.stopAnimating()
        spinnerCaption.text = "Your Eventure account was created!"
        button.isHidden = false
        button.setTitle("Return to Login", for: .normal)
        completionImage.image = #imageLiteral(resourceName: "done")
    }
    
    
    /// Initiates an API call to `account/Register` with the information provided by the user.
    
    private func createAccount() {
        
        // First copy the user inputs from the registration screen to the parameters
        guard var parameters = self.userInputs else {
            return
        }
        
        // Add `displayedName` parameter
        if parameters["displayedName"] == nil {
            parameters["displayedName"] = parameters["email"]
        }
        
        // Add `date` parameter
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd" // e.g. 2019-06-02
        df.locale = Locale(identifier: "en_US")
        let dateStr = df.string(from: Date()) // pass this to the URL parameters
        parameters["date"] = dateStr
        
        print("About to register account with these parameters:\n \(parameters)")
        
        let url = URL.with(base: API_BASE_URL,
                           API_Name: "account/Register",
                           parameters: parameters)!
        
        var request = URLRequest(url: url)
        
        // Authentication
        let token = "\(USERNAME):\(PASSWORD)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        
        let task = CUSTOM_SESSION.dataTask(with: request) {
            data, response, error in
            
            guard error == nil else {
                print(error!)
                return
            }
            
            if let str = String(data: data!, encoding: .ascii) {
                print(str)
                DispatchQueue.main.async {
                    switch str {
                    case "success":
                        self.succeeded()
                    case "invalid email":
                        self.failed(msg: "The provided email was invalid.")
                    case "internal error":
                        self.failed(msg: "The server is temporarily unavailable.")
                    case "email exists":
                        self.failed(msg: "The provided email is already registered.")
                    default:
                        self.failed(msg: "An unknown error has occurred.")
                    }
                }
                
            }
        }
        
        task.resume()
        
    }

}