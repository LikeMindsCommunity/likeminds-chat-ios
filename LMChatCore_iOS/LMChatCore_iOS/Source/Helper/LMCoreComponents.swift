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
    public var homeFeedScreen: LMChatHomeFeedViewController.Type = LMChatHomeFeedViewController.self
    
    public var exploreChatroomListScreen: LMExploreChatroomListView.Type = LMExploreChatroomListView.self
    public var exploreChatroomScreen: LMExploreChatroomViewController.Type = LMExploreChatroomViewController.self
    
    // MARK: Report Screen
    public var reportScreen: LMChatReportViewController.Type = LMChatReportViewController.self
    
    // MARK: Participant list Screen
    public var participantListScreen: LMParticipantListViewController.Type = LMParticipantListViewController.self
    
    // MARK: Attachment message screen
    public var attachmentMessageScreen: LMChatAttachmentViewController.Type = LMChatAttachmentViewController.self
    
    public var messageListScreen: LMChatMessageListViewController.Type = LMChatMessageListViewController.self
}
