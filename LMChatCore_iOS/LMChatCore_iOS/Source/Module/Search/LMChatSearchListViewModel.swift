//
//  LMChatSearchListViewModel.swift
//  LikeMindsChatCore
//
//  Created by Devansh Mohata on 16/04/24.
//

import LikeMindsChat
import Foundation
import LikeMindsChatUI

public protocol LMChatSearchListViewProtocol: AnyObject {
    func updateSearchList(with data: [LMChatSearchListViewController.ContentModel])
    func showHideFooterLoader(isShow: Bool)
}

final public class LMChatSearchListViewModel: LMChatBaseViewModel {
    public enum APIStatus {
        case headerChatroomFollowTrue
        case headerChatroomFollowFalse
        case titleChatroomFollowTrue
        case conversationFollowTrue
        case titleChatroomFollowFalse
        case conversationFollowFalse
        
        var followStatus: Bool {
            switch self {
            case .headerChatroomFollowTrue,
                    .titleChatroomFollowTrue,
                    .conversationFollowTrue:
                return true
            case .headerChatroomFollowFalse,
                    .titleChatroomFollowFalse,
                    .conversationFollowFalse:
                return false
            }
        }
        
        var searchType: String {
            switch self {
            case .headerChatroomFollowTrue,
                    .headerChatroomFollowFalse:
                return "header"
            case .titleChatroomFollowTrue,
                    .titleChatroomFollowFalse:
                return "title"
            case .conversationFollowTrue,
                    .conversationFollowFalse:
                return ""
            }
        }
    }
    
    public static func createModule() throws -> LMChatSearchListViewController {
        guard LMChatCore.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewcontroller = LMCoreComponents.shared.searchListScreen.init()
        let viewmodel = LMChatSearchListViewModel(delegate: viewcontroller)
        viewcontroller.viewmodel = viewmodel
        
        return viewcontroller
    }
    
    var delegate: LMChatSearchListViewProtocol?
    
    var headerChatroomData: [LMChatSearchChatroomDataModel]
    var titleFollowedChatroomData: [LMChatSearchChatroomDataModel]
    var titleNotFollowedChatroomData: [LMChatSearchChatroomDataModel]
    var followedConversationData: [LMChatSearchConversationDataModel]
    var notFollowedConversationData: [LMChatSearchConversationDataModel]
    
    private var searchString: String
    private var currentAPIStatus: APIStatus
    private var currentPage: Int
    private let pageSize: Int
    private var isAPICallInProgress: Bool
    private var shouldAllowAPICall: Bool
    
    init(delegate: LMChatSearchListViewProtocol? = nil) {
        self.delegate = delegate
        
        headerChatroomData = []
        titleFollowedChatroomData = []
        titleNotFollowedChatroomData = []
        followedConversationData = []
        notFollowedConversationData = []
        
        searchString = ""
        currentAPIStatus = .headerChatroomFollowTrue
        currentPage = 1
        pageSize = 10
        
        isAPICallInProgress = false
        shouldAllowAPICall = true
    }
    
    func searchList(with searchString: String) {
        self.searchString = searchString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        headerChatroomData.removeAll(keepingCapacity: true)
        titleFollowedChatroomData.removeAll(keepingCapacity: true)
        titleNotFollowedChatroomData.removeAll(keepingCapacity: true)
        followedConversationData.removeAll(keepingCapacity: true)
        notFollowedConversationData.removeAll(keepingCapacity: true)
        
        guard !self.searchString.isEmpty else {
            delegate?.showHideFooterLoader(isShow: false)
            return
        }
        
        shouldAllowAPICall = true
        isAPICallInProgress = false
        currentAPIStatus = .headerChatroomFollowTrue
        currentPage = 1
        fetchData(searchString: searchString)
    }
    
    func fetchMoreData() {
        fetchData(searchString: searchString)
    }
    
    private func setNewAPIStatus() {
        // This means we have fetched all available data, no need to progress further
        if currentAPIStatus == .conversationFollowFalse {
            shouldAllowAPICall = false
            convertToContentModel()
            return
        }
        
        currentPage = 1
        
        if currentAPIStatus == .headerChatroomFollowTrue {
            currentAPIStatus = .headerChatroomFollowFalse
        } else if currentAPIStatus == .headerChatroomFollowFalse {
            currentAPIStatus = .titleChatroomFollowTrue
        } else if currentAPIStatus == .titleChatroomFollowTrue {
            currentAPIStatus = .conversationFollowTrue
        } else if currentAPIStatus == .conversationFollowTrue {
            currentAPIStatus = .titleChatroomFollowFalse
        } else if currentAPIStatus == .titleChatroomFollowFalse {
            currentAPIStatus = .conversationFollowFalse
        }
        
        fetchMoreData()
    }
    
    private func fetchData(searchString: String) {
        guard !isAPICallInProgress,
              shouldAllowAPICall else {
            delegate?.showHideFooterLoader(isShow: false)
            return
    }
        
        isAPICallInProgress = true
        
        switch currentAPIStatus {
        case .headerChatroomFollowTrue,
                .headerChatroomFollowFalse,
                .titleChatroomFollowTrue,
                .titleChatroomFollowFalse:
            searchChatroomList(searchString: searchString, isFollowed: currentAPIStatus.followStatus, searchType: currentAPIStatus.searchType)
        case .conversationFollowTrue,
                .conversationFollowFalse:
            searchConversationList(searchString: searchString, followStatus: currentAPIStatus.followStatus)
        }
    }
    
    
    // MARK: API CALL
    private func searchChatroomList(searchString: String, isFollowed: Bool, searchType: String) {
        let request = SearchChatroomRequest.builder()
            .followStatus(isFollowed)
            .page(currentPage)
            .pageSize(pageSize)
            .search(searchString)
            .searchType(searchType)
            .build()
        
        LMChatClient.shared.searchChatroom(request: request) { [weak self] response in
            self?.isAPICallInProgress = false
            self?.delegate?.showHideFooterLoader(isShow: false)
            
            guard let self,
                  let chatrooms = response.data?.conversations else {
                self?.convertToContentModel()
                return
            }
            
            currentPage += 1
            
            let chatroomData: [LMChatSearchChatroomDataModel] = chatrooms.compactMap { chatroom in
                self.convertToChatroomData(from: chatroom.chatroom, member: chatroom.member)
            }
            
            switch currentAPIStatus {
            case .headerChatroomFollowTrue,
                    .headerChatroomFollowFalse:
                headerChatroomData.append(contentsOf: chatroomData)
            case .titleChatroomFollowTrue:
                titleFollowedChatroomData.append(contentsOf: chatroomData)
            case .titleChatroomFollowFalse:
                titleNotFollowedChatroomData.append(contentsOf: chatroomData)
            default:
                break
            }
            
            if chatrooms.count < pageSize {
                setNewAPIStatus()
            } else {
                convertToContentModel()
            }
        }
    }
    
    private func convertToChatroomData(from chatroom: _Chatroom_?, member: Member?) -> LMChatSearchChatroomDataModel? {
        guard let chatroom,
              let id = chatroom.id,
              let user = generateUserDetails(from: member) else { return .none }
        
        return .init(
            id: id,
            chatroomTitle: chatroom.header ?? "",
            chatroomImage: chatroom.chatroomImageUrl,
            isFollowed: chatroom.followStatus ?? false,
            title: chatroom.title,
            createdAt: Double(chatroom.createdAt ?? "") ?? 0,
            user: user
        )
    }
    
    private func searchConversationList(searchString: String, followStatus: Bool) {
        let request = SearchConversationRequest.builder()
            .search(searchString)
            .page(currentPage)
            .pageSize(pageSize)
            .followStatus(followStatus)
            .build()
        
        LMChatClient.shared.searchConversation(request: request) { [weak self] response in
            self?.isAPICallInProgress = false
            self?.delegate?.showHideFooterLoader(isShow: false)
            
            guard let self,
                  let conversations = response.data?.conversations else {
                self?.convertToContentModel()
                return
            }
            
            currentPage += 1
            
            let conversationData: [LMChatSearchConversationDataModel] = conversations.compactMap { conversation in
                guard let chatroomData = self.convertToChatroomData(from: conversation.chatroom, member: conversation.member) else { return .none }

                return .init(
                    id: "\(conversation.id)",
                    chatroomDetails: chatroomData,
                    message: conversation.answer,
                    createdAt: conversation.createdAt,
                    updatedAt: conversation.lastUpdated
                )
            }
                        
            switch currentAPIStatus {
            case .conversationFollowTrue:
                followedConversationData.append(contentsOf: conversationData)
            case .conversationFollowFalse:
                notFollowedConversationData.append(contentsOf: conversationData)
            default:
                break
            }
            
            if conversations.count < pageSize {
                setNewAPIStatus()
            } else {
                convertToContentModel()
            }
        }
    }
    
    private func generateUserDetails(from data: Member?) -> LMChatSearchListUserDataModel? {
        guard let data,
              let uuid = data.sdkClientInfo?.uuid else { return .none }
        
        return .init(uuid: uuid, username: data.name ?? "User", imageURL: data.imageUrl, isGuest: data.isGuest)
    }
    
    func trackEventBasicParams(chatroomId: String) -> [String: AnyHashable] {
        [LMChatAnalyticsKeys.chatroomId.rawValue: chatroomId,
         LMChatAnalyticsKeys.communityId.rawValue: getCommunityId(),
         LMChatAnalyticsKeys.communityName.rawValue: getCommunityName()]
    }
}


// MARK: Convert To Content Model
extension LMChatSearchListViewModel {
    func convertToContentModel() {
        var dataModel: [LMChatSearchListViewController.ContentModel] = []
        
        if !headerChatroomData.isEmpty {
            let followedChatroomConverted = convertChatroomCell(from: headerChatroomData)
            dataModel.append(.init(title: nil, data: followedChatroomConverted))
        }
        
        if !titleFollowedChatroomData.isEmpty || !titleNotFollowedChatroomData.isEmpty || !followedConversationData.isEmpty || !notFollowedConversationData.isEmpty {
            
            let titleFollowedData = convertTitleMessageCell(from: titleFollowedChatroomData, isJoined: true)
            let followedConversationData = convertMessageCell(from: followedConversationData, isJoined: true)
            let titleNotFollowedData = convertTitleMessageCell(from: titleNotFollowedChatroomData, isJoined: false)
            let notFollowedConversationData = convertMessageCell(from: notFollowedConversationData, isJoined: false)
            
            var sectionData: [LMChatSearchCellDataProtocol] = []
            
            sectionData.append(contentsOf: titleFollowedData)
            sectionData.append(contentsOf: followedConversationData)
            sectionData.append(contentsOf: titleNotFollowedData)
            sectionData.append(contentsOf: notFollowedConversationData)
            
            dataModel.append(.init(title: "Messages", data: sectionData))
        }
        
        delegate?.updateSearchList(with: dataModel)
    }
    
    private func convertChatroomCell(from data: [LMChatSearchChatroomDataModel]) -> [LMChatSearchChatroomCell.ContentModel] {
        data.map {
            .init(chatroomID: $0.id, image: $0.chatroomImage, chatroomName: $0.chatroomTitle)
        }
    }
    
    private func convertTitleMessageCell(from data: [LMChatSearchChatroomDataModel], isJoined: Bool) -> [LMChatSearchMessageCell.ContentModel] {
        data.map {
            .init(
                chatroomID: $0.id,
                messageID: nil,
                chatroomName: $0.chatroomTitle,
                message: $0.title ?? "",
                senderName: $0.user.firstName,
                date: $0.createdAt,
                isJoined: isJoined,
                highlightedText: searchString
            )
        }
    }
    
    private func convertMessageCell(from data: [LMChatSearchConversationDataModel], isJoined: Bool) -> [LMChatSearchMessageCell.ContentModel] {
        data.map {
            .init(
                chatroomID: $0.chatroomDetails.id,
                messageID: $0.id,
                chatroomName: $0.chatroomDetails.chatroomTitle,
                message: $0.message,
                senderName: $0.chatroomDetails.user.firstName,
                date: $0.updatedAt,
                isJoined: isJoined,
                highlightedText: searchString
            )
        }
    }
}
