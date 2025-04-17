//
//  LMAIChatBotChatViewModel.swift
//  LikeMindsChatCore
//
//  Created by Arpit Verma on 13/04/25.
//

import Foundation
import LikeMindsChatData
import LikeMindsChatUI

/// A protocol defining the methods that the view model uses to communicate
/// changes or updates back to its view controller.
public protocol LMAIChatBotChatViewModelProtocol: AnyObject {
    /// Called when the chatbot initialization process starts
    func didStartInitialization()
    
    /// Called when the chatbot initialization process completes with chatroom ID
    func didCompleteInitialization(chatroomId: String)
    
    /// Called when an error occurs during initialization
    func didFailInitialization(with error: String)
}

/// `LMAIChatBotChatViewModel` serves as the data and business logic layer
/// for `LMAIChatBotViewController`. It handles chatbot initialization and
/// chatroom creation/access.
public class LMAIChatBotChatViewModel: LMChatBaseViewModel {
    
    // MARK: - Properties
    
    /// A weak reference to the delegate conforming to `LMAIChatBotChatViewModelProtocol`.
    weak var delegate: LMAIChatBotChatViewModelProtocol?
    
    /// The chatbot user object once retrieved
    private var chatbot: Member?
    
    /// The chatroom ID for the AI chatbot conversation
    private var chatroomId: String?
    
    // MARK: - Initializer
    
    /// Creates a new instance of the view model and sets the delegate.
    init(_ viewController: LMAIChatBotChatViewModelProtocol) {
        self.delegate = viewController
    }
    
    // MARK: - Module Creation
    
    /// Factory method to create an instance of `LMAIChatBotViewController`
    /// wired up with an `LMAIChatBotChatViewModel`.
    public static func createModule() throws -> LMChatAIBotInitiationViewController {
        guard LMChatCore.isInitialized else {
            throw LMChatError.chatNotInitialized
        }
        let viewController = LMCoreComponents.shared.aiChatBotIntiationScreen.init()
        viewController.viewModel = LMAIChatBotChatViewModel(viewController)
        return viewController
    }
    
    // MARK: - Initialization Logic
    
    /// Starts the chatbot initialization process
    func initializeChatbot() {
        delegate?.didStartInitialization()
        
        // First check if we already have a chatroom ID
        if let existingChatroomId = LMSharedPreferences.getString(forKey: "chatroomIdWithAIChatbot") {
            print("Found existing chatroom ID: \(existingChatroomId)")
            // If we have an existing chatroom ID, navigate directly
            saveAndNavigateToChatroom(existingChatroomId)
            return
        }
        
        // If no existing chatroom, proceed with the normal flow
        // Step 1: Get AI Chatbots
        do {
            let request = try GetAIChatbotsRequest.builder()
                .page(1)
                .pageSize(10)
                .build()
            
            LMChatClient.shared.getAIChatbots(request: request) { [weak self] response in
                guard let self = self else { return }
                
                // Check if we have chatbots available
                guard let chatbots = response.data?.users, !chatbots.isEmpty else {
                    self.delegate?.didFailInitialization(with: "No chatbots available")
                    return
                }
                
                // Select the first chatbot
                self.chatbot = chatbots[0]
                self.checkDMStatus(for: chatbots[0])
            }
        } catch {
            delegate?.didFailInitialization(with: error.localizedDescription)
        }
    }
    
    /// Checks DM status for the given chatbot
    private func checkDMStatus(for chatbot: Member) {
        guard let chatbotUUID = chatbot.sdkClientInfo?.uuid else {
            delegate?.didFailInitialization(with: "Invalid chatbot UUID")
            return
        }
        
        let request = CheckDMStatusRequest.builder()
            .requestFrom("member_profile")
            .uuid(chatbotUUID)
            .build()
        
        LMChatClient.shared.checkDMStatus(request: request) { [weak self] response in
            guard let self = self else { return }
            print("dmResponse is \(response.data)")
            
            // Check if DM is enabled
            guard let showDM = response.data?.showDM, showDM else {
                self.delegate?.didFailInitialization(with: "Direct messaging is not enabled")
                return
            }
            
            // Check if we have a CTA URL with chatroom ID
            if let cta = response.data?.cta,
               let ctaURL = URL(string: cta),
               let components = URLComponents(url: ctaURL, resolvingAgainstBaseURL: false),
               let chatroomId = components.queryItems?.first(where: { $0.name == "chatroom_id" })?.value {
                
                
                // Chatroom exists, save ID and proceed
                self.saveAndNavigateToChatroom(chatroomId)
                
            } else {
                // No existing chatroom, create new one
                self.createDMChatroom(with: chatbotUUID)
            }
        }
    }
    
    /// Creates a new DM chatroom with the chatbot
    private func createDMChatroom(with chatbotUUID: String) {
        let request = CreateDMChatroomRequest.builder()
            .uuid(chatbotUUID)
            .build()
        
        LMChatClient.shared.createDMChatroom(request: request) { [weak self] response in
            guard let self = self else { return }
            
            if let chatroomId = response.data?.chatroomData?.id {
                self.saveAndNavigateToChatroom(chatroomId)
            } else {
                self.delegate?.didFailInitialization(with: "Failed to create chatroom")
            }
        }
    }
    
    /// Saves the chatroom ID and notifies completion
    private func saveAndNavigateToChatroom(_ chatroomId: String) {
        print("Saving chatroom ID: \(chatroomId)")
        // Save chatroom ID to local prefs
        LMSharedPreferences.setString(chatroomId, forKey: "chatroomIdWithAIChatbot")
        
        // Notify completion with chatroom ID
        delegate?.didCompleteInitialization(chatroomId: chatroomId)
    }
}
