//
//  LMChatProfileView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 02/04/24.
//

import UIKit

open class LMChatProfileView: LMView {
    /// The `UIImageView` instance that shows the avatar image.
    open private(set) var imageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.image = Constants.shared.images.personCircleFillIcon
        return image
    }()
    
    override open var intrinsicContentSize: CGSize {
        imageView.image?.size ?? super.intrinsicContentSize
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = min(imageView.bounds.width, imageView.bounds.height) / 2
    }

    open override func setupAppearance() {
        super.setupAppearance()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(imageView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        pinSubView(subView: imageView)
        imageView.setWidthConstraint(with: 36)
        imageView.setHeightConstraint(with: 36)
    }
}
