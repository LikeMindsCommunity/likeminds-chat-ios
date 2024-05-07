//
//  LMMessageLoading.swift
//  LMChatCore_iOS
//
//  Created by Pushpendra Singh on 01/05/24.
//

import Foundation
import LMChatUI_iOS

@IBDesignable
open class LMMessageLoading: LMView {
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    

    open private(set) lazy var messageView: LMChatShimmerView = {
        let view = LMChatShimmerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setWidthConstraint(with: 56)
        view.setHeightConstraint(with: 56)
        view.cornerRadius(with: 28)
        view.backgroundColor = Appearance.shared.colors.previewSubtitleTextColor
        return view
    }()
    
    open private(set) lazy var titleView: LMChatShimmerView = {
        let view = LMChatShimmerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setHeightConstraint(with: 14)
        view.cornerRadius(with: 7)
        view.backgroundColor = Appearance.shared.colors.previewSubtitleTextColor
        return view
    }()
    
    open private(set) lazy var subtitleView: LMChatShimmerView = {
        let view = LMChatShimmerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setHeightConstraint(with: 12)
        view.cornerRadius(with: 6)
        view.backgroundColor = Appearance.shared.colors.previewSubtitleTextColor
        return view
    }()
    
    open override func setupAppearance() {
        super.setupAppearance()
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(messageView)
        containerView.addSubview(titleView)
        containerView.addSubview(subtitleView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            messageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:  16),
            messageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            messageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant:  -12),
            
            titleView.leadingAnchor.constraint(equalTo: messageView.trailingAnchor, constant:  10),
            titleView.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 6),
            titleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:  -16),
            
            subtitleView.leadingAnchor.constraint(equalTo: messageView.trailingAnchor, constant:  10),
            subtitleView.topAnchor.constraint(greaterThanOrEqualTo: titleView.bottomAnchor, constant:10),
            subtitleView.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant:  -30),
        ])
    }
}
