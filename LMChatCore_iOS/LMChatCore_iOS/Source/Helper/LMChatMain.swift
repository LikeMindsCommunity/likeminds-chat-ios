//
//  LMChatMain.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 17/02/24.
//

import Foundation
import LikeMindsChat
import FirebaseMessaging

public class LMChatMain {
    
    private init() {}
    
    public static var shared: LMChatMain = .init()
//    static var analytics: LMFeedAnalyticsProtocol = LMFeedAnalyticsTracker()
    static private(set) var isInitialized: Bool = false
    var apiKey: String = ""
    var deviceId: String?
    public func configure(apiKey: String) {
        self.apiKey = apiKey
        LMChatAWSManager.shared.initialize()
        GiphyAPIConfiguration.configure()
    }
    
    public func initiateUser(username: String, userId: String, deviceId: String, completion: ((Bool, String?) -> Void)?) throws {
        self.deviceId = deviceId
        let request = InitiateUserRequest.builder()
            .userName(username)
            .uuid(userId)
            .deviceId(deviceId)
            .isGuest(false)
            .apiKey(apiKey)
            .build()
        LMChatClient.shared.initiateUser(request: request) {[weak self] response in
            guard response.success, response.data?.appAccess == true else {
                print("error in initiate user: \(response.errorMessage ?? "")")
                self?.logout()
                completion?(response.success, response.errorMessage)
                return
            }
            if let communitySettings = response.data?.community?.communitySettings, let setting = communitySettings.first(where: {$0.type == "enable_dm_without_connection_request"}), setting.enabled == true {
                LMSharedPreferences.setValue(true, key: LMSharedPreferencesKeys.isDMWithRequestEnabled.rawValue)
            } else {
                LMSharedPreferences.setValue(false, key: LMSharedPreferencesKeys.isDMWithRequestEnabled.rawValue)
            }
            Self.isInitialized = true
            self?.registerDevice(deviceId: deviceId)
            completion?(response.success, nil)
        }
    }

    func registerDevice(deviceId: String) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                let request = RegisterDeviceRequest.builder()
                    .deviceId(deviceId)
                    .token(token)
                    .build()
                LMChatClient.shared.registerDevice(request: request) { response in
                    guard response.success else {
                        print("error in device register: \(response.errorMessage ?? "")")
                        return
                    }
                }
            }
        }
    }
    
    
    func logout() {
        guard let deviceId else {
            print("error in logout: device id not present")
            return
        }
        let request = LogoutRequest.builder()
            .deviceId(deviceId)
            .build()
        LMChatClient.shared.logout(request: request) { response in
            
        }
    }
    
    public func parseDeepLink(routeUrl: String) {
        DeepLinkManager.sharedInstance.deeplinkRoute(routeUrl: routeUrl, fromNotification: false, fromDeeplink: true)
    }
    
    @discardableResult
    public func didReceieveNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let route = userInfo["route"] as? String, UIApplication.shared.applicationState == .inactive else {return false }
        DeepLinkManager.sharedInstance.didReceivedRemoteNotification(route)
        return true
    }
    
}

// MARK: LMFeedAnalyticsProtocol
public protocol LMChatAnalyticsProtocol {
    func trackEvent(for eventName: LMChatAnalyticsEventName, eventProperties: [String: AnyHashable])
}

final class LMChatAnalyticsTracker: LMChatAnalyticsProtocol {
    public func trackEvent(for eventName: LMChatAnalyticsEventName, eventProperties: [String : AnyHashable]) {
        let track = """
            ========Event Tracker========
        Event Name: \(eventName)
        Event Properties: \(eventProperties)
            =============================
        """
        print(track)
    }
}

public struct LMChatAnalyticsEventName {
    
}
