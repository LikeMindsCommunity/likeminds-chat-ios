//
//  LMChatPollResultViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 30/07/24.
//

import LikeMindsChat
import LikeMindsChatUI

public protocol LMChatPollResultViewModelProtocol: LMBaseViewControllerProtocol {
    func setupViewControllers(with pollID: String, optionList: [String], selectedID: Int)
    func loadOptionList(with data: [LMChatPollResultCollectionCell.ContentModel], index: Int)
}

public final class LMChatPollResultViewModel {
    let pollID: String
    var selectedOptionID: String?
    var optionList: [LMChatPollDataModel.Option]
    weak var delegate: LMChatPollResultViewModelProtocol?
    var userList: [LMChatUserDataModel]
    var pageNo: Int
    let pageSize: Int
    var isAPIWorking: Bool
    var shouldCallAPI: Bool {
        didSet {
            print("Value changed: \(shouldCallAPI)")
        }
    }
    
    
    init(pollID: String, selectedOptionID: String? = nil, optionList: [LMChatPollDataModel.Option], delegate: LMChatPollResultViewModelProtocol? = nil) {
        self.pollID = pollID
        self.selectedOptionID = selectedOptionID ?? optionList.first?.id
        self.optionList = optionList
        self.delegate = delegate
        self.pageNo = 1
        self.pageSize = 10
        self.userList = []
        self.isAPIWorking = false
        self.shouldCallAPI = true
    }
    
    public static func createModule(with pollID: String, optionList: [LMChatPollDataModel.Option], selectedOption: String?) throws -> LMChatPollResultScreen {
        guard LMChatCore.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewcontroller = LMCoreComponents.shared.pollResultScreen.init()
        let viewmodel = Self.init(pollID: pollID, selectedOptionID: selectedOption, optionList: optionList, delegate: viewcontroller)
        
        viewcontroller.viewModel = viewmodel
        
        return viewcontroller
    }
    
    public func initializeView() {
        var selectedIndex = 0
        
        let transformedOptions: [LMChatPollResultCollectionCell.ContentModel] = optionList.enumerated().map { id, option in
            if option.id == selectedOptionID {
                selectedIndex = id
            }
            
            return .init(optionID: option.id, title: option.option, voteCount: option.voteCount, isSelected: option.id == selectedOptionID)
        }
        
        delegate?.loadOptionList(with: transformedOptions, index: selectedIndex)
        delegate?.setupViewControllers(with: pollID, optionList: optionList.map(\.id), selectedID: selectedIndex)
    }
}

extension LMChatPollResultViewModel {
    
    func trackEventForPageSwipe(optionId: String) {
        let props = [LMChatAnalyticsKeys.conversationId.rawValue: pollID ,
                     LMChatAnalyticsKeys.messageId.rawValue: pollID,
                     LMChatAnalyticsKeys.pollOptionId.rawValue: optionId,
                     LMChatAnalyticsKeys.communityId.rawValue: SDKPreferences.shared.getCommunityId() ?? "",
                     LMChatAnalyticsKeys.communityName.rawValue: SDKPreferences.shared.getCommunityName() ?? ""]
        LMChatCore.analytics?.trackEvent(for: .pollResultsToggled, eventProperties: props)
    }
}
