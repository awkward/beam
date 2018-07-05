//
//  Settings.swift
//  Beam
//
//  Created by Rens Verhoeven on 07/02/2017.
//  Copyright © 2017 Awkward. All rights reserved.
//

import UIKit

extension Notification.Name {
    
    /// This notification is posted when a setting was set. The object will be a SettingsKey
    public static let SettingsDidChangeSetting = Notification.Name(rawValue: "UserSettingDidChangeNotification")
    
}

public protocol SettingKeyProtocol {
    
    var _key: String { get }
    var _defaultValue: Any? { get }
}

public class SettingsKeys: Equatable {
    
    public var _key: String
    
    public init() {
        self._key = ""
    }
    
    fileprivate init(key: String) {
        self._key = key
    }
    
}

public func == (lhs: SettingsKeys, rhs: SettingsKeys) -> Bool {
    return lhs._key == rhs._key
}

public class SettingsKey <ValueType>: SettingsKeys, SettingKeyProtocol {
    public var _defaultValue: Any?
    
    public init(_ key: String) {
        super.init(key: key)
    }
    
    public init(_ key: String, defaultValue: ValueType) {
        self._defaultValue = defaultValue
        super.init(key: key)
    }
    
}

public class Settings {
    
    let allKeys: [SettingsKeys]
    
    init (allKeys: [SettingsKeys]) {
        self.allKeys = allKeys
        self.userDefaults = UserDefaults.standard
    }
    
    init?(suiteName: String, allKeys: [SettingsKeys]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }
        self.allKeys = allKeys
        self.userDefaults = defaults
    }
    
    private let userDefaults: UserDefaults
    
    public func registerDefaults() {
        var dictionary = [String: Any]()
        for setting in self.allKeys {
            if let setting = setting as? SettingKeyProtocol, setting._defaultValue != nil {
                if let option = setting._defaultValue as? ExternalLinkOpenOption {
                    dictionary[setting._key] = option.rawValue
                } else if let option = setting._defaultValue as? ThumbnailsViewType {
                    dictionary[setting._key] = option.rawValue
                } else if let option = setting._defaultValue as? AppLaunchOption {
                    dictionary[setting._key] = option.dictionaryRepresentation()
                } else {
                    dictionary[setting._key] = setting._defaultValue
                }
                
            }
            
        }
        
        self.userDefaults.register(defaults: dictionary)
    }
    
    // MARK: - Subscript
    
    public subscript(key: SettingsKey<String>) -> String {
        get { return self.userDefaults.string(forKey: key._key) ?? "" }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<String?>) -> String? {
        get { return self.userDefaults.string(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Bool>) -> Bool {
        get { return self.userDefaults.bool(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Int>) -> Int {
        get { return self.userDefaults.integer(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Double>) -> Double {
        get { return self.userDefaults.double(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Float>) -> Float {
        get { return self.userDefaults.float(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Date>) -> Date {
        get { return self.userDefaults.object(forKey: key._key) as? Date ?? Date() }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Date?>) -> Date? {
        get { return self.userDefaults.object(forKey: key._key) as? Date }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<URL?>) -> URL? {
        get { return self.userDefaults.url(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Data>) -> Data {
        get { return self.userDefaults.data(forKey: key._key) ?? Data() }
        set { self.set(newValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<Data?>) -> Data? {
        get { return self.userDefaults.data(forKey: key._key) }
        set { self.set(newValue, forKey: key) }
    }
    
    // MARK: - Custom enum types
    
    public subscript(key: SettingsKey<ExternalLinkOpenOption>) -> ExternalLinkOpenOption {
        get { return ExternalLinkOpenOption(rawValue: self.userDefaults.string(forKey: key._key) ?? "") ?? ExternalLinkOpenOption.inApp }
        set { self.set(newValue.rawValue, forKey: key) }
    }
    
    public subscript(key: SettingsKey<ThumbnailsViewType>) -> ThumbnailsViewType {
        get { return ThumbnailsViewType(rawValue: self.userDefaults.string(forKey: key._key) ?? "") ?? ThumbnailsViewType.large }
        set { self.set(newValue.rawValue, forKey: key) }
    }
    
    // MARK: - Custom struct types
    
    public subscript(key: SettingsKey<AppLaunchOption>) -> AppLaunchOption {
        get {
            guard let dictionary = self.unarchive(key: key) as? [String: String] else {
                return AppLaunchOption.defaultAppLaunchOption
            }
            return AppLaunchOption(dictionary: dictionary)
        }
        set { self.archive(object: newValue.dictionaryRepresentation(), key: key) }
    }
    
    // MARK: - Array types
    
    public subscript(key: SettingsKey<[String]>) -> [String] {
        get { return self.unarchive(key: key) as? [String] ?? [String]() }
        set { self.archive(object: newValue, key: key) }
    }
    
    public subscript(key: SettingsKey<[String]?>) -> [String]? {
        get { return self.unarchive(key: key) as? [String] }
        set { self.archive(object: newValue, key: key) }
    }
    
    // MARK: - Dictionary types
    
    public subscript(key: SettingsKey<[String: NSNumber]>) -> [String: NSNumber] {
        get { return self.unarchive(key: key) as? [String: NSNumber] ?? [String: NSNumber]() }
        set { self.archive(object: newValue, key: key) }
    }
    
    public subscript(key: SettingsKey<[String: NSNumber]?>) -> [String: NSNumber]? {
        get { return self.unarchive(key: key) as? [String: NSNumber] }
        set { self.archive(object: newValue, key: key) }
    }
    
    public subscript(key: SettingsKey<[String: String]>) -> [String: String] {
        get { return self.unarchive(key: key) as? [String: String] ?? [String: String]() }
        set { self.archive(object: newValue, key: key) }
    }
    
    public subscript(key: SettingsKey<[String: String]?>) -> [String: String]? {
        get { return self.unarchive(key: key) as? [String: String] }
        set { self.archive(object: newValue, key: key) }
    }
    
    // MARK: - Archiving
    
    private func archive(object: Any?, key: SettingKeyProtocol) {
        guard let object = object else {
            self.userDefaults.set(nil, forKey: key._key)
            return
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        self.userDefaults.set(data, forKey: key._key)
        self.settingDidChange(key: key, newValue: data)
    }
    
    private func unarchive(key: SettingKeyProtocol) -> Any? {
        guard let data = self.userDefaults.data(forKey: key._key) else {
            return nil
        }
        let object = NSKeyedUnarchiver.unarchiveObject(with: data)
        return object
    }
    
    // MARK: - Change notifications
    
    private func set(_ value: Any?, forKey key: SettingKeyProtocol) {
        guard let value = value else {
            self.userDefaults.removeObject(forKey: key._key)
            self.settingDidChange(key: key, newValue: nil)
            return
        }
        self.userDefaults.set(value, forKey: key._key)
        self.settingDidChange(key: key, newValue: value)
    }
    
    private func settingDidChange(key: SettingKeyProtocol, newValue: Any?) {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: Notification.Name.SettingsDidChangeSetting, object: key)
        } else {
            DispatchQueue.main.sync {
                NotificationCenter.default.post(name: Notification.Name.SettingsDidChangeSetting, object: key)
            }
        }
    }
    
}
