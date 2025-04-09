//
//  LMCommunityChatViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/02/24.
//

import Foundation
import LikeMindsChatData
import LikeMindsChatUI

public protocol LMCommunityChatViewModelProtocol: AnyObject {
    func reloadData()
    func updateHomeFeedChatroomsData()
    func updateHomeFeedExploreCountData()
    func updateHomeFeedSecretChatroomInvitesData(chatroomId: String?)
}

public class LMChatBaseViewModel {

    func getCommunityId() -> String {
        SDKPreferences.shared.getCommunityId() ?? ""
    }

    func getCommunityName() -> String {
        SDKPreferences.shared.getCommunityName() ?? ""
    }
}

public class LMCommunityChatViewModel: LMChatBaseViewModel {

    weak var delegate: LMCommunityChatViewModelProtocol?
    var chatrooms: [Chatroom] = []
    var exploreTabCountData: GetExploreTabCountResponse?
    var secretChatroomInvites: [ChannelInvite] = []
    var memberProfile: User?

    var secretChatroomInvitesPageCount = 1

    init(_ viewController: LMCommunityChatViewModelProtocol) {
        self.delegate = viewController
    }

    public static func createModule() throws -> LMCommunityChatViewController {
        guard LMChatCore.isInitialized else {
            throw LMChatError.chatNotInitialized
        }

        let viewController = LMCoreComponents.shared.groupChatFeedScreen.init()
        viewController.viewModel = LMCommunityChatViewModel(viewController)
        return viewController
    }

    func fetchUserProfile() {
        memberProfile = LMChatClient.shared.getLoggedInUser()
    }

    func getChatrooms() {
        fetchUserProfile()
        LMChatClient.shared.getChatrooms(withObserver: self)
        LMChatClient.shared.observeLiveHomeFeed(
            withCommunityId: SDKPreferences.shared.getCommunityId() ?? "")
    }

    func syncChatroom() {
        LMChatClient.shared.syncChatrooms()
    }

    func getExploreTabCount() {
        LMChatClient.shared.getExploreTabCount { [weak self] response in
            guard let exploreTabCountData = response.data else { return }
            self?.exploreTabCountData = exploreTabCountData
            self?.delegate?.updateHomeFeedExploreCountData()
        }
    }

    /// Retrieves secret chatroom channel invites from the server and appends them to the
    /// existing `secretChatroomInvites` array. If the received invites are fewer than 20,
    /// it increments the page count and calls `getChannelInvites()` again to fetch more.
    ///
    /// This function uses pagination to gather all channel invites (in pages of size 20).
    /// It leverages the `LMChatClient` to make a network request, and updates the local
    /// `secretChatroomInvites` storage as well as notifies a delegate about the new data.
    func getChannelInvites() {
        // 1. Build the request for channel invites, specifying channel type and pagination info.
        let request: GetChannelInvitesRequest =
            GetChannelInvitesRequest.builder()
            .channelType(1)  // channelType(1) could mean chats
            .page(secretChatroomInvitesPageCount)  // current page number
            .pageSize(20)  // fetch 20 invites per page
            .build()

        // 2. Make the network call via the chat client, passing in our constructed request.
        //    The response is handled in a closure (with [weak self] to avoid strong reference cycles).
        LMChatClient.shared.getChannelInvites(request: request) {
            [weak self] response in

            // 3. Ensure the response data exists. If it's nil, just return (no further action).
            guard let secretChatroomInvitesResponse = response.data else {
                return
            }

            // 4. Append the newly fetched channel invites to our local array.
            self?.secretChatroomInvites.append(
                contentsOf: secretChatroomInvitesResponse.channelInvites
            )

            // 5. Notify our delegate that there are new secret chatroom invites available.
            self?.delegate?.updateHomeFeedSecretChatroomInvitesData(
                chatroomId: nil)

            // 6. Check if the number of fetched invites is less than 20.
            //    If so, increment the page count and recursively call `getChannelInvites()`
            //    to fetch additional invites (next page).
            if secretChatroomInvitesResponse.channelInvites.count < 20 {
                return
            } else {
                self?.secretChatroomInvitesPageCount += 1
                self?.getChannelInvites()
            }
        }
    }

    /// Updates the invite status for a specific channel.
    ///
    /// This method sends a request to update the invite status for a given channel
    /// using the provided `channelId` and `inviteStatus`. Upon successful completion,
    /// it notifies the delegate to update the corresponding cell. In case of failure,
    /// an error handling mechanism can be added to notify the user.
    ///
    /// - Parameters:
    ///   - channelId: The unique identifier of the channel whose invite status needs to be updated.
    ///   - inviteStatus: The new status of the invite, represented as a `ChannelInviteStatus` enum.
    func updateChannelInvite(
        channelInvite: LMChatHomeFeedSecretChatroomInviteCell.ContentModel,
        inviteStatus: ChannelInviteStatus
    ) {
        // Create a request to update the channel invite
        let request: UpdateChannelInviteRequest =
            UpdateChannelInviteRequest.builder()
            .channelId(channelInvite.chatroom.id)  // Set the channel ID in the request
            .inviteStatus(inviteStatus)  // Set the desired invite status in the request
            .build()  // Finalize the request object

        // Use the shared chat client to perform the update operation
        LMChatClient.shared.updateChannelInvite(request: request) { response in
            // Check if the response indicates success
            if response.success {
                // Notify the delegate to update the corresponding cell in the UI
                self.secretChatroomInvites.removeAll { invite in
                    invite.id == channelInvite.id
                }

                self.delegate?.updateHomeFeedSecretChatroomInvitesData(
                    chatroomId: inviteStatus == ChannelInviteStatus.accepted
                        ? channelInvite.chatroom.id : nil)
            } else {
                // TODO: Handle the failure case
                // Suggestion: Show an error message to inform the user about the failure
            }
        }
    }

    func reloadChatroomsData(data: [Chatroom]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.chatrooms = data
            self?.chatrooms.sort(by: {
                ($0.lastConversation?.createdEpoch ?? 0)
                    > ($1.lastConversation?.createdEpoch ?? 0)
            })
            self?.delegate?.updateHomeFeedChatroomsData()
        }
    }

    func updateChatroomsData(data: [Chatroom]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            for item in data {
                if let firstIndex = self?.chatrooms.firstIndex(where: {
                    $0.id == item.id
                }) {
                    if item.followStatus == false {
                        self?.chatrooms.remove(at: firstIndex)
                        continue
                    }
                    self?.chatrooms[firstIndex] = item
                } else {
                    self?.chatrooms.append(item)
                }
            }
            self?.chatrooms.sort(by: {
                ($0.lastConversation?.createdEpoch ?? 0)
                    > ($1.lastConversation?.createdEpoch ?? 0)
            })
            self?.delegate?.updateHomeFeedChatroomsData()
        }
    }

    func chatroomContentView(chatroom: Chatroom?)
        -> LMChatHomeFeedChatroomView.ContentModel
    {
        let lastConversation = chatroom?.lastConversation
        let isLoggedInUser =
            lastConversation?.member?.sdkClientInfo?.uuid
            == UserPreferences.shared.getClientUUID()
        let creatorName =
            isLoggedInUser
            ? "You"
            : (lastConversation?.member?.name ?? "").components(
                separatedBy: " "
            ).first ?? ""
        var lastMessage = chatroom?.lastConversation?.answer ?? ""
        lastMessage =
            GetAttributedTextWithRoutes.getAttributedText(from: lastMessage)
            .string

        return LMChatHomeFeedChatroomView.ContentModel(
            userName: creatorName,
            lastMessage: lastMessage,
            lastConversation: chatroom?.lastConversation?.toViewData(
                memberTitle: chatroom?.lastConversation?.member?
                    .communityManager(),
                message: lastMessage,
                createdBy: chatroom?.lastConversation?.member?.sdkClientInfo?
                    .uuid
                    != UserPreferences.shared.getClientUUID()
                    ? chatroom?.lastConversation?.member?.name : "You",
                isIncoming: chatroom?.lastConversation?.member?.sdkClientInfo?
                    .uuid != UserPreferences.shared.getClientUUID(),
                messageType: chatroom?.lastConversation?.state.rawValue,
                messageStatus: nil,
                hideLeftProfileImage: false,
                createdTime: LMCoreTimeUtils.timestampConverted(
                    withEpoch: chatroom?.lastConversation?.createdEpoch ?? 0),
                replyConversation: nil
            ),
            chatroomName: chatroom?.header ?? "",
            chatroomImageUrl: chatroom?.chatroomImageUrl,
            isMuted: chatroom?.muteStatus ?? false,
            isSecret: chatroom?.isSecret ?? false,
            isAnnouncementRoom: chatroom?.type == ChatroomType.purpose,
            unreadCount: chatroom?.unseenCount ?? 0,
            timestamp: LMCoreTimeUtils.timestampConverted(
                withEpoch: lastConversation?.createdEpoch ?? 0,
                withOnlyTime: false) ?? "",
            fileTypeWithCount: getAttachmentType(chatroom: chatroom),
            messageType: chatroom?.lastConversation?.state.rawValue ?? 0,
            isContainOgTags: lastConversation?.ogTags != nil)
    }

    func getAttachmentType(chatroom: Chatroom?) -> [(String, Int)] {
        guard let attachments = chatroom?.lastConversation?.attachments else {
            return []
        }
        let attachmentTypes = attachments.compactMap({ $0.type }).unique()
        let groupedBy = Dictionary(grouping: attachments, by: { $0.type })
        var typeArray: [(String, Int)] = []
        for atType in attachmentTypes {
            typeArray.append((atType.rawValue, groupedBy[atType]?.count ?? 0))
        }
        typeArray =
            ((typeArray.count) > 0)
            ? typeArray
            : ((chatroom?.lastConversation?.ogTags != nil) ? [("link", 0)] : [])
        return typeArray
    }

}

extension LMCommunityChatViewModel: HomeFeedClientObserver {

    public func initial(_ chatrooms: [Chatroom]) {
        reloadChatroomsData(data: chatrooms)
    }

    public func onChange(
        removed: [Chatroom], inserted: [(Int, Chatroom)],
        updated: [(Int, Chatroom)]
    ) {
        if !updated.isEmpty {
            updateChatroomsData(data: updated.compactMap({ $0.1 }))
        } else if !inserted.isEmpty {
            updateChatroomsData(data: inserted.compactMap({ $0.1 }))
        } else if !removed.isEmpty {
            reloadChatroomsData(data: removed)
        }
    }
}
