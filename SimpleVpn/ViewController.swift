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
    @IBOutlet weak var pskSwitch: UISwitch!
    @IBOutlet weak var pskText: UITextField!
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
        
        let config = Configuration.loadFromDefaults()
        serverText.text = config.server
        accountText.text = config.account
        passwordText.text = config.password
        ondemandSwitch.isOn = config.onDemand
        pskSwitch.isOn = config.pskEnabled
        pskText.text = config.psk
        pskText.isEnabled = config.pskEnabled
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === serverText) {
            accountText.becomeFirstResponder()
        } else if (textField === accountText) {
            passwordText.becomeFirstResponder()
        } else if (textField === pskText && pskSwitch.isOn) {
            passwordText.becomeFirstResponder()
        } else {
            connectClick()
        }
        return true
    }
    
    func vpnStateChanged(status: NEVPNStatus) {
        changeControlEnabled(state: VPNManager.shared.isDisconnected)
        switch status {
        case .disconnected, .invalid, .reasserting:
            connectButton.setTitle("Connect", for: .normal)
        case .connected:
            connectButton.setTitle("Disconnect", for: .normal)
        case .connecting:
            connectButton.setTitle("Connecting...", for: .normal)
        case .disconnecting:
            connectButton.setTitle("Disconnecting...", for: .normal)
        @unknown default:
            connectButton.setTitle("Connect", for: .normal)
        }
    }
    
    func changeControlEnabled(state: Bool) {
        for i in inputFields {
            i.isEnabled = state
        }
        pskSwitch.isEnabled = state
        pskText.isEnabled = pskSwitch.isOn
        ondemandSwitch.isEnabled = state
    }
    
    @IBAction func pskSwitchChanged(_ sender: UISwitch) {
        pskText.isEnabled = sender.isOn
    }
    
    @IBAction func connectClick() {
        if (VPNManager.shared.isDisconnected) {
            let config = Configuration(
                server: serverText.text ?? "",
                account: accountText.text ?? "",
                password: passwordText.text ?? "",
                onDemand: ondemandSwitch.isOn,
                psk: pskSwitch.isOn ? pskText.text : nil)
            VPNManager.shared.connectIKEv2(config: config) { error in
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
            config.saveToDefaults()
        } else {
            VPNManager.shared.disconnect()
        }
    }
}
