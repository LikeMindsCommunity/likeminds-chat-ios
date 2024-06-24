//
//  LMChatDMFeedViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 17/06/24.
//

import Foundation
import LikeMindsChat
import LikeMindsChatUI

public protocol LMChatDMFeedViewModelProtocol: AnyObject {
    func reloadData()
    func updateHomeFeedChatroomsData()
    func updateHomeFeedExploreCountData()
    func checkDMStatus(showDM: Bool)
}

public class LMChatDMFeedViewModel {
    
    weak var delegate: LMChatDMFeedViewModelProtocol?
    var chatrooms: [Chatroom] = []
    var exploreTabCountData: GetExploreTabCountResponse?
    var memberProfile: User?
    var showList: Int?
    
    init(_ viewController: LMChatDMFeedViewModelProtocol) {
        self.delegate = viewController
    }
    
    public static func createModule() throws -> LMChatDMFeedViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewController = LMCoreComponents.shared.dmChatFeedScreen.init()
        viewController.viewModel = LMChatDMFeedViewModel(viewController)
        return viewController
    }
    
    func fetchUserProfile() {
        memberProfile = LMChatClient.shared.getLoggedInUser()
    }
    
    func getChatrooms() {
        fetchUserProfile()
        LMChatClient.shared.getDMChatrooms(withObserver: self)
        LMChatClient.shared.observeLiveHomeFeed(withCommunityId: SDKPreferences.shared.getCommunityId() ?? "")
    }
    
    func syncChatroom() {
        LMChatClient.shared.syncChatrooms()
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
        let fileType = lastConversation?.attachments?.first?.type
        
        return  LMChatHomeFeedChatroomView.ContentModel(userName: creatorName,
                                                        lastMessage: lastMessage,
                                                        chatroomName: directMessageTitle(chatroom: chatroom),
                                                        chatroomImageUrl: chatroom?.chatWithUser?.imageUrl,
                                                        isMuted: chatroom?.muteStatus ?? false,
                                                        isSecret: chatroom?.isSecret ?? false,
                                                        isAnnouncementRoom: chatroom?.type == ChatroomType.purpose.rawValue,
                                                        unreadCount: chatroom?.unseenCount ?? 0,
                                                        timestamp: LMCoreTimeUtils.timestampConverted(withEpoch: lastConversation?.createdEpoch ?? 0, withOnlyTime: false) ?? "",
                                                        fileTypeWithCount: getAttachmentType(chatroom: chatroom),
                                                        messageType: chatroom?.lastConversation?.state.rawValue ?? 0,
                                                        isContainOgTags: lastConversation?.ogTags != nil)
    }
    
    func directMessageTitle(chatroom: Chatroom?) -> String {
        guard let member = chatroom?.chatWithUser else { return chatroom?.header ?? ""}
        var dmTitle = member.name ?? ""
        if let title = member.customTitle {
            dmTitle = dmTitle + " \(Constants.shared.strings.dot) " + "\(title)"
        }
        if UserPreferences.shared.getClientUUID() == member.sdkClientInfo?.uuid {
            dmTitle = chatroom?.member?.name ?? ""
            if let title = chatroom?.member?.customTitle {
                dmTitle = dmTitle + " \(Constants.shared.strings.dot) " + "\(title)"
            }
        }
        return dmTitle
    }
    
    func getAttachmentType(chatroom: Chatroom?) -> [(String, Int)] {
        guard let attachments = chatroom?.lastConversation?.attachments else { return [] }
        let attachmentTypes = attachments.compactMap({$0.type}).unique()
        let groupedBy = Dictionary(grouping: attachments, by: { $0.type })
        var typeArray: [(String, Int)] = []
        for atType in attachmentTypes {
            typeArray.append((atType, groupedBy[atType]?.count ?? 0))
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
