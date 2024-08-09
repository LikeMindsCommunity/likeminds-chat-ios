//
//  LMChatAnalytics.swift
//  LMChatCore_iOS
//
//  Created by Devansh Mohata on 08/05/24.
//

import Foundation

// MARK: LMChatAnalyticsProtocol
public protocol LMChatAnalyticsProtocol {
    func trackEvent(for eventName: LMChatAnalyticsEventName, eventProperties: [String: AnyHashable])
}

final class LMChatAnalyticsTracker: LMChatAnalyticsProtocol {
    public func trackEvent(for eventName: LMChatAnalyticsEventName, eventProperties: [String : AnyHashable]) {
        let track = """
            ========Event Tracker========
        Event Name: \(eventName.rawValue)
        Event Properties: \(eventProperties)
            =============================
        """
        print(track)
    }
}

public enum LMChatAnalyticsEventName: String {
    // Chatroom Events
    case chatroomLinkClicked = "chatroom_link_clicked"
    case userTagsSomeone = "user_tags_someone" // Done
    case chatroomMuted = "chatroom_muted" // Done
    case chatroomUnmuted = "chatroom_unmuted" // Done
    case chatroomResponded = "chatroom_responded"
    case chatRoomDeleted = "chatroom_deleted"
    case chatRoomFollowed = "chatroom_followed" // Done
    case chatRoomLeft = "chatroom_left"
    case chatRoomOpened = "chatroom_opened" // Done
    case chatRoomShared = "chatroom_shared"
    case chatRoomUnfollowed = "chatroom_unfollowed" // Done
    case chatroomAutoFollow = "auto_follow_enabled"
    case setChatroomTopic = "current_topic_updated" // Done
    
    // DM Events
    case dmScreenOpened = "direct_messages_screen_opened" // Done
    case dmRequestSent = "dm_request_sent"
    case dmRequestResponded = "dm_request_responded"
    case dmSent = "dm_sent"
    case dmBlock = "dm_blocked"
    case dmUnblock = "dm_unblocked"
    
    // Notification Events
    case notificationReceived = "notification_received"
    case notificationClicked = "notification_clicked"

    // Reaction Events
    case reactionsClicked = "reactions_click"
    case reactionAdded = "reaction_added" // Done
    case reactionListOpened = "reaction_list_opened" // Done
    case reactionRemoved = "reaction_removed" // Done

    // Search Events
    case searchIconClicked = "clicked_search_icon" // Done
    case searchCrossIconClicked = "clicked_cross_search_icon" // Done
    case chatroomSearched = "chatroom_searched" // Done
    case chatroomSearchClosed = "chatroom_search_closed"
    case messageSearched = "message_searched" // Done
    case messageSearchClosed = "message_search_closed"

    // Voice Note Events
    case voiceNoteRecorded = "voice_message_recorded" // Done
    case voiceNotePreviewed = "voice_message_previewed" // Done
    case voiceNoteCanceled = "voice_message_canceled" // Done
    case voiceNoteSent = "voice_message_sent" // Done
    case voiceNotePlayed = "voice_message_played" // Done

    // Onboarding Flow
    case communityTabClicked = "community_tab_clicked"
    case communityFeedClicked = "community_feed_clicked"

    // Attachment Events
    case imageViewed = "image_viewed" // Done
    case videoPlayed = "video_played" // Done
    case audioPlayed = "audio_played" // Done
    case chatLinkClicked = "chat_link_clicked" // Done

    // Message Action Events
    case messageEdited = "message_edited" // Done
    case messageDeleted = "message_deleted" // Done
    case messageCopied = "message_copied" // Done
    case messageReply = "message_reply" // Done

    // Reporting Events
    case messageReported = "message_reported"

    // Sync Related Events
    case syncComplete = "sync_complete"

    // Third Party Share Events
    case thirdPartySharing = "third_party_sharing"
    case thirdPartyAbandoned = "third_party_abandoned"

    // Home and UI Events
    case homeFeedPageOpened = "home_feed_page_opened"
    case emoticonTrayOpened = "emoticon_tray_opened"
    
    // Poll events
    case pollVoted = "poll_voted"
    case pollVotingSkiped = "poll_voting_skipped"
    case pollVotingEdited = "poll_voting_edited"
    case pollCreationCompleted = "poll_creation_completed"
    case pollOptionCreated = "poll_option_created"
    case pollAnswersViewed = "poll_answers_viewed"
    case pollResultsToggled = "poll_results_toggled"
    
}


public enum LMChatAnalyticsKeys: String {
    case chatroomId = "chatroom_id"
    case chatroomName = "chatroom_name"
    case chatroomTitle = "chatroom_title"
    case chatroomType = "chatroom_type"
    case communityName = "community_name"
    case conversationId = "conversation_id"
    case pollOptionId = "poll_option_id"
    case messageId = "message_id"
    case communityId = "community_id"
    case uuid = "uuid"
    case source = "source"
    case receiver
    case status
    case senderId = "sender_user_id"
    case reported
    case reportedReason = "reported reason"
    case blockedUser = "blocked user"
}


public enum LMChatAnalyticsSource: String {
    case messageReactionsFromLongPress = "long press"
    case messageReactionsFromReactionButton = "reaction button"
    case communityTab = "community_tab"
    case homeFeed = "home_feed"
    case exploreFeed = "explore_feed"
    case notification = "notification"
    case deepLink = "deep_link"
    case pollResult = "poll_result"
    case messageReactions = "message_reactions"
    case directMessagesScreen = "direct_messages_screen"
}
