//
//  NavigationActions.swift
//  LMChatCore_iOS
//
//  Created by Pushpendra Singh on 17/04/24.
//

import Foundation
import LMChatUI_iOS
import LikeMindsChat
import UIKit
import SafariServices
//import GiphyUISDK

enum NavigationActions {
    case homeFeed
    case chatroom(chatroomId: String)
    case messageAttachment(delegat: LMChatAttachmentViewDelegate?, chatroomId: String?)
    case participants(chatroomId: String, isSecret: Bool)
    case report(chatroomId: String?, conversationId: String?, memberId: String?)
    case reactionSheet(reactions: [Reaction], selectedReaction: String?, conversation: String?, chatroomId: String?)
    case exploreFeed
    case browser(url: URL)
    case mediaPreview(data: LMChatMediaPreviewViewModel.DataModel, startIndex: Int)
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
            guard let homefeedvc = try? LMHomeFeedViewModel.createModule() else { return }
            source.navigationController?.pushViewController(homefeedvc, animated: true)
        case .chatroom(let chatroomId):
            guard let chatroom = try? LMMessageListViewModel.createModule(withChatroomId: chatroomId) else { return }
            source.navigationController?.pushViewController(chatroom, animated: true)
        case .messageAttachment(let delegate, let chatroomId):
            guard let attachment = try? LMChatAttachmentViewModel.createModule(delegate: delegate, chatroomId: chatroomId) else { return }
            source.navigationController?.pushViewController(attachment, animated: true)
        case .participants(let chatroomId, let isSecret):
            guard let participants = try? LMParticipantListViewModel.createModule(withChatroomId: chatroomId, isSecretChatroom: isSecret) else { return }
            source.navigationController?.pushViewController(participants, animated: true)
        case .report(let chatroomId, let conversationId, let memberId):
            guard let report = try? LMChatReportViewModel.createModule(reportContentId: (chatroomId, conversationId, memberId)) else { return }
            source.navigationController?.pushViewController(report, animated: true)
        case .reactionSheet(let reactions, let selected, let conversationId, let chatroomId):
            guard let reactions = try? LMReactionViewModel.createModule(reactions: reactions, selected: selected, conversationId: conversationId, chatroomId: chatroomId) else { return }
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

