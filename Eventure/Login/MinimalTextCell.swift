//
//  MinimalTextCell.swift
//  Eventure
//
//  Created by Jia Rui Shan on 2019/6/20.
//  Copyright © 2019 UC Berkeley. All rights reserved.
//

import UIKit

class MinimalTextCell: UITableViewCell, UITextFieldDelegate {
    
    let RADIUS: CGFloat = 26
    private var overlay: UIView!
    var auxiliaryView: UIButton!
    private var spinner: UIActivityIndicatorView!
    private var rightConstraint: NSLayoutConstraint?
    
    var textField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .next
        return field
    }()
    
    var returnHandler: (() -> ())?
    var completionHandler: (() -> ())?
    var changeHandler: (() -> ())?
    
    var status: StatusIcon = .none {
        didSet {
            if let r = rightConstraint {
                r.isActive = false
                textField.removeConstraint(r)
            }
            
            self.spinner.stopAnimating()
            
            var inset: CGFloat = -46
            
            switch status {
            case .none:
                inset = -20
                self.auxiliaryView.setImage(nil, for: .normal)
            case .tick:
                for state: UIControl.State in [.normal, .highlighted] {
                    self.auxiliaryView.setImage(#imageLiteral(resourceName: "check"), for: state)
                }
            case .fail:
                for state: UIControl.State in [.normal, .highlighted] {
                    self.auxiliaryView.setImage(#imageLiteral(resourceName: "cross"), for: state)
                }
            case .loading:
                self.spinner.startAnimating()
                self.auxiliaryView.setImage(nil, for: .normal)
            case .disconnected:
                for state: UIControl.State in [.normal, .highlighted] {
                    self.auxiliaryView.setImage(#imageLiteral(resourceName: "disconnected"), for: state)
                }
            case .info:
                self.auxiliaryView.setImage(#imageLiteral(resourceName: "info"), for: .normal)
            }
            
            rightConstraint = textField.rightAnchor.constraint(equalTo: overlay.rightAnchor, constant: inset)
            rightConstraint?.isActive = true
        }
    }
    
    init() {
        super.init(style: .default, reuseIdentifier: nil)
        
        tintColor = .init(red: 1, green: 156/255, blue: 138/255, alpha: 1)
        selectionStyle = .none
        
        overlay = makeBackgroundOverlay()
        configureTextfield()
        auxiliaryView = makeAuxiliaryView()
        spinner = makeSpinner()
    }
    
    private func makeBackgroundOverlay() -> UIView {
        let view = UIView()
        view.backgroundColor = .init(white: 0.88, alpha: 0.5)
        view.layer.cornerRadius = RADIUS
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor,
                                   constant: 30).isActive = true
        view.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor,
                                    constant: -30).isActive = true
        view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor,
                                  constant: 10).isActive = true
        view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor,
                                     constant: -10).isActive = true

        view.heightAnchor.constraint(equalToConstant: RADIUS * 2).isActive = true
        
        return view
    }
    
    private func makeAuxiliaryView() -> UIButton {
        let aux = UIButton(type: .custom)
        aux.tintColor = MAIN_TINT
        aux.imageView?.contentMode = .scaleAspectFit
        aux.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(aux)
        
        aux.widthAnchor.constraint(equalToConstant: 25).isActive = true
        aux.heightAnchor.constraint(equalToConstant: 25).isActive = true
        aux.centerYAnchor.constraint(equalTo: overlay.centerYAnchor).isActive = true
        aux.rightAnchor.constraint(equalTo: overlay.rightAnchor,
                                   constant: -20).isActive = true
        
        return aux
    }
    
    private func makeSpinner() -> UIActivityIndicatorView {
        let auxSpinner = UIActivityIndicatorView(style: .gray)
        auxSpinner.hidesWhenStopped = true
        auxSpinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(auxSpinner)
        
        auxSpinner.centerXAnchor.constraint(equalTo: auxiliaryView.centerXAnchor).isActive = true
        auxSpinner.centerYAnchor.constraint(equalTo: auxiliaryView.centerYAnchor).isActive = true
        
        return auxSpinner
    }
    
    private func configureTextfield() {
        textField.delegate = self
        textField.addTarget(self,
                            action: #selector(textDidChange),
                            for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        
        textField.leftAnchor.constraint(equalTo: overlay.leftAnchor,
                                        constant: RADIUS).isActive = true
        textField.topAnchor.constraint(equalTo: topAnchor, constant: 1).isActive = true
        textField.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        rightConstraint = textField.rightAnchor.constraint(equalTo: overlay.rightAnchor, constant: -RADIUS)
        rightConstraint?.isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            textField.becomeFirstResponder()
        }
    }
    
    
    // Textfield delegate
    
    var originalText = ""
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        originalText = textField.text!
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        /*
         
         Suppose that the user focuses onto another text field. Should we refresh
         the status of the current field? There are two scenarios where we SHOULD
         refresh the status.
         
         1. The text has been modified.
         2. Although the text field hasn't been modified, it is the empty string.
         
         */
        
        if originalText != textField.text! || originalText.isEmpty {
            completionHandler?()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        returnHandler?()
        return true
    }
    
    @objc private func textDidChange() {
        changeHandler?()
    }

}

extension MinimalTextCell {
    enum StatusIcon {
        case none, loading, tick, fail, disconnected, info
    }
}