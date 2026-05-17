//
//  SSHCredentials.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import Foundation

enum AuthMethod: String, Codable {
    case password
    case privateKey
}

struct SSHCredentials: Codable {
    var hostname: String
    var username: String
    var authMethod: AuthMethod
    var password: String?
    var privateKey: String?

    init(hostname: String = "", username: String = "", authMethod: AuthMethod = .password, password: String? = nil, privateKey: String? = nil) {
        self.hostname = hostname
        self.username = username
        self.authMethod = authMethod
        self.password = password
        self.privateKey = privateKey
    }

    var isValid: Bool {
        guard !hostname.isEmpty && !username.isEmpty else {
            return false
        }

        switch authMethod {
        case .password:
            return password != nil && !password!.isEmpty
        case .privateKey:
            return privateKey != nil && !privateKey!.isEmpty
        }
    }
}

