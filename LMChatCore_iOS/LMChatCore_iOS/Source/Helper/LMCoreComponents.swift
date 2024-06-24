//
//  LMCoreComponents.swift
//  LikeMindsChatUI
//
//  Created by Pushpendra Singh on 07/03/24.
//

import Foundation
import UIKit

let LMChatCoreBundle = Bundle(for: LMChatMessageListViewController.self)

public struct LMCoreComponents {
    public static var shared = Self()
    
    // MARK: HomeFeed Screen
    public var groupChatFeedScreen: LMChatGroupFeedViewController.Type = LMChatGroupFeedViewController.self
    public var chatFeedScreen: LMChatFeedViewController.Type = LMChatFeedViewController.self
    
    public var exploreChatroomListScreen: LMExploreChatroomListView.Type = LMExploreChatroomListView.self
    public var exploreChatroomScreen: LMExploreChatroomViewController.Type = LMExploreChatroomViewController.self
    
    // MARK: Report Screen
    public var reportScreen: LMChatReportViewController.Type = LMChatReportViewController.self
    
    // MARK: Participant list Screen
    public var participantListScreen: LMChatParticipantListViewController.Type = LMChatParticipantListViewController.self
    
    // MARK: Attachment message screen
    public var attachmentMessageScreen: LMChatAttachmentViewController.Type = LMChatAttachmentViewController.self
    
    // MARK: Message List Screen
    public var messageListScreen: LMChatMessageListViewController.Type = LMChatMessageListViewController.self
    
    // MARK: Reaction List Screen
    public var reactionListScreen: LMChatReactionViewController.Type = LMChatReactionViewController.self
    
    // MARK: Search List Screen
    public var searchListScreen: LMChatSearchListViewController.Type = LMChatSearchListViewController.self
    
    //MARK: DM Screen
    public var dmChatFeedScreen: LMChatDMFeedViewController.Type = LMChatDMFeedViewController.self
    public var dmMemberListScreen: LMChatMemberListViewController.Type = LMChatMemberListViewController.self
}
