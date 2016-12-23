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
    static let sharedManager: VPNManager = {
        let instance = VPNManager()
        instance.loadProfile(callback: nil)
        instance.manager.localizedDescription = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        instance.manager.isEnabled = true
        return instance
    }()
    
    let manager: NEVPNManager = { NEVPNManager.shared() }()
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
    
    public func connect(server: String, account: String, passwordRef: Data, enableDemand: Bool, onError: @escaping ()->Void) {
        loadProfile() { success in
            if !success {
                onError()
                return
            }
            VPNManager.sharedManager.connectIKEv2(
                server: server,
                account: account,
                passwordRef: passwordRef,
                enableDemand: enableDemand,
                onError: onError)
        }
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
    private func connectIKEv2(server: String, account: String, passwordRef: Data, enableDemand: Bool, onError: @escaping ()->Void) {
        let p = NEVPNProtocolIKEv2()
        p.authenticationMethod = NEVPNIKEAuthenticationMethod.none
        p.useExtendedAuthentication = true
        p.serverAddress = server
        p.remoteIdentifier = server
        p.disconnectOnSleep = false
        p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.medium
        p.localIdentifier = "VPN"
        p.username = account
        p.passwordReference = passwordRef
        manager.protocolConfiguration = p
        if enableDemand {
            manager.onDemandRules = [NEOnDemandRuleConnect()]
            manager.isOnDemandEnabled = true
        }
        saveProfile { success in
            if !success {
                onError()
                return
            }
            self.loadProfile() { success in
                if !success {
                    onError()
                    return
                }
                let result = self.startVPNTunnel()
                if !result {
                    onError()
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
