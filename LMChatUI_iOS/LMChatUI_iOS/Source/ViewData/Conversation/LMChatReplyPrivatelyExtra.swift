//
//  LMChatReplyPrivatelyExtra.swift
//  LikeMindsChatUI
//
//  Created by Anurag Tyagi on 24/04/25.
//
import Foundation

public class LMChatReplyPrivatelyExtra {
    // MARK: - Properties
    public let sourceChatroomName: String
    public let sourceChatroomId: String
    public let sourceConversation: ConversationViewData

    // MARK: - Initialization
    public init(
        sourceChatroomName: String,
        sourceChatroomId: String,
        sourceConversation: ConversationViewData
    ) {
        self.sourceChatroomName = sourceChatroomName
        self.sourceChatroomId = sourceChatroomId
        self.sourceConversation = sourceConversation
    }
}
