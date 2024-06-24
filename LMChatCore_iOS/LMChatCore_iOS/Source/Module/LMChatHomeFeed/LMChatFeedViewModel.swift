//
//  LMChatFeedViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 14/06/24.
//

import Foundation
import LikeMindsChat
import LikeMindsChatUI

public protocol LMChatFeedViewModelProtocol: AnyObject {

}

public class LMChatFeedViewModel {
    
    weak var delegate: LMChatFeedViewModelProtocol?
    
    init(_ viewController: LMChatFeedViewModelProtocol) {
        self.delegate = viewController
    }
    
    public static func createModule() throws -> LMChatFeedViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        let viewController = LMCoreComponents.shared.chatFeedScreen.init()
        viewController.viewModel = LMChatFeedViewModel(viewController)
        return viewController
    }
    
}
