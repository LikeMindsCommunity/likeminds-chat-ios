//
//  LMChatPollViewCell.swift
//  LikeMindsChatUI
//
//  Created by Pushpendra Singh on 24/07/24.
//

import Foundation

open class LMChatPollViewCell: LMChatMessageCell {
    
    open private(set) lazy var pollMessageView: LMChatPollContentView = {
        let view = LMUIComponents.shared.pollContentView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: setupViews
    open override func setupViews() {
        chatMessageView = pollMessageView
        super.setupViews()
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
    }
    
    
    // MARK: configure
    open override func setData(with data: ContentModel, index: IndexPath) {
        super.setData(with: data, index: index)
        pollMessageView.setDataView(data, index: index)
        pollMessageView.pollDisplayView.delegate = pollDelegate
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
    }
}
