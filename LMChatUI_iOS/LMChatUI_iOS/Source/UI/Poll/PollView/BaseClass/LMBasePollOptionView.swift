//
//  LMBasePollOptionView.swift
//  LikeMindsChatUI
//
//  Created by Pushpendra Singh on 24/07/24.
//

import UIKit

open class LMBasePollOptionView: LMView {
    public protocol Content {
        var option: String { get }
        var addedByUser: String? { get }
    }
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) lazy var stackView: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 4
        return stack
    }()
    
    open private(set) lazy var optionLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.font = Appearance.shared.fonts.textFont1
        label.textColor = Appearance.shared.colors.gray51
        label.text = ""
        return label
    }()
    
    open private(set) lazy var addedByLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.font = Appearance.shared.fonts.subHeadingFont1
        label.textColor = Appearance.shared.colors.blueGray.withAlphaComponent(0.7)
        label.text = ""
        return label
    }()
}
