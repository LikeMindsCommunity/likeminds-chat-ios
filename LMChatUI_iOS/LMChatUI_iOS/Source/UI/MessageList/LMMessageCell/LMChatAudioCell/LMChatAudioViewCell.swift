//
//  LMChatAudioViewCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import Foundation

@IBDesignable
open class LMChatAudioViewCell: LMChatMessageCell {
    
    open private(set) lazy var audioMessageView: LMChatAudioContentView = {
        let view = LMUIComponents.shared.audioContentView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: setupViews
    open override func setupViews() {
        chatMessageView = audioMessageView
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
        audioMessageView.onShowMoreCallback = { [weak self] in
            self?.updateForSeeMore(for: data.message?.messageId ?? "", index: index)
        }
        
    }
    
    open func resetAudio() {
        audioMessageView.resetAudio()
    }
    
    open func seekSlider(to position: Float, url: String) {
        audioMessageView.seekSlider(to: position, url: url)
    }
    
    open func updateForSeeMore(for messageID: String, index: IndexPath) {
        delegate?.onClickOfSeeMore(for: messageID, indexPath: index)
    }
}
