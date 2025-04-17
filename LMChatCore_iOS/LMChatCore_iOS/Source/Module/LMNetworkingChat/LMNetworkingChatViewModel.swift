//
//  LMNetworkingChatViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 17/06/24.
//

import Foundation
import LikeMindsChatData
import LikeMindsChatUI

/// A protocol defining the methods that the view model uses to communicate
/// changes or updates back to its view controller.
public protocol LMNetworkingChatViewModelProtocol: AnyObject {
    /// Reloads the UI data, typically called when a major refresh is needed.
    func reloadData()

    /// Informs the UI to update its chatrooms listing.
    func updateHomeFeedChatroomsData()

    /// Informs the UI to update the count of total/unseen chatrooms (Explore tab).
    func updateHomeFeedExploreCountData()

    /// Updates the UI regarding the visibility of the DM floating action button.
    ///
    /// - Parameter showDM: `true` to show the DM button; `false` to hide it.
    func checkDMStatus(showDM: Bool)
}

/// `LMNetworkingChatViewModel` serves as the data and business logic layer
/// for `LMNetworkingChatViewController`. It retrieves chatroom data,
/// user profile info, and handles real-time updates through observers.
public class LMNetworkingChatViewModel: LMChatBaseViewModel {

    // MARK: - Properties

    /// A weak reference to the delegate conforming to `LMNetworkingChatViewModelProtocol`.
    /// Used to update the UI whenever the data changes.
    weak var delegate: LMNetworkingChatViewModelProtocol?

    /// A list of `Chatroom` objects retrieved from the chat client.
    var chatrooms: [Chatroom] = []

    /// Holds data for the "Explore" tab, including total and unseen chatroom counts.
    var exploreTabCountData: GetExploreTabCountResponse?

    /// Holds the current user’s profile.
    var memberProfile: User?

    /// An integer representing additional configuration on how to show the
    /// DM member list. Value typically extracted from a CTA response.
    var showList: Int?

    // MARK: - Initializer

    /// Creates a new instance of the view model and sets the delegate.
    ///
    /// - Parameter viewController: The class conforming to `LMNetworkingChatViewModelProtocol`.
    init(_ viewController: LMNetworkingChatViewModelProtocol) {
        self.delegate = viewController
    }

    // MARK: - Module Creation

    /// Factory method to create an instance of `LMNetworkingChatViewController`
    /// wired up with an `LMNetworkingChatViewModel`.
    ///
    /// - Throws: `LMChatError.chatNotInitialized` if the chat core is not initialized.
    /// - Returns: An instance of `LMNetworkingChatViewController`.
    public static func createModule() throws -> LMNetworkingChatViewController {
        guard LMChatCore.isInitialized else {
            throw LMChatError.chatNotInitialized
        }
        let viewController = LMCoreComponents.shared.networkingChatScreen.init()
        viewController.viewModel = LMNetworkingChatViewModel(viewController)
        return viewController
    }

    // MARK: - Data Fetching and Initialization

    /// Retrieves the initial data for the chat feed screen:
    /// - Fetches the user profile
    /// - Gets chatrooms
    /// - Syncs chatrooms
    /// - Checks DM status
    func getInitialData() {
        fetchUserProfile()
        getChatrooms()
        syncChatroom()
        checkDMStatus()
    }

    /// Retrieves the current user’s profile from the chat client and
    /// stores it in `memberProfile`.
    func fetchUserProfile() {
        memberProfile = LMChatClient.shared.getLoggedInUser()
    }

    /// Registers this view model as an observer for DM chatrooms and
    /// starts observing live DM feed updates for the community.
    func getChatrooms() {
        
        LMChatClient.shared.getDMChatrooms(withObserver: self)
        LMChatClient.shared.observeLiveDMFeed(
            withCommunityId: SDKPreferences.shared.getCommunityId() ?? "")
    }

    /// Triggers a synchronization of DM chatrooms in the background.
    func syncChatroom() {
        LMChatClient.shared.syncDMChatrooms()
    }

    /// Checks whether the DM feature is enabled for the current user
    /// and updates the UI accordingly. Also extracts configuration data
    /// like `show_list`.
    func checkDMStatus() {
        let request = CheckDMStatusRequest.builder()
            .requestFrom("dm_feed_v2")
            .uuid(UserPreferences.shared.getClientUUID() ?? "")
            .build()

        LMChatClient.shared.checkDMStatus(request: request) {
            [weak self] response in
            guard let self,
                let showDM = response.data?.showDM,
                let cta = response.data?.cta
            else { return }
            delegate?.checkDMStatus(showDM: showDM)
            showList = Int(cta.getQueryItems()["show_list"] ?? "")
        }
    }

    /// Checks if the DM tab should be displayed to the user. If `hideDMTab`
    /// is `true`, it clears chatrooms; otherwise, it re-initializes the data.
    func checkDMTab() {
        LMChatClient.shared.checkDMTab { [weak self] response in
            guard let data = response.data, data.hideDMTab == false else {
                self?.reloadChatroomsData(data: [])
                return
            }
            self?.getInitialData()
        }
    }

    // MARK: - Data Handling

    /// Reloads the chatrooms data and informs the delegate to update the feed.
    /// Sorts chatrooms by the epoch of their last conversation in descending order.
    ///
    /// - Parameter data: The array of `Chatroom` objects to display.
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

    /// Updates the internal list of chatrooms by merging with new or changed data,
    /// then sorts them and instructs the UI to refresh.
    ///
    /// - Parameter data: An array of updated `Chatroom` objects.
    func updateChatroomsData(data: [Chatroom]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            for item in data {
                if let firstIndex = self?.chatrooms.firstIndex(where: {
                    $0.id == item.id
                }) {
                    // If followStatus is false, remove the chatroom
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

    // MARK: - Content Model Helpers

    /// Constructs the content model for a single chatroom cell.
    /// Includes the chatroom title, last message, attachments, etc.
    ///
    /// - Parameter chatroom: The `Chatroom` to convert to a feed cell model.
    /// - Returns: A configured `LMChatHomeFeedChatroomView.ContentModel`.
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

        let directMessageHeader = directMessageTitle(chatroom: chatroom)

        return LMChatHomeFeedChatroomView.ContentModel(
            userName: creatorName,
            lastMessage: lastMessage,
            lastConversation: chatroom?.lastConversation?.toViewData(
                memberTitle: chatroom?.lastConversation?.member?
                    .communityManager(),
                message: lastMessage,
                createdBy: chatroom?.lastConversation?.member?.sdkClientInfo?
                    .uuid != UserPreferences.shared.getClientUUID()
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
            chatroomName: directMessageHeader.title,
            chatroomImageUrl: directMessageHeader.imageUrl,
            isMuted: chatroom?.muteStatus ?? false,
            isSecret: chatroom?.isSecret ?? false,
            isAnnouncementRoom: chatroom?.type == ChatroomType.purpose,
            unreadCount: unreadCount(chatroom, isLoggedInUser: isLoggedInUser),
            timestamp: LMCoreTimeUtils.timestampConverted(
                withEpoch: lastConversation?.createdEpoch ?? 0,
                withOnlyTime: false) ?? "",
            fileTypeWithCount: getAttachmentType(chatroom: chatroom),
            messageType: chatroom?.lastConversation?.state.rawValue ?? 0,
            isContainOgTags: lastConversation?.ogTags != nil
        )
    }

    /// Computes the unread message count for the specified chatroom.
    /// If the last message’s creator is the logged-in user, returns 0.
    ///
    /// - Parameters:
    ///   - chatroom: The `Chatroom` to check.
    ///   - isLoggedInUser: Indicates if the last message was from the logged-in user.
    /// - Returns: The number of unseen messages in the chatroom.
    func unreadCount(_ chatroom: Chatroom?, isLoggedInUser: Bool) -> Int {
        guard !isLoggedInUser else { return 0 }
        return chatroom?.unseenCount ?? 0
    }

    /// Generates a display title and optional image URL for a direct message (DM) chatroom.
    ///
    /// - Parameter chatroom: The optional `Chatroom`.
    /// - Returns: A tuple containing the title and image URL for display.
    func directMessageTitle(chatroom: Chatroom?) -> (
        title: String, imageUrl: String?
    ) {
        guard let member = chatroom?.chatWithUser else {
            return (chatroom?.header ?? "", nil)
        }

        var dmTitle = member.name ?? ""
        var imageUrl = member.imageUrl

        if let title = member.customTitle {
            dmTitle += " \(Constants.shared.strings.dot) \(title)"
        }

        // If the chat with user is the logged-in user themselves
        if UserPreferences.shared.getClientUUID() == member.sdkClientInfo?.uuid
        {
            dmTitle = chatroom?.member?.name ?? ""
            imageUrl = chatroom?.member?.imageUrl
            if let title = chatroom?.member?.customTitle {
                dmTitle += " \(Constants.shared.strings.dot) \(title)"
            }
        }
        return (dmTitle, imageUrl)
    }

    /// Retrieves attachment types (image, video, etc.) from the last conversation
    /// in the chatroom and aggregates the counts.
    ///
    /// - Parameter chatroom: The optional `Chatroom`.
    /// - Returns: An array of tuples `(attachmentType, count)`.
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

        // If no standard attachment is present but we have OG Tags, treat it as a link
        typeArray =
            typeArray.isEmpty
            ? ((chatroom?.lastConversation?.ogTags != nil) ? [("link", 0)] : [])
            : typeArray
        return typeArray
    }
}

// MARK: - HomeFeedClientObserver Conformance

/// Extends the view model to conform to `HomeFeedClientObserver`,
/// allowing it to handle real-time chatroom updates.
extension LMNetworkingChatViewModel: HomeFeedClientObserver {

    /// Called once when chatrooms are initially fetched. Updates the local chatrooms list.
    /// - Parameter chatrooms: The array of `Chatroom` objects.
    public func initial(_ chatrooms: [Chatroom]) {
        reloadChatroomsData(data: chatrooms)
    }

    /// Called whenever there is a change (removal, insertion, or update) in chatrooms.
    /// Merges the changes and updates the UI accordingly.
    ///
    /// - Parameters:
    ///   - removed: An array of removed `Chatroom`s.
    ///   - inserted: An array of tuples containing the position and newly inserted `Chatroom`.
    ///   - updated: An array of tuples containing the position and updated `Chatroom`.
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
