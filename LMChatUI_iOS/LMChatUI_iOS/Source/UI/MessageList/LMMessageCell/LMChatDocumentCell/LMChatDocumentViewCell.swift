//
//  LMChatDocumentViewCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import Foundation
import Kingfisher

@IBDesignable
open class LMChatDocumentViewCell: LMChatMessageCell {
    
    open private(set) lazy var documentMessageView: LMChatDocumentContentView = {
        let view = LMUIComponents.shared.documentsContentView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: setupViews
    open override func setupViews() {
        chatMessageView = documentMessageView
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
        documentMessageView.onShowMoreCallback = { [weak self] in
            self?.delegate?.onClickOfSeeMore(for: data.message?.messageId ?? "", indexPath: index)
        }
    }
}
