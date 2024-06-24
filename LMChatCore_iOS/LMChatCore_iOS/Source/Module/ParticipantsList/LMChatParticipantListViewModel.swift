//
//  LMChatParticipantListViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 16/02/24.
//

import LikeMindsChatUI
import LikeMindsChat

public protocol LMChatParticipantListViewModelProtocol: AnyObject {
    func reloadData(with data: [LMChatParticipantCell.ContentModel])
}

public class LMChatParticipantListViewModel {
    weak var delegate: LMChatParticipantListViewModelProtocol?
    var participants: [Member] = []
    
    private var pageNo: Int
    private let pageSize: Int
    private var totalParticipantCount: Int
    private var isParticipantLoading: Bool
    private var isAllParticipantLoaded: Bool
    
    var chatroomId: String
    var isSecretChatroom: Bool
    var participantsContentModels: [LMChatParticipantCell.ContentModel] = []
    
    var searchedText: String?
    var chatroomActionData: GetChatroomActionsResponse?
    
    init(_ viewController: LMChatParticipantListViewModelProtocol, chatroomId: String, isSecret: Bool) {
        self.delegate = viewController
        self.chatroomId = chatroomId
        self.isSecretChatroom = isSecret
        
        self.pageNo = 1
        self.pageSize = 20
        self.totalParticipantCount = .zero
        self.isParticipantLoading = false
        self.isAllParticipantLoaded = false
    }
    
    public static func createModule(withChatroomId chatroomId: String, isSecretChatroom isSecret: Bool = false) throws -> LMChatParticipantListViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        let viewController = LMCoreComponents.shared.participantListScreen.init()
        viewController.viewModel = LMChatParticipantListViewModel(viewController, chatroomId: chatroomId, isSecret: isSecret)
        return viewController
    }
    
    func getParticipants() {
        guard !isParticipantLoading else { return }
        
        isParticipantLoading = true
        
        let request = GetParticipantsRequest.builder()
            .chatroomId(chatroomId)
            .page(pageNo)
            .pageSize(pageSize)
            .participantName(searchedText)
            .isChatroomSecret(isSecretChatroom)
            .build()
        
        LMChatClient.shared.getParticipants(request: request) {[weak self] response in
            guard let self, 
                    let participantsData = response.data?.participants,
                  !participantsData.isEmpty else {
                self?.isParticipantLoading = false
                return
            }
            
            totalParticipantCount = response.data?.totalParticipantsCount ?? 0
            pageNo += 1
            participants.append(contentsOf: participantsData)
            participantsContentModels.append(contentsOf: participantsData.compactMap({
                .init(id: $0.sdkClientInfo?.uuid, name: $0.name ?? "", designationDetail: nil, profileImageUrl: $0.imageUrl, customTitle: $0.customTitle)
            }))
            delegate?.reloadData(with: participantsContentModels)
            isAllParticipantLoaded = (totalParticipantCount == participants.count)
            isParticipantLoading = false
        }
    }
    
    func fetchChatroomData() {
        let request = GetChatroomActionsRequest.builder()
            .chatroomId(chatroomId)
            .build()
        LMChatClient.shared.getChatroomActions(request: request) { [weak self] response in
            guard let self,
                  let actionsData = response.data else { return }
            self.chatroomActionData = actionsData
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.delegate?.reloadData(with: self.participantsContentModels)
            }
        }
    }
    
    func searchParticipants(_ searchText: String?) {
        guard !isParticipantLoading else { return }
        isParticipantLoading = true
        pageNo = 1
        self.searchedText = searchText
        
        participants.removeAll(keepingCapacity: true)
        participantsContentModels.removeAll(keepingCapacity: true)
        
        let request = GetParticipantsRequest.builder()
            .chatroomId(chatroomId)
            .page(pageNo)
            .pageSize(pageSize)
            .participantName(searchedText)
            .isChatroomSecret(isSecretChatroom)
            .build()
        
        LMChatClient.shared.getParticipants(request: request) { [weak self] response in
            self?.isParticipantLoading = false
            
            guard let self else { return }
            
            let participantsData = response.data?.participants ?? []
            
            totalParticipantCount = response.data?.totalParticipantsCount ?? 0
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
