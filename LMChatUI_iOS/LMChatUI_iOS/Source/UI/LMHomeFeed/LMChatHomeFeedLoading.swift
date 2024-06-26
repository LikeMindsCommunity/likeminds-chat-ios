//
//  LMChatHomeFeedLoading.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 30/04/24.
//

import UIKit

@IBDesignable
open class LMChatHomeFeedLoading: LMView {
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var profileView: LMChatShimmerView = {
        let view = LMUIComponents.shared.shimmerView.init()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setWidthConstraint(with: 56)
        view.setHeightConstraint(with: 56)
        view.cornerRadius(with: 28)
        view.backgroundColor = Appearance.shared.colors.previewSubtitleTextColor
        return view
    }()
    
    open private(set) lazy var titleView: LMChatShimmerView = {
        let view = LMUIComponents.shared.shimmerView.init()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setHeightConstraint(with: 14)
        view.cornerRadius(with: 7)
        view.backgroundColor = Appearance.shared.colors.previewSubtitleTextColor
        return view
    }()
    
    open private(set) lazy var subtitleView: LMChatShimmerView = {
        let view = LMUIComponents.shared.shimmerView.init()
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
        containerView.addSubview(profileView)
        containerView.addSubview(titleView)
        containerView.addSubview(subtitleView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        pinSubView(subView: containerView)
        
        NSLayoutConstraint.activate([
            profileView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant:  16),
            profileView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            profileView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant:  -12),
            
            titleView.leadingAnchor.constraint(equalTo: profileView.trailingAnchor, constant:  10),
            titleView.topAnchor.constraint(equalTo: profileView.topAnchor, constant: 6),
            titleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant:  -16),
            
            subtitleView.leadingAnchor.constraint(equalTo: profileView.trailingAnchor, constant:  10),
            subtitleView.topAnchor.constraint(greaterThanOrEqualTo: titleView.bottomAnchor, constant:10),
            subtitleView.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant:  -30),
        ])
    }
}
