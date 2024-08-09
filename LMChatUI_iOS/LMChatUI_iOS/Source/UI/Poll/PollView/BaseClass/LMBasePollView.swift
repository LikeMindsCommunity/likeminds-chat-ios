//
//  LMBasePollView.swift
//  LikeMindsChatUI
//
//  Created by Pushpendra Singh on 24/07/24.
//

import UIKit

open class LMBasePollView: LMView {
    public protocol Content {
        var question: String { get }
        var expiryDate: Date { get }
        var optionState: String { get }
        var optionCount: Int { get }
        var expiryDateFormatted: String { get }
        var optionStringFormatted: String { get }
        var isShowOption: Bool { get }
    }
    
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) lazy var questionContainerStackView: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 8
        return stack
    }()
    
    open private(set) lazy var questionTitle: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.numberOfLines = 0
        label.textColor = Appearance.shared.colors.gray51
        label.font = Appearance.shared.fonts.textFont1
        return label
    }()
    
    open private(set) lazy var optionSelectCountLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.textColor = Appearance.shared.colors.gray155
        label.font = Appearance.shared.fonts.buttonFont1
        label.numberOfLines = 0
        return label
    }()
    
    open private(set) lazy var optionStackView: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillProportionally
        stack.spacing = 8
        return stack
    }()
    
    open private(set) lazy var expiryDateLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.textColor = Appearance.shared.colors.white
        label.font = Appearance.shared.fonts.subHeadingFont2
        label.paddingLeft = 8
        label.paddingRight = 8
        label.paddingTop = 8
        label.paddingBottom = 8
        return label
    }()
    
    open private(set) lazy var pollImageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.image = Constants.shared.images.pollIcon.withSystemImageConfig(pointSize: 30)
        image.tintColor = Appearance.shared.colors.appTintColor
        image.cornerRadius(with: 2)
        return image
    }()
    
    open private(set) lazy var pollTypeLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.textColor = Appearance.shared.colors.gray102
        label.font = Appearance.shared.fonts.subHeadingFont2
        label.text = ""
        label.paddingBottom = 4
        return label
    }()
}

public extension LMBasePollView.Content {
    var expiryDateFormatted: String {
        if expiryDate < Date() {
            return "Poll Ended"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy hh:mm a"

        let dateString = dateFormatter.string(from: expiryDate)
        
        return "Expires on \(dateString)"
    }
    
    var optionStringFormatted: String {
        "*Select \(optionState.lowercased()) \(optionCount) \(optionCount == 1 ? "option" : "options")"
    }
    
    var isShowOption: Bool {
        !optionState.isEmpty && (optionCount != 0)
    }
}
