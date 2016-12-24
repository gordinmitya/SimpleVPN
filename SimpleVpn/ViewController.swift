//
//  ViewController.swift
//  SimpleVpn
//
//  Created by Dmitry Gordin on 12/22/16.
//  Copyright © 2016 Dmitry Gordin. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var serverText: UITextField!
    @IBOutlet weak var accountText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet var inputFields: [UITextField]!
    @IBOutlet weak var ondemandSwitch: UISwitch!
    @IBOutlet weak var connectButton: CustomButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for field in inputFields {
            field.delegate = self
        }
        
        vpnStateChanged(status: VPNManager.shared.status)
        VPNManager.shared.statusEvent.attach(self, ViewController.vpnStateChanged)
        
        let credentials = ConnectionManager.shared.loadCredentials()
        serverText.text = credentials.server
        accountText.text = credentials.account
        passwordText.text = credentials.password
        ondemandSwitch.isOn = ConnectionManager.shared.loadDemand()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === serverText) {
            accountText.becomeFirstResponder()
        } else if (textField === accountText) {
            passwordText.becomeFirstResponder()
        } else {
            connectClick()
        }
        
        return true
    }
    
    func vpnStateChanged(status: NEVPNStatus) {
        changeControlEnabled(enabled: VPNManager.shared.isDisconnected)
        switch status {
        case .disconnected, .invalid, .reasserting:
            connectButton.setTitle("Connect", for: .normal)
        case .connected:
            connectButton.setTitle("Disconnect", for: .normal)
        case .connecting:
            connectButton.setTitle("Connecting...", for: .normal)
        case .disconnecting:
            connectButton.setTitle("Disconnecting...", for: .normal)
        }
    }
    
    func changeControlEnabled(enabled: Bool) {
        for i in inputFields {
            i.isEnabled = enabled
        }
        ondemandSwitch.isEnabled = enabled
    }
    
    @IBAction func connectClick() {
        if (VPNManager.shared.isDisconnected) {
            let credentials = Credentials(
                server: serverText.text ?? "",
                account: accountText.text ?? "",
                password: passwordText.text ?? "")
            ConnectionManager.shared.connect(credentials: credentials, onDemand: ondemandSwitch.isOn) { error in
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
        } else {
            ConnectionManager.shared.disconnect()
        }
    }
}
