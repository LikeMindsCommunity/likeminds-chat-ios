//
//  LMChatSearchChatroomCell.swift
//  LikeMindsChatCore
//
//  Created by Devansh Mohata on 15/04/24.
//

import Kingfisher
import UIKit

public protocol LMChatSearchCellDataProtocol { 
    var chatroomID: String { get }
}

public class LMChatSearchChatroomCell: LMTableViewCell {
    public struct ContentModel: LMChatSearchCellDataProtocol {
        public var chatroomID: String
        public let image: String?
        public let chatroomName: String
        
        
        public init(chatroomID: String, image: String?, chatroomName: String) {
            self.chatroomID = chatroomID
            self.image = image
            self.chatroomName = chatroomName
        }
    }
    
    lazy var groupIcon: LMImageView = {
        let imageView = LMImageView().translatesAutoresizingMaskIntoConstraints()
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var titleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "Trial Text"
        label.font = Appearance.shared.fonts.buttonFont1
        label.textColor = Appearance.shared.colors.black
        return label
    }()
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(groupIcon)
        containerView.addSubview(titleLabel)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        containerView.addConstraint(top: (contentView.topAnchor, 0),
                                    leading: (contentView.leadingAnchor, 0),
                                    trailing: (contentView.trailingAnchor, 0))
        
        containerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
        
        groupIcon.addConstraint(top: (containerView.topAnchor, 16),
                                bottom: (containerView.bottomAnchor, -8),
                                leading: (containerView.leadingAnchor, 8))
        groupIcon.setHeightConstraint(with: 64)
        groupIcon.setWidthConstraint(with: groupIcon.heightAnchor)
        
        titleLabel.addConstraint(leading: (groupIcon.trailingAnchor, 8),
                                 trailing: (containerView.trailingAnchor, -8),
                                 centerY: (containerView.centerYAnchor, 0))
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        groupIcon.layer.cornerRadius = 32
    }
    
    
    // MARK: configure
    open func configure(with data: ContentModel) {
        groupIcon.kf.setImage(
            with: URL(string: data.image ?? ""),
            placeholder: UIImage.generateLetterImage(name: data.chatroomName.components(separatedBy: " ").first ?? "")
        )
        titleLabel.text = data.chatroomName
    }
}
