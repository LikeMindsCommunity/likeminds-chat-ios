//
//  LMUIComponents.swift
//  LMFramework
//
//  Created by Devansh Mohata on 28/11/23.
//

import UIKit

public struct LMUIComponents {
    public static var shared = Self()
    
    private init() { }

    // MARK: Tagging View
    public var taggingTableViewCell: LMChatTaggingUserTableCell.Type = LMChatTaggingUserTableCell.self
    
    //MARK: LMHomeFeed
    public var homeFeedChatroomCell: LMChatHomeFeedChatroomCell.Type = LMChatHomeFeedChatroomCell.self
    public var homeFeedExploreTabCell: LMChatHomeFeedExploreTabCell.Type = LMChatHomeFeedExploreTabCell.self
    public var homeFeedLoading: LMChatHomeFeedLoading.Type = LMChatHomeFeedLoading.self
    public var homeFeedListView: LMChatHomeFeedListView.Type = LMChatHomeFeedListView.self
    public var homeFeedExploreTabView: LMChatHomeFeedExploreTabView.Type = LMChatHomeFeedExploreTabView.self
    public var homeFeedChatroomView: LMChatHomeFeedChatroomView.Type = LMChatHomeFeedChatroomView.self
    public var homeFeedShimmerView: LMChatHomeFeedShimmerView.Type = LMChatHomeFeedShimmerView.self
    
    // MARK: Participant List View
    public var participantListCell: LMChatParticipantCell.Type = LMChatParticipantCell.self
    public var participantView: LMChatParticipantView.Type = LMChatParticipantView.self
    public var participantListView: LMChatParticipantListView.Type = LMChatParticipantListView.self
    
    // MARK: Report Screen Components
    public var reportCollectionCell: LMChatReportViewCell.Type = LMChatReportViewCell.self
    
    public var emojiCollectionCell: LMChatEmojiCollectionCell.Type = LMChatEmojiCollectionCell.self
    
    // Explore chatroom
    public var exploreChatroomView: LMChatExploreChatroomView.Type = LMChatExploreChatroomView.self
    public var exploreChatroomCell: LMChatExploreChatroomCell.Type = LMChatExploreChatroomCell.self
    
    // Shimmer view
    public var shimmerView: LMChatShimmerView.Type = LMChatShimmerView.self
    
    // Chat message list
    public var messageContentView: LMChatMessageContentView.Type = LMChatMessageContentView.self
    public var messageBubbleView: LMChatMessageBubbleView.Type = LMChatMessageBubbleView.self
    public var chatroomHeaderMessageView: LMChatroomHeaderMessageView.Type = LMChatroomHeaderMessageView.self
    public var chatMessageCell: LMChatMessageCell.Type = LMChatMessageCell.self
    public var chatNotificationCell: LMChatNotificationCell.Type = LMChatNotificationCell.self
    public var chatroomHeaderMessageCell: LMChatroomHeaderMessageCell.Type = LMChatroomHeaderMessageCell.self
    public var chatMessageGalleryCell: LMChatGalleryViewCell.Type = LMChatGalleryViewCell.self
    public var chatMessageDocumentCell: LMChatDocumentViewCell.Type = LMChatDocumentViewCell.self
    public var chatMessageAudioCell: LMChatAudioViewCell.Type = LMChatAudioViewCell.self
    public var chatMessageLinkPreviewCell: LMChatLinkPreviewCell.Type = LMChatLinkPreviewCell.self
    public var chatMessagePollCell: LMChatPollViewCell.Type = LMChatPollViewCell.self
    public var messageLoading: LMChatMessageLoading.Type = LMChatMessageLoading.self
    public var attachmentLoaderView: LMAttachmentLoaderView.Type = LMAttachmentLoaderView.self
    public var attachmentRetryView: LMChatAttachmentUploadRetryView.Type = LMChatAttachmentUploadRetryView.self
    public var messageReactionView: LMChatMessageReactionsView.Type = LMChatMessageReactionsView.self
    public var messageReplyView: LMChatMessageReplyPreview.Type = LMChatMessageReplyPreview.self
    public var bottomLinkPreview: LMChatBottomMessageLinkPreview.Type = LMChatBottomMessageLinkPreview.self
    public var chatProfileView: LMChatProfileView.Type = LMChatProfileView.self
    public var galleryContentView: LMChatGalleryContentView.Type = LMChatGalleryContentView.self
    public var galleryView: LMChatMessageGallaryView.Type = LMChatMessageGallaryView.self
    
    public var documentsContentView: LMChatDocumentContentView.Type = LMChatDocumentContentView.self
    public var messageDocumentPreview: LMChatMessageDocumentPreview.Type = LMChatMessageDocumentPreview.self
    
    public var audioContentView: LMChatAudioContentView.Type = LMChatAudioContentView.self
    public var audioPreview: LMChatAudioPreview.Type = LMChatAudioPreview.self
    public var voiceNotePreview: LMChatVoiceNotePreview.Type = LMChatVoiceNotePreview.self
    public var linkContentView: LMChatLinkPreviewContentView.Type = LMChatLinkPreviewContentView.self
    public var messageLinkPreview: LMChatMessageLinkPreview.Type = LMChatMessageLinkPreview.self
    
    public var reactionViewCell: LMChatReactionViewCell.Type = LMChatReactionViewCell.self
    public var reactionTitleCell: LMChatReactionTitleCell.Type = LMChatReactionTitleCell.self
    
    public var searchMessageCell: LMChatSearchMessageCell.Type = LMChatSearchMessageCell.self
    public var searchChatroomCell: LMChatSearchChatroomCell.Type = LMChatSearchChatroomCell.self
    public var approveRejectRequestView: LMChatApproveRejectView.Type = LMChatApproveRejectView.self
    
    public var createPollDisplayView: LMChatCreateDisplayPollView.Type = LMChatCreateDisplayPollView.self
    public var createPollDisplayWidget: LMChatDisplayCreatePollWidget.Type = LMChatDisplayCreatePollWidget.self
    public var createPollHeaderView: LMChatCreatePollHeader.Type = LMChatCreatePollHeader.self
    public var createPollQuestionView: LMChatCreatePollQuestionView.Type = LMChatCreatePollQuestionView.self
    public var createPollDateView: LMChatCreatePollDateView.Type = LMChatCreatePollDateView.self
    public var createPollMetaView: LMChatCreatePollMetaView.Type = LMChatCreatePollMetaView.self
    public var createPollOptionCell: LMChatCreatePollOptionWidget.Type = LMChatCreatePollOptionWidget.self
    
    // MARK: Display Poll Components
    public var pollContentView: LMChatPollContentView.Type = LMChatPollContentView.self
    public var pollDisplayView: LMChatPollView.Type = LMChatPollView.self
    public var pollOptionView: LMChatPollOptionView.Type = LMChatPollOptionView.self
    public var resultPollOptionCell: LMChatPollResultCollectionCell.Type = LMChatPollResultCollectionCell.self
}
