//
//  Credentials.swift
//  SimpleVpn
//
//  Created by Dmitry Gordin on 12/23/16.
//  Copyright © 2016 Dmitry Gordin. All rights reserved.
//

import Foundation

class Credentials {
    public let server: String
    public let account: String
    public let password: String
    
    init(server: String, account: String, password: String) {
        self.server = server
        self.account = account
        self.password = password
    }
}
