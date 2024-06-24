//
//  LMChatFeedViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 14/06/24.
//

import Foundation
import LikeMindsChat
import LikeMindsChatUI
import LikeMindsChatCore

public protocol ChatFeedViewModelProtocol: AnyObject {

}

public class ChatFeedViewModel {
    
    weak var delegate: ChatFeedViewModelProtocol?
    
    init(_ viewController: ChatFeedViewModelProtocol) {
        self.delegate = viewController
    }
    
    public static func createModule() -> ChatFeedViewController {
        let viewController = ChatFeedViewController()
        viewController.viewModel = ChatFeedViewModel(viewController)
        return viewController
    }
    
}
