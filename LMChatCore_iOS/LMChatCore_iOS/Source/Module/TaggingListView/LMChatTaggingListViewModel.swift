//
//  LMChatTaggingListViewModel.swift
//  lm-feedCore-iOS
//
//  Created by Devansh Mohata on 11/01/24.
//

import LikeMindsChat
import LikeMindsChatUI

public protocol LMChatTaggingListViewModelProtocol: AnyObject { 
    func updateList(with users: [LMChatTaggingUserTableCell.ViewModel])
}

public final class LMChatTaggingListViewModel {
    // MARK: Data Variables
    public var currentPage: Int
    public let pageSize: Int
    public var isFetching: Bool
    public var isLastPage: Bool
    public var searchString: String
    public var chatroomId: String
    public var taggedUsers: [LMChatTagUser]
    public var debounerTimer: Timer?
    public let debounceTime: TimeInterval
    public var shouldFetchNames: Bool
    public weak var delegate: LMChatTaggingListViewModelProtocol?
    
    
    // MARK: Init
    init(delegate: LMChatTaggingListViewModelProtocol?) {
        self.currentPage = 1
        self.pageSize = 20
        self.isFetching = false
        self.isLastPage = false
        self.searchString = ""
        self.taggedUsers = []
        self.debounceTime = 0.5
        self.shouldFetchNames = true
        self.delegate = delegate
        self.chatroomId = ""
    }

    func stopFetchingUsers() {
        isFetching = false
        shouldFetchNames = false
        taggedUsers.removeAll(keepingCapacity: true)
        debounerTimer?.invalidate()
        delegate?.updateList(with: [])
    }
    
    func fetchUsers(with searchString: String, chatroomId: String) {
        self.searchString = searchString
        self.chatroomId = chatroomId
        shouldFetchNames = true
        debounerTimer?.invalidate()
        debounerTimer = Timer.scheduledTimer(withTimeInterval: debounceTime, repeats: false) { [weak self] _ in
            guard let self else { return }
            currentPage = 1
            isLastPage = false
            taggedUsers.removeAll()
            fetchTaggingList(searchString, chatroomId)
        }
    }
    
    func fetchMoreUsers() {
        guard !isFetching,
              !isLastPage else { return }
        fetchTaggingList(searchString, chatroomId)
    }
    
    private func fetchTaggingList(_ searchString: String, _ chatroomId: String) {
        isFetching = true
        let request = GetTaggingListRequest.Builder()
            .searchName(searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
            .chatroomId(chatroomId)
            .page(currentPage)
            .pageSize(pageSize)
            .build()
        LMChatClient.shared.getTaggingList(request: request) { [weak self] response in
            guard let self else { return }
            guard let users = response.data?.communityMembers else { return }
            isLastPage = users.isEmpty
            
            let tempUsers: [LMChatTagUser] = users.compactMap { user in
                return LMChatTagUser(name: user.name ?? "NA", routeUrl: user.route ?? "", userId: user.uuid ?? "")
            }
            
            taggedUsers.append(contentsOf: tempUsers)
            convertToViewModel()
            currentPage += 1
            isFetching = false
        }
    }
    
    private func convertToViewModel() {
        guard shouldFetchNames else { return }
        
        let convertedUsers: [LMChatTaggingUserTableCell.ViewModel] = taggedUsers.map { user in
                .init(userImage: user.image, userName: user.name, route: user.route)
        }
        delegate?.updateList(with: convertedUsers)
    }
}
