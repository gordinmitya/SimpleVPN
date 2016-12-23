//
//  ConnectionManager.swift
//  SimpleVpn
//
//  Created by Dmitry Gordin on 12/23/16.
//  Copyright © 2016 Dmitry Gordin. All rights reserved.
//

import Foundation

class ConnectionManager {
    static let shared: ConnectionManager = {
        return ConnectionManager()
    }()
    
    static let VPN_SERVER = "server"
    static let VPN_ACCOUNT = "account"
    static let VPN_PASSWORD = "password"
    static let VPN_ONDEMAND = "ondemand"
    
    static let KEYCHAIN_VPN_PASSWORD = "VPNPassword"
    
    private init() {}
    
    public func connect(credentials: Credentials, onDemand: Bool, onError: @escaping (String) -> Void) {
        saveCredentials(credentials: credentials)
        saveDemand(demand: onDemand)
        
        KeychainWrapper.standard.set(credentials.password, forKey: ConnectionManager.KEYCHAIN_VPN_PASSWORD)
        let passwordRef = KeychainWrapper.standard.dataRef(forKey: ConnectionManager.KEYCHAIN_VPN_PASSWORD)
        
        if passwordRef == nil {
            onError("Unable to save password to keychain")
            return
        }
        
        VPNManager.shared
            .connect(server: credentials.server,
                     account: credentials.account,
                     passwordRef: passwordRef!,
                     enableDemand: onDemand,
                     onError: onError)
    }
    public func disconnect() {
        VPNManager.shared.disconnect()
    }
    
    public func loadCredentials() -> Credentials {
        let server = UserDefaults.standard.string(forKey: ConnectionManager.VPN_SERVER) ?? ""
        let account = UserDefaults.standard.string(forKey: ConnectionManager.VPN_ACCOUNT) ?? ""
        let password = UserDefaults.standard.string(forKey: ConnectionManager.VPN_PASSWORD) ?? ""
        
        return Credentials(server: server, account: account, password: password)
    }
    public func saveCredentials(credentials: Credentials) {
        UserDefaults.standard.set(credentials.server, forKey: ConnectionManager.VPN_SERVER)
        UserDefaults.standard.set(credentials.account, forKey: ConnectionManager.VPN_ACCOUNT)
        UserDefaults.standard.set(credentials.password, forKey: ConnectionManager.VPN_PASSWORD)
    }
    public func loadDemand() -> Bool {
        return UserDefaults.standard.bool(forKey: ConnectionManager.VPN_ONDEMAND)
    }
    public func saveDemand(demand: Bool) {
        UserDefaults.standard.set(demand, forKey: ConnectionManager.VPN_ONDEMAND)
    }
}
