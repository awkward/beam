//
//  Keychain.swift
//  Snoo
//
//  Created by Robin Speijer on 18-06-15.
//  Copyright © 2015 Awkward. All rights reserved.
//
//swiftlint:disable operator_usage_whitespace

import Foundation

enum KeychainError: OSStatus, Error {
    case success                               = 0       /* No error. */
    case unimplemented                         = -4      /* Function or operation not implemented. */
    case io                                    = -36     /*I/O error (bummers)*/
    case opWr                                  = -49     /*file already open with with write permission*/
    case param                                 = -50     /* One or more parameters passed to a function where not valid. */
    case allocate                              = -108    /* Failed to allocate memory. */
    case userCanceled                          = -128    /* User canceled the operation. */
    case badReq                                = -909    /* Bad parameter or invalid state for operation. */
    case internalComponent                     = -2070
    case notAvailable                          = -25291  /* No keychain is available. You may need to restart your computer. */
    case duplicateItem                         = -25299  /* The specified item already exists in the keychain. */
    case itemNotFound                          = -25300  /* The specified item could not be found in the keychain. */
    case interactionNotAllowed                 = -25308  /* User interaction is not allowed. */
    case decode                                = -26275  /* Unable to decode the provided data. */
    case authFailed                            = -25293  /* The user name or passphrase you entered is not correct. */
}

class Keychain {
    
    static var serviceName = "com.madeawkward.snoo"
    
    static func save(_ key: String, data: Data) throws {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrIsInvisible as String: kCFBooleanTrue,
            kSecAttrService as String: self.serviceName,
            kSecAttrAccessible as String: kSecAttrAccessibleAlways
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        
        let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            if let error = KeychainError(rawValue: status) {
                throw error
            } else {
                throw NSError.snooError(Int(status), localizedDescription: "Unknown keychain save error (\(status))")
            }
        }
    }
    
    static func load(_ key: String) throws -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrService as String: self.serviceName] as [String: Any]
        
        var dataTypeRef: AnyObject?
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == noErr {
            return (dataTypeRef as? Data)
        } else {
            if let error = KeychainError(rawValue: status) {
                if error == KeychainError.itemNotFound {
                    return nil
                }
                throw error
            } else {
                throw NSError.snooError(Int(status), localizedDescription: "Unknown keychain load error (\(status))")
            }
        }
    }
    
    static func delete(_ key: String) throws {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: self.serviceName] as [String: Any]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        if status != noErr {
            if let error = KeychainError(rawValue: status) {
                throw error
            } else {
                throw NSError.snooError(Int(status), localizedDescription: "Unknown keychain delete error (\(status))")
            }
        }
    }
    
    static func clear() throws {
        let query = [ kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: self.serviceName ] as [String: Any]
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        if status != noErr {
            if let error = KeychainError(rawValue: status) {
                throw error
            } else {
                throw NSError.snooError(Int(status), localizedDescription: "Unknown keychain clear error (\(status))")
            }
        }
    }
    
}
