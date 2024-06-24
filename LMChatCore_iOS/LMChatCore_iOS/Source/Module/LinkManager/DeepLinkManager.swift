//
//  DeepLinkManager.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 14/03/24.
//
import Foundation

@objc public class DeepLinkManager: NSObject {
    
    public static let sharedInstance = DeepLinkManager()
 
// MARK: - Variable Access obj-C Classes
    @objc var usingSdkLinks = false
    @objc var isFromUrl = false
    
// MARK: - Global Variable
//    let appDelegate = UIApplication.shared.delegate as! AppDelegate
//    weak var preferences = PreferencesFactory.userPreferences()
    var controller = UIViewController()
    
    private var supportUrlHosts = ["likeminds.community", "www.likeminds.community", "beta.likeminds.community", "www.beta.likeminds.community", "betaweb.likeminds.community", "web.likeminds.community", "*", "collabmates.app.link"]
    private var supportSchemes = ["https", "likeminds", "collabmates"]
    
// MARK: - Private Variable (Internal)
    private var stringCollabcard = "collabcard"
    private var stringChatroomDetails = "chatroom_detail"
    private var limitAcessCalled = false
 
// MARK: - Func Access obj-C Classes
    
    func params(fromRoute url: String) -> [String : Any] {
        let urlComponents = NSURLComponents(string: url)
        let queryItems = urlComponents?.queryItems
        var dictionary: [String : Any] = [:]
        for item in queryItems ?? [] {
            dictionary[item.name] = (item.value ?? "").replacingOccurrences(of: "%20", with: " ")
        }
        return dictionary
    }

// MARK: - Internal func (Rediection  Flow)
    
// MARK:- Go to external Browser
    
    private func gotoExternalBrowser(_ url: String) {
        guard let url = URL(string: url) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func didReceivedRemoteNotification(_ routeUrl: String) {
        print("Notification URL: \(routeUrl)")
        routeToScreen(routeUrl: routeUrl, fromNotification: true, fromDeeplink: false)
    }
    
    func deeplinkRoute(routeUrl: String, fromNotification: Bool, fromDeeplink: Bool) {
        guard let linkUrl = URL(string: routeUrl),
              let firstPath = linkUrl.path.components(separatedBy: "/").filter({$0 != ""}).first?.lowercased(),
              (firstPath == stringCollabcard || firstPath == stringChatroomDetails),
              let finalRouteUrl = RouteBuilderManager.buildRouteForChatroom(withDict: params(fromRoute: routeUrl)) else {
            return
        }
        routeToScreen(routeUrl: finalRouteUrl, fromNotification: true, fromDeeplink: false)
    }

    //MARK:- Deeplink SDK route handled
    func routeToScreen(routeUrl: String, fromNotification: Bool, fromDeeplink: Bool) {
        let routeManager = Routes(route: routeUrl, fromNotification: fromNotification, fromDeeplink: fromDeeplink)
        DispatchQueue.main.async {
            routeManager.fetchRoute { viewController in
                DispatchQueue.main.async {
                    guard let viewController, let topMostController = UIViewController.topViewController() else {
                        LMSharedPreferences.setString(routeUrl, forKey: .tempDeeplinkUrl)
                        return
                    }
                    if let vc = topMostController as? UINavigationController, let homeFeedVC = vc.topViewController as? LMChatGroupFeedViewController {
                        homeFeedVC.navigationController?.pushViewController(viewController, animated: true)
                    } else {
                        let chatMessageViewController = UINavigationController(rootViewController: viewController)
                        chatMessageViewController.modalPresentationStyle = .fullScreen
                        topMostController.present(chatMessageViewController, animated: false)
                    }
                }
            }
        }
    }
}
