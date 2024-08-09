//
//  LMChatCreatePollViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 16/07/24.
//

import Foundation
import LikeMindsChat
import LikeMindsChatUI


public protocol LMChatCreatePollViewModelProtocol: LMBaseViewControllerProtocol {
    func configure(pollHeaderData: LMChatCreatePollHeader.ContentModel, pollOptionsData: [LMChatCreatePollOptionWidget.ContentModel], metaOptions: LMChatCreatePollMetaView.ContentModel, expiryDate: Date?)
    func updateExpiryDate(with newDate: Date)
    func updatePollOptions(with newData: [LMChatCreatePollOptionWidget.ContentModel])
    func showMetaOptionsPickerView(with data: LMChatGeneralPicker.ContentModel)
    func updateMetaOption(with option: String, count: Int)
    func presentDatePicker(with selectedDate: Date, minimumDate: Date)
    func updatePoll(with data: LMChatCreatePollDataModel)
}

final public class LMChatCreatePollViewModel: LMChatBaseViewModel {
    weak var delegate: LMChatCreatePollViewModelProtocol?
    
    /// minimum poll options to be shown
    let defaultPollAnswerCount: Int
    
    /// poll question
    var pollQuestion: String?
    
    /// number of options in selection
    var currentOptionCount: Int
    
    /// poll option state - `exactly` || `at_max` || `at_least`
    var optionSelectionState: LMChatPollSelectState
    
    /// poll expiry date
    var pollExpiryDate: Date?
    
    /// poll options
    var pollOptions: [String?]
    
    /// is anonymous poll: default is `false`
    var isAnonymousPoll: Bool
    
    /// is instant poll: default is `true`
    var isInstantPoll: Bool
    
    /// allow user to add options: default is `false`
    var allowAddOptions: Bool
    
    init(delegate: LMChatCreatePollViewModelProtocol?, prefilledData: LMChatCreatePollDataModel?) {
        self.delegate = delegate
        self.pollQuestion = prefilledData?.pollQuestion
        self.defaultPollAnswerCount = 2
        self.optionSelectionState = prefilledData?.selectState ?? .exactly
        self.currentOptionCount = prefilledData?.selectStateCount ?? 0
        self.pollOptions = prefilledData?.pollOptions ?? Array(repeating: nil, count: defaultPollAnswerCount)
        self.isAnonymousPoll = prefilledData?.isAnonymous ?? false
        self.isInstantPoll = prefilledData?.isInstantPoll ?? true
        self.allowAddOptions = prefilledData?.allowAddOptions ?? false
        self.pollExpiryDate = prefilledData?.expiryTime
    }
    
    public static func createModule(withDelegate pollDelegate: LMChatCreatePollViewDelegate?, data: LMChatCreatePollDataModel? = nil) throws -> LMChatCreatePollViewController {
        guard LMChatCore.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewcontroller = LMCoreComponents.shared.createPollScreen.init()
        let viewModel = LMChatCreatePollViewModel(delegate: viewcontroller, prefilledData: data)
        
        viewcontroller.viewmodel = viewModel
        viewcontroller.pollDelegate = pollDelegate
        
        return viewcontroller
    }
    
    public func loadInitialData() {
        let userDetails = LMChatClient.shared.getUserDetails()
        
        let pollHeaderData = LMChatCreatePollHeader.ContentModel(
            profileImage: userDetails?.imageUrl,
            username: userDetails?.name ?? "User",
            pollQuestion: pollQuestion
        )
        
        let pollOptions: [LMChatCreatePollOptionWidget.ContentModel] = pollOptions.enumerated().map { id, option in
            return .init(id: id, option: option)
        }
        
        
        var metaOptionsModel: [LMChatCreatePollMetaOptionWidget.ContentModel] = []
        
        LMChatCreatePollDataModel.MetaOptions.allCases.forEach { option in
            let desc = option.description
            switch option {
            case .isAnonymousPoll:
                metaOptionsModel.append(.init(id: option.rawValue, title: desc, isSelected: isAnonymousPoll))
            case .isInstantPoll:
                metaOptionsModel.append(.init(id: option.rawValue, title: desc, isSelected: !isInstantPoll))
            case .allowAddOptions:
                metaOptionsModel.append(.init(id: option.rawValue, title: desc, isSelected: allowAddOptions))
            }
        }
        
        let metaOptionsData: LMChatCreatePollMetaView.ContentModel = .init(
            metaOptions: metaOptionsModel,
            optionState: optionSelectionState.description,
            optionCount: currentOptionCount
        )
        
        
        delegate?.configure(
            pollHeaderData: pollHeaderData,
            pollOptionsData: pollOptions,
            metaOptions: metaOptionsData,
            expiryDate: pollExpiryDate
        )
    }
    
    public func updatePollExpiryDate(with newDate: Date) {
        pollExpiryDate = newDate
        delegate?.updateExpiryDate(with: newDate)
    }
    
    public func removePollOption(at index: Int) {
        guard pollOptions.count > 2,
              pollOptions.indices.contains(index) else { return }
        pollOptions.remove(at: index)
        
        
        if currentOptionCount > pollOptions.count {
            currentOptionCount = 1
            delegate?.updateMetaOption(with: optionSelectionState.description, count: currentOptionCount)
        }
        
        delegate?.updatePollOptions(with: pollOptions.enumerated().map({ .init(id: $0, option: $1) }))
    }
    
    public func insertPollOption() {
        guard pollOptions.count < 10 else {
            delegate?.showError(withTitle: "Error", message: "You can add at max 10 options", isPopVC: false)
            return
        }
        pollOptions.append(nil)
        
        delegate?.updatePollOptions(with: pollOptions.enumerated().map({ .init(id: $0, option: $1) }))
    }
    
    public func updatePollOption(for id: Int, option: String?) {
        guard pollOptions.indices.contains(id) else { return }
        pollOptions[id] = option
    }
    
    public func showMetaOptionsPicker() {
        let optionTypeRow: [String] = LMChatPollSelectState.allCases.map({ $0.description })
        
        var optionCountRow: [String] = []
        
        let count = pollOptions.count
        
        for i in 1...count {
            optionCountRow.append("\(i) option\(i == 1 ? "" : "s")")
        }
        
        let data = LMChatGeneralPicker.ContentModel(components: [optionTypeRow, optionCountRow],
                                                    selectedIndex: [optionSelectionState.rawValue, currentOptionCount - 1])
        
        delegate?.showMetaOptionsPickerView(with: data)
    }
    
    public func updateMetaOptionPicker(with selectedIndex: [Int]) {
        guard let newOptionType = LMChatPollSelectState(rawValue: selectedIndex[0]) else { return }
        optionSelectionState = newOptionType
        currentOptionCount = selectedIndex[1] + 1
        
        delegate?.updateMetaOption(with: optionSelectionState.description, count: currentOptionCount)
    }
    
    public func openDatePicker() {
        let newDate = Date()
        delegate?.presentDatePicker(with: pollExpiryDate ?? newDate, minimumDate: newDate)
    }
    
    public func metaValueChanged(for id: Int) {
        guard let option = LMChatCreatePollDataModel.MetaOptions(rawValue: id) else { return }
        
        switch option {
        case .isAnonymousPoll:
            isAnonymousPoll.toggle()
        case .isInstantPoll:
            isInstantPoll.toggle()
        case .allowAddOptions:
            allowAddOptions.toggle()
        }
    }
    
    public func validatePoll(with question: String?, options: [String?]) {
        guard let question,
              !question.isEmpty else {
            delegate?.showError(withTitle: "Error", message: "Question cannot be empty", isPopVC: false)
            return
        }
        
        var filteredOptions: [String] = []
        
        for (idx, option) in options.enumerated() {
            if let trimmedText = option?.trimmingCharacters(in: .whitespacesAndNewlines),
               !trimmedText.isEmpty {
                filteredOptions.append(trimmedText)
            } else {
                delegate?.showError(withTitle: "Error", message: "Option \(idx + 1) cannot be empty", isPopVC: false)
                return
            }
        }
        
        guard filteredOptions.count > 1 else {
            delegate?.showError(withTitle: "Error", message: "Need atleast 2 poll options", isPopVC: false)
            return
        }
        
        guard filteredOptions.count == Set(filteredOptions).count else {
            delegate?.showError(withTitle: "Error", message: "Options should be unique", isPopVC: false)
            return
        }
        
        guard let pollExpiryDate else {
            delegate?.showError(withTitle: "Error", message: "Expiry date cannot be empty", isPopVC: false)
            return
        }
        
        guard pollExpiryDate > Date() else {
            delegate?.showError(withTitle: "Error", message: "Expiry date cannot be in past", isPopVC: false)
            return
        }
        
        let pollDetails: LMChatCreatePollDataModel = .init(
            pollQuestion: question,
            expiryTime: pollExpiryDate,
            pollOptions: filteredOptions,
            isInstantPoll: isInstantPoll,
            selectState: optionSelectionState,
            selectStateCount: currentOptionCount,
            isAnonymous: isAnonymousPoll,
            allowAddOptions: allowAddOptions
        )
        
        
        delegate?.updatePoll(with: pollDetails)
    }
}

