//
//  LMChatPollResultListViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 30/07/24.
//

import LikeMindsChat
import LikeMindsChatUI

public protocol LMChatPollResultListViewModelProtocol: LMBaseViewControllerProtocol {
    func reloadResults(with userList: [LMChatParticipantCell.ContentModel])
    func showLoader()
    func showHideTableFooter(isShow: Bool)
}

public final class LMChatPollResultListViewModel {
    let pollId: String
    let optionId: String
    var pageNo: Int
    let pageSize: Int
    var isFetching: Bool
    var userList: [LMChatUserDataModel]
    weak var delegate: LMChatPollResultListViewModelProtocol?
    
    init(pollId: String, optionId: String, delegate: LMChatPollResultListViewModelProtocol?) {
        self.pollId = pollId
        self.optionId = optionId
        self.pageNo = 1
        self.pageSize = 10
        self.isFetching = false
        self.userList = []
        self.delegate = delegate
    }
    
    public static func createModule(for pollId: String, optionId: String) -> LMChatPollResultListScreen {
        let viewcontroller = LMCoreComponents.shared.pollResultList.init()
        
        let viewmodel = Self.init(pollId: pollId, optionId: optionId, delegate: viewcontroller)
        viewcontroller.viewModel = viewmodel
        
        return viewcontroller
    }
    
    public func fetchUserList() {
        guard !isFetching else { return }
        let request = GetPollUsersRequest.builder()
            .conversationId(pollId)
            .pollOptionId(optionId)
            .build()
        LMChatClient.shared.getPollUsers(request: request) {[weak self] response in
            defer {
                self?.isFetching = false
                self?.reloadResults(with: self?.userList ?? [])
            }
            
            if let voterList = response.data?.members {
                var transformedUsers: [LMChatUserDataModel] = []
                voterList.forEach { voter in
                    if let uuid = voter.sdkClientInfo?.uuid {
                        transformedUsers.append(.init(userName: voter.name ?? "", userUUID: uuid, userProfileImage: voter.imageUrl, customTitle: voter.customTitle))
                    }
                }
                self?.userList.append(contentsOf: transformedUsers)
                self?.pageNo += 1
            }
        }
    }

    func reloadResults(with transformedUsers: [LMChatUserDataModel]) {
        userList = transformedUsers
        
        let memberItems: [LMChatParticipantCell.ContentModel] = transformedUsers.map {
            return .init(id: $0.userUUID, name: $0.userName, designationDetail: nil, profileImageUrl: $0.userProfileImage , customTitle: $0.customTitle)
        }
        
        delegate?.reloadResults(with: memberItems)
    }
}
