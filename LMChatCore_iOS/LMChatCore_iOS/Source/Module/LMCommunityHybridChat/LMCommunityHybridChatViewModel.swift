//
//  LMCommunityHybridChatViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 14/06/24.
//

import Foundation
import LikeMindsChatData
import LikeMindsChatUI

public protocol LMCommunityHybridChatViewModelProtocol: AnyObject {
    func showDMTab()
}

public class LMCommunityHybridChatViewModel {
    
    weak var delegate: LMCommunityHybridChatViewModelProtocol?
    var dmTab: CheckDMTabResponse?
    
    init(_ viewController: LMCommunityHybridChatViewModelProtocol) {
        self.delegate = viewController
    }
    
    public static func createModule() -> LMCommunityHybridChatViewController {
        let viewController = LMCommunityHybridChatViewController()
        viewController.viewModel = LMCommunityHybridChatViewModel(viewController)
        return viewController
    }
    
    func checkDMTab() {
        LMChatClient.shared.checkDMTab {[weak self] response in
            guard let data = response.data else { return }
            self?.dmTab = data
            self?.delegate?.showDMTab()
        }
    }
}
