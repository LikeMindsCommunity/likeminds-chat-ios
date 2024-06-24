//
//  LMChatMemberListViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 20/06/24.
//

import Foundation
import LikeMindsChatUI
import LikeMindsChat

public protocol LMChatMemberListViewModelProtocol: AnyObject {
    func reloadData(with data: [LMChatParticipantCell.ContentModel])
}

public class LMChatMemberListViewModel {
    weak var delegate: LMChatMemberListViewModelProtocol?
    var participants: [Member] = []
    
    private var pageNo: Int
    private let pageSize: Int
    var totalParticipantCount: Int
    private var isParticipantLoading: Bool
    private var isAllParticipantLoaded: Bool
    private var searchTime: Timer?
    private var showList: Int?

    var participantsContentModels: [LMChatParticipantCell.ContentModel] = []
    
    var searchedText: String?
    var searchMemberStates: [Int]?
    var filterMemberRoles: [GetAllMembersRequest.MemberTypes] = []
    
    init(_ viewController: LMChatMemberListViewModelProtocol, showList: Int?) {
        self.delegate = viewController
        self.showList = showList
        self.pageNo = 1
        self.pageSize = 20
        self.totalParticipantCount = .zero
        self.isParticipantLoading = false
        self.isAllParticipantLoaded = false
        self.validateShowList()
    }
    
    public static func createModule(showList: Int?) throws -> LMChatMemberListViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        let viewController = LMCoreComponents.shared.dmMemberListScreen.init()
        viewController.viewModel = LMChatMemberListViewModel(viewController, showList: showList)
        return viewController
    }
    
    func validateShowList() {
        guard let showList else { return }
        if showList == 1 {
            filterMemberRoles = [.member, .admin]
            searchMemberStates = [1, 4]
        } else if showList == 2 {
            filterMemberRoles = [.admin]
            searchMemberStates = [1]
        }
    }
    
    func getParticipants() {
        guard !isParticipantLoading, let showList else { return }
        
        if let searchedText, !searchedText.isEmpty {
            searchMembers(searchedText)
            return
        }
        
        isParticipantLoading = true
        
        let request = GetAllMembersRequest.builder()
            .page(pageNo)
            .pageSize(pageSize)
            .filterMemberRoles(filterMemberRoles)
            .excludeSelfUser(true)
            .build()
        
        LMChatClient.shared.getAllMembers(request: request) {[weak self] response in
            guard let self,
                  let participantsData = response.data?.members,
                  !participantsData.isEmpty else {
                self?.isParticipantLoading = false
                return
            }
            if showList == 1 {
                totalParticipantCount = (response.data?.membersCount ?? 0) + (response.data?.adminsCount ?? 0)
            } else {
                totalParticipantCount = (response.data?.adminsCount ?? 0)
            }
            if pageNo == 1 {
                participants.removeAll(keepingCapacity: true)
                participantsContentModels.removeAll(keepingCapacity: true)
            }
            participants.append(contentsOf: participantsData)
            participantsContentModels.append(contentsOf: participantsData.compactMap({
                .init(id: $0.sdkClientInfo?.uuid, name: $0.name ?? "", designationDetail: nil, profileImageUrl: $0.imageUrl, customTitle: $0.customTitle)
            }))
            pageNo += 1
            delegate?.reloadData(with: participantsContentModels)
            isAllParticipantLoaded = (totalParticipantCount == participants.count)
            isParticipantLoading = false
        }
    }
    
    func searchParticipants(_ searchText: String?) {
        guard !isParticipantLoading, let searchText, !searchText.isEmpty else {
            searchedText = nil
            pageNo = 1
            getParticipants()
            return
        }
        if searchText == searchedText { return }
        searchTime?.invalidate()
        searchTime = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { [weak self] (timer) in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self else {return}
                isParticipantLoading = true
                searchedText = searchText
                pageNo = 1
                participants.removeAll(keepingCapacity: true)
                participantsContentModels.removeAll(keepingCapacity: true)
                searchMembers(searchText)
            }
        })
    }
    
    func searchMembers(_ searchText: String) {
        isParticipantLoading = true
        let request = SearchMembersRequest.builder()
            .searchType("name")
            .page(pageNo)
            .memberState(searchMemberStates)
            .search(searchText)
            .pageSize(pageSize)
            .excludeSelfUser(true)
            .build()
        LMChatClient.shared.searchMembers(request: request) { [weak self] response in
            self?.isParticipantLoading = false
            
            guard let self else { return }
            
            let participantsData = response.data?.members ?? []
            
            totalParticipantCount = response.data?.members?.count ?? 0
            pageNo += participantsData.isEmpty ? 0 : 1
            
            participants.append(contentsOf: participantsData)
            participantsContentModels.append(contentsOf: participantsData.compactMap({
                .init(id: $0.sdkClientInfo?.uuid, name: $0.name ?? "", designationDetail: nil, profileImageUrl: $0.imageUrl, customTitle: $0.customTitle)
            }))
            
            delegate?.reloadData(with: participantsContentModels)
            
            isAllParticipantLoaded = (totalParticipantCount == participants.count)
            isParticipantLoading = false
        }
    }
}
