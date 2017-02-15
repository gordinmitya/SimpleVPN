//
//  VPNManager.swift
//  SimpleVpn
//
//  Created by Dmitry Gordin on 12/22/16.
//  Copyright © 2016 Dmitry Gordin. All rights reserved.
//

import Foundation
import NetworkExtension

final class VPNManager: NSObject {
    static let shared: VPNManager = {
        let instance = VPNManager()
        instance.manager.localizedDescription = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        instance.loadProfile(callback: nil)
        return instance
    }()
    
    let manager: NEVPNManager = { NEVPNManager.shared() }()
    public var isDisconnected: Bool {
        get {
            return (status == .disconnected)
                || (status == .reasserting)
                || (status == .invalid)
        }
    }
    public var status: NEVPNStatus { get { return manager.connection.status } }
    public let statusEvent = Subject<NEVPNStatus>()
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(VPNManager.VPNStatusDidChange(_:)),
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: nil)
    }
    public func disconnect(completionHandler: (()->Void)? = nil) {
        manager.onDemandRules = []
        manager.isOnDemandEnabled = false
        manager.saveToPreferences { _ in
            self.manager.connection.stopVPNTunnel()
            completionHandler?()
        }
    }
    
    @objc private func VPNStatusDidChange(_: NSNotification?){
        statusEvent.notify(status)
    }
    private func loadProfile(callback: ((Bool)->Void)?) {
        manager.protocolConfiguration = nil
        manager.loadFromPreferences { error in
            if let error = error {
                NSLog("Failed to load preferences: \(error.localizedDescription)")
                callback?(false)
            } else {
                callback?(self.manager.protocolConfiguration != nil)
            }
        }
    }
    private func saveProfile(callback: ((Bool)->Void)?) {
        manager.saveToPreferences { error in
            if let error = error {
                NSLog("Failed to save profile: \(error.localizedDescription)")
                callback?(false)
            } else {
                callback?(true)
            }
        }
    }
    public func connectIKEv2(config: Configuration, onError: @escaping (String)->Void) {
        let p = NEVPNProtocolIKEv2()
        if config.pskEnabled {
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
        } else {
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.none
        }
        p.serverAddress = config.server
        p.disconnectOnSleep = false
        p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.medium
        p.username = config.account
        p.passwordReference = config.getPasswordRef()
        p.sharedSecretReference = config.getPSKRef()
        p.disableMOBIKE = false
        p.disableRedirect = false
        p.enableRevocationCheck = false
        p.enablePFS = false
        p.useExtendedAuthentication = true
        p.useConfigurationAttributeInternalIPSubnet = false
        
        // two lines bellow may depend of your server configuration
        p.remoteIdentifier = config.server
        p.localIdentifier = config.account
        
        loadProfile { _ in
            self.manager.protocolConfiguration = p
            if config.onDemand {
                self.manager.onDemandRules = [NEOnDemandRuleConnect()]
                self.manager.isOnDemandEnabled = true
            }
            self.manager.isEnabled = true
            self.saveProfile { success in
                if !success {
                    onError("Unable to save vpn profile")
                    return
                }
                self.loadProfile() { success in
                    if !success {
                        onError("Unable to load profile")
                        return
                    }
                    let result = self.startVPNTunnel()
                    if !result {
                        onError("Can't connect")
                    }
                }
            }
        }
    }
    private func startVPNTunnel() -> Bool {
        do {
            try self.manager.connection.startVPNTunnel()
            return true
        } catch NEVPNError.configurationInvalid {
            NSLog("Failed to start tunnel (configuration invalid)")
        } catch NEVPNError.configurationDisabled {
            NSLog("Failed to start tunnel (configuration disabled)")
        } catch {
            NSLog("Failed to start tunnel (other error)")
        }
        return false
    }
}
