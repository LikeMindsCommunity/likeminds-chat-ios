//
//  LMSharedPreferences.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 09/05/24.
//

import Foundation

enum LMSharedPreferencesKeys: String {
    case tempDeeplinkUrl = "$_deeplink_url"
    case isDMWithRequestEnabled = "$_isDMWithRequestEnabled"
}

class LMSharedPreferences {
    
    private static let shared = UserDefaults.standard
    
    private init() {}
    
    static func setString(_ value: String, forKey key: LMSharedPreferencesKeys) {
        shared.set(value, forKey: key.rawValue)
        shared.synchronize()
    }
    
    static func getString(forKey key: LMSharedPreferencesKeys) -> String? {
        shared.value(forKey: key.rawValue) as? String
    }
    
    static func setString(_ value: String, forKey key: String) {
        shared.set(value, forKey: key)
        shared.synchronize()
    }
    
    static func getString(forKey key: String) -> String? {
        shared.value(forKey: key) as? String
    }
    
    static func removeValue(forKey key: LMSharedPreferencesKeys) {
        shared.removeObject(forKey: key.rawValue)
        shared.synchronize()
    }
    
    static func removeValue(forKey key: String) {
        shared.removeObject(forKey: key)
        shared.synchronize()
    }
    
    static func setValue(_ value: Any, key: String) {
        shared.set(value, forKey: key)
        shared.synchronize()
    }
    
    static func bool(forKey key: String) -> Bool? {
        shared.value(forKey: key) as? Bool
    }
    
}
