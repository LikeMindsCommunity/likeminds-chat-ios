//
//  LMChatGalleryViewCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import Foundation
import Kingfisher

@IBDesignable
open class LMChatGalleryViewCell: LMChatMessageCell {
    
    open private(set) lazy var galleryMessageView: LMChatGalleryContentView = {
        let view = LMUIComponents.shared.galleryContentView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()

    // MARK: setupViews
    open override func setupViews() {
        chatMessageView = galleryMessageView
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
        galleryMessageView.galleryView.delegate = self
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
    }
}

extension LMChatGalleryViewCell: LMChatMessageGallaryViewDelegate {
    
    public func onClickAttachment(_ index: Int) {
        delegate?.onClickGalleryOfMessage(attachmentIndex: index, indexPath: currentIndexPath)
    }
}

