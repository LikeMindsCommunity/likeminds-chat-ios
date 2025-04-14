//
//  ViewController.swift
//  networking-chat
//
//  Created by Anurag Tyagi on 04/04/25.
//

import FirebaseMessaging
import LikeMindsChatCore
import LikeMindsChatUI
import UIKit

extension UIViewController {
    var window: UIWindow? {
        if #available(iOS 13, *) {
            guard
                let windowScene = UIApplication.shared.connectedScenes.first
                    as? UIWindowScene,
                let delegate = windowScene.delegate as? SceneDelegate,
                let window = delegate.window
            else { return nil }
            return window
        }
        return nil
    }
}

class NetworkingChatViewController: LMViewController {

    @IBOutlet weak var apiKeyField: UITextField?
    @IBOutlet weak var userIdField: UITextField?
    @IBOutlet weak var userNameField: UITextField?
    @IBOutlet weak var loginButton: UIButton?

    static func createViewController() -> NetworkingChatViewController {
        let main: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        return main.instantiateViewController(
            withIdentifier: "LoginViewController")
            as! NetworkingChatViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isSavedData()
    }

    func moveToNextScreen() {
        self.showHideLoaderView(isShow: false, backgroundColor: .clear)
        do {
            let networkingChatViewController =
                try LMNetworkingChatViewModel.createModule()
            let navigation = UINavigationController(
                rootViewController: networkingChatViewController)
            navigation.modalPresentationStyle = .overFullScreen
            self.window?.rootViewController = navigation
        } catch let error {
            self.showAlert(message: error.localizedDescription)
        }
    }

    @IBAction func loginAsCMButtonClicked(_ sender: UIButton) {
    }

    @IBAction func loginAsMemberButtonClicked(_ sender: UIButton) {
    }

    @IBAction func loginButtonClicked(_ sender: UIButton) {
        guard
            let apiKey = apiKeyField?.text?.trimmingCharacters(
                in: .whitespacesAndNewlines), !apiKey.isEmpty,
            let userId = userIdField?.text?.trimmingCharacters(
                in: .whitespacesAndNewlines), !userId.isEmpty,
            let username = userNameField?.text?.trimmingCharacters(
                in: .whitespacesAndNewlines), !username.isEmpty
        else {
            showAlert(message: "All fields are mandatory!")
            return
        }

        let userDefalut = UserDefaults.standard
        userDefalut.setValue(apiKey, forKey: "apiKey")
        userDefalut.setValue(userId, forKey: "userId")
        userDefalut.setValue(username, forKey: "username")
        userDefalut.synchronize()
        callInitiateApi(userId: userId, username: username, apiKey: apiKey)
    }

    @discardableResult
    func isSavedData() -> Bool {
        let userDefalut = UserDefaults.standard
        guard let apiKey = userDefalut.value(forKey: "apiKey") as? String,
            let userId = userDefalut.value(forKey: "userId") as? String,
            let username = userDefalut.value(forKey: "username") as? String
        else {
            return false
        }
        callInitiateApi(userId: userId, username: username, apiKey: apiKey)
        return true
    }

    func callInitiateApi(userId: String, username: String, apiKey: String) {
        self.showHideLoaderView(isShow: true, backgroundColor: .clear)

        LMChatCore.shared.showChat(
            apiKey: apiKey, username: username, uuid: userId
        ) { [weak self] result in
            switch result {
            case .success:
                self?.moveToNextScreen()
            case .failure(let error):
                self?.showAlert(message: error.localizedDescription)
            }
        }

    }

    func showAlert(message: String) {
        let alert = UIAlertController(
            title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alert, animated: true)
    }
}
