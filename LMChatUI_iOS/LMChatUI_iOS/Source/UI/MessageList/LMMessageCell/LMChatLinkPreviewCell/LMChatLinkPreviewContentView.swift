//
//  LMChatLinkPreviewContentView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import UIKit

@IBDesignable
open class LMChatLinkPreviewContentView: LMChatMessageContentView {
 
    open private(set) lazy var linkPreview: LMChatMessageLinkPreview = {[unowned self] in
        let preview = LMUIComponents.shared.messageLinkPreview.init().translatesAutoresizingMaskIntoConstraints()
        preview.widthAnchor.constraint(equalToConstant: widthViewSize).isActive = true
        preview.backgroundColor = .clear
        preview.cornerRadius(with: 12)
        return preview
    }()
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        bubbleView.addArrangeSubview(linkPreview, atIndex: 2)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
    }
    
    open override func setDataView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        super.setDataView(data, index: index)
        if data.message?.isDeleted == true {
            linkPreview.isHidden = true
        } else {
            linkPreview(data)
        }
        bubbleView.layoutIfNeeded()
    }
    
    func linkPreview(_ data: LMChatMessageCell.ContentModel) {
        guard let ogTags = data.message?.ogTags else {
            linkPreview.isHidden = true
            return
        }
        
        linkPreview.setData(.init(linkUrl: ogTags.link, thumbnailUrl: ogTags.thumbnailUrl, title: ogTags.title, subtitle: ogTags.subtitle))
        linkPreview.isHidden = false
    }
    
    override func prepareToResuse() {
        super.prepareToResuse()
    }
}
