//
//  LMConversationUtils.swift
//  Pods
//
//  Created by Anurag Tyagi on 15/04/25.
//

import LikeMindsChatData
import LikeMindsChatUI

/// A utility class that provides helper functions for conversation-related tasks within the chat SDK.
public class LMConversationUtils {
    
    /// A shared singleton instance of `LMConversationUtils` to access utility methods.
    public static let shared = LMConversationUtils()

    // Private initializer to enforce the singleton pattern.
    private init() {}

    /**
     Determines if a conversation is valid for the "Reply Privately" option.
     
     A conversation is considered valid for "Reply Privately" if:
     - It is not a self-message (i.e., the conversation does not belong to the logged-in user).
     - It has not been deleted by another user.
     
     - Parameters:
        - selectedConversation: The conversation that needs to be validated for "Reply Privately".
     
     - Returns: `true` if the conversation is valid for replying privately, `false` otherwise.
     */
    static func isConversationValidForReplyPrivately(
        selectedConversation: ConversationViewData
    ) -> Bool {
        // Check if it's a self-message
        if selectedConversation.member?.sdkClientInfo?.uuid
            == UserPreferences.shared.getClientUUID()
        {
            return false
        }

        // Check if the conversation is deleted
        if selectedConversation.deletedBy != nil {
            return false
        }

        return true
    }

    /**
     Determines if the "Reply Privately" option should be shown for a specific conversation.
     
     The option is shown based on several conditions including the conversation's validity,
     the chat theme, the type of chatroom, and whether direct messaging (DM) is enabled.

     - Parameters:
        - selectedConversation: The conversation to check if the option should be shown for.
        - selectedChatTheme: The theme of the chat (e.g., community hybrid chat).
        - checkDMStatusResponse: The status of direct messaging for the user.
        - chatroomType: The type of chatroom (used to check if it's a DM chatroom).
     
     - Returns: `true` if the "Reply Privately" option should be shown, `false` otherwise.
     */
    static func toShowReplyPrivatelyOption(
        selectedConversation: ConversationViewData,
        selectedChatTheme: LMChatTheme,
        checkDMStatusResponse: CheckDMStatusResponse,
        chatroomType: Int
    ) -> Bool {
        // Get configuration from the configuration manager
        guard
            let replyPrivatelyConfig =
                LMConfigurationManager.getReplyPrivatelyConfiguration(),
            let showList = Int(
                checkDMStatusResponse.cta?.getQueryItems()["show_list"] ?? "0")
        else {
            return false
        }

        // Check if the conversation is valid for replying privately
        let isConversationValid = isConversationValidForReplyPrivately(
            selectedConversation: selectedConversation)

        // Perform initial checks for the "Reply Privately" option
        if selectedChatTheme != .COMMUNITY_HYBRID_CHAT {
            return false
        }

        if chatroomType == 10 {  // DM chatroom
            return false
        }

        if checkDMStatusResponse.showDM == false { // DM is not enabled
            return false
        }

        if !isConversationValid { // Conversation is not valid for replying privately
            return false
        }

        // Check the value of showList and apply conditions accordingly
        if showList == 2 {  // Only Member to CM enabled
            if selectedConversation.member?.state == 1 {
                return true
            }
            return false
        } else if showList == 1 {  // Member to Member enabled
            guard
                let allowScope = replyPrivatelyConfig.value["allowed_scope"]
                    as? String,
                let allowedScope = ReplyPrivatelyAllowedScope(
                    rawValue: allowScope)
            else {
                return false
            }

            // Handle different allowed scopes for replying privately
            switch allowedScope {
            case .NO_ONE:
                return false
            case .ONLY_CMS:
                return selectedConversation.member?.state == 1
            case .ALL_MEMBERS:
                return true
            }
        }

        return false
    }
}
