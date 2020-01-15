//
//  AuthenticationSession.swift
//  Snoo
//
//  Created by Robin Speijer on 11-06-15.
//  Copyright (c) 2015 Awkward. All rights reserved.
//

import Foundation
import CoreData

public final class AuthenticationSession: NSObject, NSSecureCoding {
    
    fileprivate let ExpirationDateKey = "expires_in"
    fileprivate let TokenTypeKey = "token_type"
    fileprivate let ScopeKey = "scope"
    fileprivate let UserIDKey = "userID"
    fileprivate let UsernameKey = "username"
    fileprivate let AccessTokenKey = "access_token"
    fileprivate let RefreshTokenKey = "refresh_token"
    fileprivate let VisitsQeueKey = "visits"
    static let OldKeychainUsernameKey = "reddit"
    
    // MARK: - Properties
    var expirationDate: Date?
    var tokenType: String?
    var scope: String?
    
    public var userIdentifier: String?
    public var username: String?
    public var visitedPostsQueue = Set<String>()
    
    var accessToken: String?
    
    var refreshToken: String?
    
    func destroy() {
        self.refreshToken = nil
    }
    // MARK: - Lifecycle
    
    init?(dictionary: NSDictionary) {
        if let expirationSeconds = dictionary[ExpirationDateKey] as? TimeInterval,
            let scope = dictionary[ScopeKey] as? String,
            let token = dictionary[AccessTokenKey] as? String,
            let type = dictionary[TokenTypeKey] as? String {
                self.expirationDate = Date(timeIntervalSinceNow: expirationSeconds)
                self.tokenType = type
                self.scope = scope
                
                super.init()
                
                self.accessToken = token
                
                if let refreshToken = dictionary[RefreshTokenKey] as? String {
                    self.refreshToken = refreshToken
                }
                if let username = dictionary[UsernameKey] as? String {
                    self.username = username
                }
        } else {
            super.init()
            return nil
        }
        
    }
    
    init(userIdentifier: String, refreshToken: String) {
        super.init()
        self.refreshToken = refreshToken
        self.userIdentifier = userIdentifier
    }
    
    // MARK: - NSCoding
    
    public static var supportsSecureCoding: Bool { true }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        if let expirationDate = aDecoder.decodeObject(of: NSDate.self, forKey: ExpirationDateKey) as Date?,
            let tokenType = aDecoder.decodeObject(of: NSString.self, forKey: TokenTypeKey) as String? {
            self.expirationDate = expirationDate
            self.tokenType = tokenType
            self.scope = aDecoder.decodeObject(of: NSString.self, forKey: ScopeKey) as String?
            self.userIdentifier = aDecoder.decodeObject(of: NSString.self, forKey: UserIDKey) as String?
            self.username = aDecoder.decodeObject(of: NSString.self, forKey: UsernameKey) as String?
            self.accessToken = aDecoder.decodeObject(of: NSString.self, forKey: AccessTokenKey) as String?
            
            var refreshToken: String?
            if let username = self.username,
                let data = try? Keychain.load(username),
                let token = String(data: data, encoding: .utf8) {
                refreshToken = token
            } else if let token = aDecoder.decodeObject(of: NSString.self, forKey: RefreshTokenKey) as String?,
                let decryptedToken = self.encryptDecryptToken(token) {
                refreshToken = decryptedToken
            }
            self.refreshToken = refreshToken
        } else {
            return nil
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.expirationDate, forKey: ExpirationDateKey)
        aCoder.encode(self.tokenType, forKey: TokenTypeKey)
        aCoder.encode(self.scope, forKey: ScopeKey)
        aCoder.encode(self.userIdentifier, forKey: UserIDKey)
        aCoder.encode(self.username, forKey: UsernameKey)
        aCoder.encode(self.accessToken, forKey: AccessTokenKey)
        
        if let username = self.username, let data = self.refreshToken?.data(using: .utf8) {
            do {
                try Keychain.save(username, data: data)
            } catch {
                if let refreshToken = self.refreshToken, let encryptedToken = self.encryptDecryptToken(refreshToken) {
                    aCoder.encode(encryptedToken, forKey: RefreshTokenKey)
                }
            }
        } else if let refreshToken = self.refreshToken, let encryptedToken = self.encryptDecryptToken(refreshToken) {
            aCoder.encode(encryptedToken, forKey: RefreshTokenKey)
        } else {
            if self.refreshToken != nil {
                NSLog("Failed to encrypt refresh token")
            }
        }
        
    }
    
    fileprivate func encryptDecryptToken(_ input: String) -> String? {
        let staticKey = "dVaaOqGmtAXbPxn"
        let key = staticKey.utf8
        let bytes = input.utf8.enumerated().map({
            $1 ^ key[key.index(key.startIndex, offsetBy: $0 % key.count)]
        })
        return String(bytes: bytes, encoding: String.Encoding.utf8)
    }
    
    // MARK: - Helpers
    
    var isValid: Bool {
        if let expirationDate = self.expirationDate {
            return expirationDate.timeIntervalSinceNow > 30
        }
        return false
    }
    
}
