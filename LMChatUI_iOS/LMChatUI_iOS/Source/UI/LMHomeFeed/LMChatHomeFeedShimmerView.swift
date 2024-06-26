//
//  LMChatHomeFeedShimmerView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 07/05/24.
//

import Foundation

open class LMChatHomeFeedShimmerView: LMView {
    
    open private(set) lazy var containerView: LMView = {
        let view = LMView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    open private(set) lazy var stackView: LMStackView = {
        let stack = LMStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 8
        return stack
    }()
    
    
    open override func setupViews() {
        super.setupViews()
        addSubviewWithDefaultConstraints(stackView)
    }
    
    open override func setupLayouts() {
        super.setupLayouts()
        for _ in 0..<5 {
            let shimmer = LMUIComponents.shared.homeFeedLoading.init()
            shimmer.translatesAutoresizingMaskIntoConstraints = false
            shimmer.setHeightConstraint(with: 80)
            stackView.addArrangedSubview(shimmer)
        }
        stackView.addArrangedSubview(UIView())
    }
}
