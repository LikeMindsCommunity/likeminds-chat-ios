//
//  LMChatMediaVideoPreview.swift
//  LikeMindsChatCore
//
//  Created by Devansh Mohata on 20/04/24.
//

import LikeMindsChatUI
import UIKit

public struct LMChatMediaPreviewContentModel {
    let mediaURL: String
    let thumbnailURL: String?
    let isVideo: Bool
}

open class LMChatMediaVideoPreview: LMCollectionViewCell {
    // MARK: UI Elements
    open private(set) lazy var videoPreview: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.contentMode = .scaleAspectFit
        image.backgroundColor = Appearance.shared.colors.black
        return image
    }()
    
    open private(set) lazy var playButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setTitle(nil, for: .normal)
        button.setImage(Constants.shared.images.playFilled, for: .normal)
        button.tintColor = Appearance.shared.colors.white
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    
    // MARK: callback
    public var onTapCallback: (() -> Void)?
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        contentView.addSubviewWithDefaultConstraints(containerView)
        containerView.addSubviewWithDefaultConstraints(videoPreview)
        containerView.addSubview(playButton)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        playButton.setWidthConstraint(with: 36)
        playButton.setHeightConstraint(with: playButton.widthAnchor)
        playButton.addConstraint(centerX: (containerView.centerXAnchor, 0),
                                 centerY: (containerView.centerYAnchor, 0))
    }
    
    
    // MARK: setupActions
    open override func setupActions() {
        super.setupActions()
        playButton.addTarget(self, action: #selector(onTapPlayButton), for: .touchUpInside)
    }
    
    @objc
    open func onTapPlayButton() {
        onTapCallback?()
    }
    
    
    // MARK: configure
    open func configure(with data: LMChatMediaPreviewContentModel, onTapCallback: (() -> Void)?) {
        self.onTapCallback = onTapCallback
        videoPreview.kf.setImage(with: URL(string: data.thumbnailURL ?? ""))
    }
}
