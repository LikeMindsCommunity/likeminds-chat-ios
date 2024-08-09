//
//  LMChatLinkPreviewCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import UIKit

@IBDesignable
open class LMChatLinkPreviewCell: LMChatMessageCell {
    
    open private(set) lazy var linkPreview: LMChatLinkPreviewContentView = {
        let view = LMUIComponents.shared.linkContentView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: setupViews
    open override func setupViews() {
        chatMessageView = linkPreview
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
        
        linkPreview.linkPreview.onClickLinkPriview = {[weak self] url in
            self?.delegate?.onClickAttachmentOfMessage(url: url, indexPath: self?.currentIndexPath)
        }
    }
    
}

