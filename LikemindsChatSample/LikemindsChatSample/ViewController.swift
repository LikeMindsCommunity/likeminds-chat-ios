//
//  ViewController.swift
//  LikemindsChatSample
//
//  Created by Pushpendra Singh on 13/12/23.
//

import UIKit
import LikeMindsChat
import LikeMindsChatUI
import LikeMindsChatCore

class ViewController: LMViewController {
    
    @IBOutlet weak var apiKeyField: UITextField?
    @IBOutlet weak var userIdField: UITextField?
    @IBOutlet weak var userNameField: UITextField?
    @IBOutlet weak var loginButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        isSavedData()
//        self.apiKeyField?.text = "2a540606-6e83-4fcc-946e-ea479bb3c6a8"
//        self.userIdField?.text = "testpushcom123"
//        self.userNameField?.text = "testpushcom"
        self.apiKeyField?.text = "5f567ca1-9d74-4a1b-be8b-a7a81fef796f"
        self.userIdField?.text = "aca04469-4fde-4593-834d-f7931244d2f1"
        self.userNameField?.text = "Pushpendra Singh"
        
    }
    
    func moveToNextScreen() {
        self.showHideLoaderView(isShow: false, backgroundColor: .clear)
//        guard let homefeedvc = try? LMChatHomeFeedViewModel.createModule() else { return }
//        guard let homefeedvc = try? LMChatFeedViewModel.createModule() else { return }
        let homefeedvc = ChatFeedViewModel.createModule()
        let navigation = UINavigationController(rootViewController: homefeedvc)
        navigation.modalPresentationStyle = .overFullScreen
        self.present(navigation, animated: false)
    }
    
    // MARK: setupViews
    open override func setupViews() {
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
    }
    
    @IBAction func loginAsCMButtonClicked(_ sender: UIButton) {
    }
    
    @IBAction func loginAsMemberButtonClicked(_ sender: UIButton) {
    }

    @IBAction func loginButtonClicked(_ sender: UIButton) {
        guard let apiKey = apiKeyField?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty,
              let userId = userIdField?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !userId.isEmpty,
              let username = userNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !username.isEmpty else {
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
              let username = userDefalut.value(forKey: "username") as? String else {
            return false
        }
        callInitiateApi(userId: userId, username: username, apiKey: apiKey)
        return true
    }
    
    func callInitiateApi(userId: String, username: String, apiKey: String) {
        LMChatMain.shared.configure(apiKey: apiKey)
        self.showHideLoaderView(isShow: true, backgroundColor: .clear)
        try? LMChatMain.shared.initiateUser(username: username, userId: userId, deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "") {[weak self] success, error in
            guard success else {
                self?.showAlert(message: error ?? "")
                return
            }
            self?.moveToNextScreen()
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alert, animated: true)
    }
 
}

