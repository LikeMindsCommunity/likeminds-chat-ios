//
//  LMChatMessageLoadingShimmerView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 15/04/24.
//

import Foundation

open class LMChatMessageLoadingShimmerView: LMView {
    
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
        for _ in 0..<2 {
            let shimmer = LMUIComponents.shared.messageLoading.init()
            shimmer.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(shimmer)
        }
        stackView.addArrangedSubview(UIView())
    }
}
