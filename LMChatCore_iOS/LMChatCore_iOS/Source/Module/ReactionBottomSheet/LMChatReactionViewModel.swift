//
//  LMChatReactionViewModel.swift
//  SampleApp
//
//  Created by Devansh Mohata on 15/04/24.
//

import Foundation
import LikeMindsChatData
import LikeMindsChatUI

protocol ReactionViewModelProtocol: AnyObject {
    func showData(with collection: [LMChatReactionTitleCell.ContentModel], cells: [LMChatReactionViewCell.ContentModel])
    func reactionDeleted()
}

final public class LMChatReactionViewModel {
    var delegate: ReactionViewModelProtocol?
    var reactionsData: [Reaction] = []
    var reactionsByGroup: [String: [Reaction]] = [:]
    
    var reactions: [LMChatReactionTitleCell.ContentModel]
    var reactionList: [LMChatReactionViewCell.ContentModel]
    
    var conversationId: String?
    var chatroomId: String?
    var selectedReaction: String?
    
    init(delegate: ReactionViewModelProtocol?, chatroomId: String?, conversationId: String?, reactionsData: [Reaction], selectedReaction: String?) {
        self.delegate = delegate
        self.chatroomId = chatroomId
        self.conversationId = conversationId
        self.reactionsData = reactionsData
        self.selectedReaction = selectedReaction
        
        reactions = []
        reactionList = []
    }
    
    public static func createModule(reactions: [Reaction], selected: String?, conversationId: String?, chatroomId: String?) throws -> LMChatReactionViewController? {
        guard LMChatCore.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let vc = LMCoreComponents.shared.reactionListScreen.init()
        
        let viewmodel = Self.init(
            delegate: vc,
            chatroomId: chatroomId,
            conversationId: conversationId,
            reactionsData: reactions,
            selectedReaction: selected
        )
        
        vc.viewModel = viewmodel
        return vc
    }
    
    func getData() {
        reactionListOpen()
        fetchReactions()
    }
    
    func fetchReactions() {
        let reactionsOnly = reactionsData.map { $0.reaction }.unique()
        reactionsByGroup = Dictionary(grouping: reactionsData, by: ({$0.reaction}))
        reactions.append(.init(title: "All", count: reactionsData.count, isSelected: true))
        for react in reactionsOnly {
            reactions.append(.init(title: react, count: reactionsByGroup[react]?.count ?? 0, isSelected: false))
        }
        reactionList = reactionsData.map({.init(image: $0.member?.imageUrl, username: $0.member?.name ?? "", isSelfReaction: (($0.member?.sdkClientInfo?.uuid ?? "") == UserPreferences.shared.getClientUUID()), reaction: $0.reaction)})
        if let selectedReaction, !selectedReaction.isEmpty {
            fetchReactionBy(reaction: selectedReaction)
        } else {
            delegate?.showData(with: reactions, cells: reactionList)
        }
    }
    
    func fetchReactionBy(reaction: String) {
        for i in 0..<reactions.count { reactions[i].isSelected = false }
        guard let selectedReactionIndex = reactions.firstIndex(where: { $0.title == reaction }) else {
            return
        }
        var selectedReaction = reactions[selectedReactionIndex]
        selectedReaction.isSelected = true
        reactions[selectedReactionIndex] = selectedReaction
        
        if reaction == "All" {
            reactionList = reactionsData.map({.init(image: $0.member?.imageUrl, username: $0.member?.name ?? "", isSelfReaction: (($0.member?.sdkClientInfo?.uuid ?? "") == UserPreferences.shared.getClientUUID()), reaction: $0.reaction)})
            delegate?.showData(with: reactions, cells: reactionList)
            return
        }
        
        reactionList = (reactionsByGroup[reaction] ?? []).compactMap({
            .init(
                image: $0.member?.imageUrl,
                username: $0.member?.name ?? "",
                isSelfReaction: (($0.member?.sdkClientInfo?.uuid ?? "") == UserPreferences.shared.getClientUUID()),
                reaction: $0.reaction
            )
        })
        
        delegate?.showData(with: reactions, cells: reactionList)
    }
    
    func reactionListOpen() {
        // TODO: Analytics Missing Community ID
        LMChatCore.analytics?.trackEvent(for: .reactionListOpened, eventProperties: [
            LMChatAnalyticsKeys.messageId.rawValue: conversationId,
            LMChatAnalyticsKeys.communityId.rawValue: SDKPreferences.shared.getCommunityId() ?? "",
            LMChatAnalyticsKeys.chatroomId.rawValue: chatroomId])
    }
    
    func deleteConversationReaction() {
        guard let conversationId else {
            deleteChatroomReaction()
            return
        }
        
        LMChatCore.analytics?.trackEvent(for: .reactionRemoved, eventProperties: [
            LMChatAnalyticsKeys.messageId.rawValue: conversationId,
            LMChatAnalyticsKeys.chatroomId.rawValue: chatroomId])
        
        let request = DeleteReactionRequest.builder()
            .conversationId(conversationId)
            .build()
        self.delegate?.reactionDeleted()
        LMChatClient.shared.deleteReaction(request: request) {[weak self] response in
            guard response.success else {
                return
            }
            (self?.delegate as? LMChatReactionViewController)?.didTapDimmedView()
        }
    }
    
    func deleteChatroomReaction() {
        guard let chatroomId else { return }
        let request = DeleteReactionRequest.builder()
            .chatroomId(chatroomId)
            .build()
        self.delegate?.reactionDeleted()
        LMChatClient.shared.deleteReaction(request: request) {[weak self] response in
            guard response.success else {
                return
            }
            (self?.delegate as? LMChatReactionViewController)?.didTapDimmedView()
        }
    }
}
