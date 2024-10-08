//
//  LMChatPollResultCollectionCell.swift
//  LikeMindsChatUI
//
//  Created by Pushpendra Singh on 29/07/24.
//

import UIKit

open class LMChatPollResultCollectionCell: LMCollectionViewCell {
    public struct ContentModel {
        public let optionID: String
        public let title: String
        public let voteCount: Int
        public var isSelected: Bool
        
        public init(optionID: String, title: String, voteCount: Int, isSelected: Bool) {
            self.optionID = optionID
            self.title = title
            self.voteCount = voteCount
            self.isSelected = isSelected
        }
    }
    
    
    // MARK: UI Elements
    open private(set) lazy var stackView: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 2
        return stack
    }()
    
    open private(set) lazy var voteCountLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.font = Appearance.shared.fonts.headingFont1
        label.textAlignment = .center
        return label
    }()
    
    open private(set) lazy var voteTitleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.font = Appearance.shared.fonts.headingFont1
        label.textAlignment = .center
        return label
    }()
    
    open private(set) lazy var sepratorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    
    // MARK: Data Variables
    open var selectedPollColor: UIColor {
        Appearance.shared.colors.appTintColor
    }
    
    open var notSelectedPollColor: UIColor {
        UIColor(r: 102, g: 102, b: 102)
    }
    
    open override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        containerView.addSubview(sepratorView)
        
        stackView.addArrangedSubview(voteCountLabel)
        stackView.addArrangedSubview(voteTitleLabel)
    }
    
    open override func setupLayouts() {
        super.setupLayouts()
        
        contentView.pinSubView(subView: containerView)
        
        stackView.addConstraint(top: (containerView.topAnchor, 8),
                                bottom: (containerView.bottomAnchor, -2),
                                leading: (containerView.leadingAnchor, 0),
                                trailing: (containerView.trailingAnchor, 0))
        
        sepratorView.addConstraint(bottom: (containerView.bottomAnchor, 0),
                                   leading: (containerView.leadingAnchor, 0),
                                   trailing: (containerView.trailingAnchor, 0))
        sepratorView.setHeightConstraint(with: 4, priority: .required)
        sepratorView.layer.cornerRadius = 2
        
        containerView.pinSubView(subView: stackView, padding: .init(top: 12, left: 8, bottom: -12, right: -8))
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        
        sepratorView.clipsToBounds = true
        sepratorView.layer.masksToBounds = true
    }
    
    open func configure(with data: ContentModel) {
        voteCountLabel.text = "\(data.voteCount)"
        voteTitleLabel.text = data.title
        
        voteCountLabel.textColor = data.isSelected ? selectedPollColor : notSelectedPollColor
        voteTitleLabel.textColor = data.isSelected ? selectedPollColor : notSelectedPollColor
        sepratorView.backgroundColor = data.isSelected ? selectedPollColor : Appearance.shared.colors.clear
    }
}
