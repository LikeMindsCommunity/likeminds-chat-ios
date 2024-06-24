//
//  NavigationActions.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 17/04/24.
//

import Foundation
import LikeMindsChatUI
import LikeMindsChat
import UIKit
import SafariServices
//import GiphyUISDK

enum NavigationActions {
    case homeFeed
    case chatroom(chatroomId: String, conversationID: String? = nil)
    case messageAttachment(delegate: LMChatAttachmentViewDelegate?, chatroomId: String?, sourceType: LMChatAttachmentViewModel.LMAttachmentSourceType)
    case messageAttachmentWithData(data:[MediaPickerModel], delegate: LMChatAttachmentViewDelegate?, chatroomId: String?, mediaType: MediaType)
    case participants(chatroomId: String, isSecret: Bool)
    case dmMemberList(showList: Int?)
    case report(chatroomId: String?, conversationId: String?, memberId: String?)
    case reactionSheet(reactions: [Reaction], selectedReaction: String?, conversation: String?, chatroomId: String?)
    case exploreFeed
    case browser(url: URL)
    case mediaPreview(data: LMChatMediaPreviewViewModel.DataModel, startIndex: Int)
    case searchScreen
    case emojiPicker(conversationId: String?, chatroomId: String?)
//    case giphy
    
}

protocol NavigationScreenProtocol: AnyObject {
    func perform(_ action: NavigationActions, from source: LMViewController, params: Any?)
}


class NavigationScreen: NavigationScreenProtocol {
    static let shared = NavigationScreen()
    
    private init() {}
    
    func perform(_ action: NavigationActions, from source: LMViewController, params: Any?) {
        switch action {
        case .homeFeed:
            guard let homefeedvc = try? LMChatHomeFeedViewModel.createModule() else { return }
            source.navigationController?.pushViewController(homefeedvc, animated: true)
        case .chatroom(let chatroomId, let conversationId):
            guard let chatroom = try? LMChatMessageListViewModel.createModule(withChatroomId: chatroomId, conversationId: conversationId) else { return }
            source.navigationController?.pushViewController(chatroom, animated: true)
        case .messageAttachment(let delegate, let chatroomId, let sourceType):
            guard let attachment = try? LMChatAttachmentViewModel.createModule(delegate: delegate, chatroomId: chatroomId, sourceType: sourceType) else { return }
            attachment.modalPresentationStyle = .fullScreen
            source.present(attachment, animated: true)
        case .messageAttachmentWithData(let data, let delegate, let chatroomId, let mediaType):
            guard let viewController =  try? LMChatAttachmentViewModel.createModuleWithData(mediaData: data, delegate: delegate, chatroomId: chatroomId, mediaType: mediaType), !data.isEmpty else { return }
            viewController.modalPresentationStyle = .fullScreen
            source.present(viewController, animated: true)
        case .participants(let chatroomId, let isSecret):
            guard let participants = try? LMChatParticipantListViewModel.createModule(withChatroomId: chatroomId, isSecretChatroom: isSecret) else { return }
            source.navigationController?.pushViewController(participants, animated: true)
        case .dmMemberList(let showList):
            guard let participants = try? LMChatMemberListViewModel.createModule(showList: showList) else { return }
            source.navigationController?.pushViewController(participants, animated: true)
        case .report(let chatroomId, let conversationId, let memberId):
            guard let report = try? LMChatReportViewModel.createModule(reportContentId: (chatroomId, conversationId, memberId)) else { return }
            source.navigationController?.pushViewController(report, animated: true)
        case .reactionSheet(let reactions, let selected, let conversationId, let chatroomId):
            guard let reactions = try? LMChatReactionViewModel.createModule(reactions: reactions, selected: selected, conversationId: conversationId, chatroomId: chatroomId) else { return }
            reactions.delegate = (source as? LMChatMessageListViewController)
            source.present(reactions, animated: true)
        case .exploreFeed:
            guard let exploreFeed = try? LMExploreChatroomViewModel.createModule() else { return }
            source.navigationController?.pushViewController(exploreFeed, animated: true)
        case .browser(let url):
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            let vc = SFSafariViewController(url: url, configuration: config)
            source.present(vc, animated: true)
        case .mediaPreview(let data, let startIndex):
            let mediaPreview = LMChatMediaPreviewViewModel.createModule(with: data, startIndex: startIndex)
            source.navigationController?.pushViewController(mediaPreview, animated: true)
        case .searchScreen:
            guard let searchScreen = try? LMChatSearchListViewModel.createModule() else { return }
            source.navigationController?.pushViewController(searchScreen, animated: false)
        case .emojiPicker(let conversationId, let chatroomId):
            let picker = LMChatEmojiListViewController()
            picker.conversationId = conversationId
            picker.chatroomId = chatroomId
            picker.delegate = source as? LMChatMessageListViewController
            source.present(picker, animated: true)
//        case .giphy:
//            let giphy = GiphyViewController()
//            giphy.mediaTypeConfig = [.gifs]
//            giphy.theme = GPHTheme(type: .lightBlur)
//            giphy.showConfirmationScreen = false
//            giphy.rating = .ratedPG
//            giphy.delegate = self as? LMMessageListViewController
//            self.window?.rootViewController?.present(giphy, animated: true, completion: nil)
        }
    }
}

