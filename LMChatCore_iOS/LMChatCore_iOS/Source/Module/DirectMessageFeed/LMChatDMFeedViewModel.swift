//
//  LMChatDMFeedViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 17/06/24.
//

import Foundation
import LikeMindsChatData
import LikeMindsChatUI

public protocol LMChatDMFeedViewModelProtocol: AnyObject {
    func reloadData()
    func updateHomeFeedChatroomsData()
    func updateHomeFeedExploreCountData()
    func checkDMStatus(showDM: Bool)
}

public class LMChatDMFeedViewModel: LMChatBaseViewModel {
    
    weak var delegate: LMChatDMFeedViewModelProtocol?
    var chatrooms: [Chatroom] = []
    var exploreTabCountData: GetExploreTabCountResponse?
    var memberProfile: User?
    var showList: Int?
    
    init(_ viewController: LMChatDMFeedViewModelProtocol) {
        self.delegate = viewController
    }
    
    public static func createModule() throws -> LMChatDMFeedViewController {
        guard LMChatCore.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewController = LMCoreComponents.shared.dmChatFeedScreen.init()
        viewController.viewModel = LMChatDMFeedViewModel(viewController)
        return viewController
    }
    
    func getInitialData() {
        fetchUserProfile()
        getChatrooms()
        syncChatroom()
        checkDMStatus()
    }
    
    func fetchUserProfile() {
        memberProfile = LMChatClient.shared.getLoggedInUser()
    }
    
    func getChatrooms() {
        LMChatClient.shared.getDMChatrooms(withObserver: self)
        LMChatClient.shared.observeLiveDMFeed(withCommunityId: SDKPreferences.shared.getCommunityId() ?? "")
    }
    
    func syncChatroom() {
        LMChatClient.shared.syncDMChatrooms()
    }
    
    func checkDMStatus() {
        let request = CheckDMStatusRequest.builder()
            .requestFrom("dm_feed_v2")
            .uuid(UserPreferences.shared.getClientUUID() ?? "")
            .build()
        LMChatClient.shared.checkDMStatus(request: request) {[weak self] response in
            guard let self, let showDM = response.data?.showDM, let cta = response.data?.cta else { return }
            delegate?.checkDMStatus(showDM: showDM)
            showList = Int(cta.getQueryItems()["show_list"] ?? "")
        }
    }
    
    func checkDMTab() {
        LMChatClient.shared.checkDMTab {[weak self] response in
            guard let data = response.data, data.hideDMTab == false else {
                self?.reloadChatroomsData(data: [])
                return
            }
            self?.getInitialData()
        }
    }

    func reloadChatroomsData(data: [Chatroom]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
            self?.chatrooms = data
            self?.chatrooms.sort(by: {($0.lastConversation?.createdEpoch ?? 0) > ($1.lastConversation?.createdEpoch ?? 0)})
            self?.delegate?.updateHomeFeedChatroomsData()
        }
    }
    
    func updateChatroomsData(data: [Chatroom]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
            for item in data {
                if let firstIndex = self?.chatrooms.firstIndex(where: {$0.id == item.id}) {
                    if item.followStatus == false {
                        self?.chatrooms.remove(at: firstIndex)
                        continue
                    }
                    self?.chatrooms[firstIndex] = item
                } else {
                    self?.chatrooms.append(item)
                }
            }
            self?.chatrooms.sort(by: {($0.lastConversation?.createdEpoch ?? 0) > ($1.lastConversation?.createdEpoch ?? 0)})
            self?.delegate?.updateHomeFeedChatroomsData()
        }
    }
    
    func chatroomContentView(chatroom: Chatroom?) -> LMChatHomeFeedChatroomView.ContentModel {
        let lastConversation = chatroom?.lastConversation
        let isLoggedInUser = lastConversation?.member?.sdkClientInfo?.uuid == UserPreferences.shared.getClientUUID()
        let creatorName = isLoggedInUser ? "You" : (lastConversation?.member?.name ?? "").components(separatedBy: " ").first ?? ""
        var lastMessage = chatroom?.lastConversation?.answer ?? ""
        lastMessage = GetAttributedTextWithRoutes.getAttributedText(from: lastMessage).string
        let directMessageHeader = directMessageTitle(chatroom: chatroom)
        return  LMChatHomeFeedChatroomView.ContentModel(userName: creatorName,
                                                        lastMessage: lastMessage,
                                                        lastConversation: chatroom?.lastConversation?.toViewData(
                                                            memberTitle: chatroom?.lastConversation?.member?.communityManager(),
                                                            message: lastMessage,
                                                            createdBy: chatroom?.lastConversation?.member?.sdkClientInfo?.uuid
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
                                                        chatroomName: directMessageHeader.title,
                                                        chatroomImageUrl: directMessageHeader.imageUrl,
                                                        isMuted: chatroom?.muteStatus ?? false,
                                                        isSecret: chatroom?.isSecret ?? false,
                                                        isAnnouncementRoom: chatroom?.type == ChatroomType.purpose,
                                                        unreadCount: unreadCount(chatroom, isLoggedInUser: isLoggedInUser),
                                                        timestamp: LMCoreTimeUtils.timestampConverted(withEpoch: lastConversation?.createdEpoch ?? 0, withOnlyTime: false) ?? "",
                                                        fileTypeWithCount: getAttachmentType(chatroom: chatroom),
                                                        messageType: chatroom?.lastConversation?.state.rawValue ?? 0,
                                                        isContainOgTags: lastConversation?.ogTags != nil)
    }
    
    func unreadCount(_ chatroom: Chatroom?, isLoggedInUser: Bool) -> Int {
        guard !isLoggedInUser else { return 0 }
        return chatroom?.unseenCount ?? 0
    }
    
    func directMessageTitle(chatroom: Chatroom?) -> (title: String, imageUrl: String?) {
        guard let member = chatroom?.chatWithUser else { return (chatroom?.header ?? "", nil)}
        var dmTitle = member.name ?? ""
        var imageUrl = member.imageUrl
        if let title = member.customTitle {
            dmTitle = dmTitle + " \(Constants.shared.strings.dot) " + "\(title)"
        }
        if UserPreferences.shared.getClientUUID() == member.sdkClientInfo?.uuid {
            dmTitle = chatroom?.member?.name ?? ""
            imageUrl = chatroom?.member?.imageUrl
            if let title = chatroom?.member?.customTitle {
                dmTitle = dmTitle + " \(Constants.shared.strings.dot) " + "\(title)"
            }
        }
        return (dmTitle, imageUrl)
    }
    
    func getAttachmentType(chatroom: Chatroom?) -> [(String, Int)] {
        guard let attachments = chatroom?.lastConversation?.attachments else { return [] }
        let attachmentTypes = attachments.compactMap({$0.type}).unique()
        let groupedBy = Dictionary(grouping: attachments, by: { $0.type })
        var typeArray: [(String, Int)] = []
        for atType in attachmentTypes {
            typeArray.append((atType.rawValue, groupedBy[atType]?.count ?? 0))
        }
        typeArray = ((typeArray.count) > 0) ? typeArray : ((chatroom?.lastConversation?.ogTags != nil) ? [("link", 0)] : [] )
        return typeArray
    }
    
}

extension LMChatDMFeedViewModel: HomeFeedClientObserver {
    
    public func initial(_ chatrooms: [Chatroom]) {
        reloadChatroomsData(data: chatrooms)
    }
    
    public func onChange(removed: [Chatroom], inserted: [(Int, Chatroom)], updated: [(Int, Chatroom)]) {
        if !updated.isEmpty {
            updateChatroomsData(data: updated.compactMap({$0.1}))
        } else if !inserted.isEmpty {
            updateChatroomsData(data: inserted.compactMap({$0.1}))
        } else if !removed.isEmpty {
            reloadChatroomsData(data: removed)
        }
    }
}
