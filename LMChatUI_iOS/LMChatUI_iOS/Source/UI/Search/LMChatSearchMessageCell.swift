//
//  LMChatSearchMessageCell.swift
//  LikeMindsChatCore
//
//  Created by Devansh Mohata on 16/04/24.
//

import UIKit

public class LMChatSearchMessageCell: LMTableViewCell {
    public struct ContentModel: LMChatSearchCellDataProtocol {
        public var chatroomID: String
        public var messageID: String?
        public let chatroomName: String
        public let message: String
        public let senderName: String
        public let date: TimeInterval
        public let isJoined: Bool
        public let highlightedText: String
        
        public init(chatroomID: String, messageID: String?, chatroomName: String, message: String, senderName: String, date: TimeInterval, isJoined: Bool, highlightedText: String) {
            self.chatroomID = chatroomID
            self.messageID = messageID
            self.chatroomName = chatroomName
            self.message = message
            self.senderName = senderName
            self.date = date
            self.isJoined = isJoined
            self.highlightedText = highlightedText
        }
    }
    
    lazy var titleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "Testing"
        label.font = Appearance.shared.fonts.headingFont1
        label.textColor = Appearance.shared.colors.black
        return label
    }()
    
    lazy var subtitleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "Notification"
        label.numberOfLines = 2
        return label
    }()
    
    lazy var dateLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.headingFont2
        label.textColor = Appearance.shared.colors.black
        return label
    }()
    
    lazy var isJoinedLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "chat room not joined yet"
        label.font = Appearance.shared.fonts.headingFont2
        label.textColor = Appearance.shared.colors.gray51
        return label
    }()
    
    lazy var sepratorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .lightGray
        return view
    }()
    
    open override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(isJoinedLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(sepratorView)
    }
    
    
    open override func setupLayouts() {
        super.setupLayouts()
        
        containerView.addConstraint(top: (contentView.topAnchor, 0),
                                    leading: (contentView.leadingAnchor, 0),
                                    trailing: (contentView.trailingAnchor, 0))
        
        containerView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor).isActive = true
        
        titleLabel.addConstraint(top: (containerView.topAnchor, 8),
                                 leading: (containerView.leadingAnchor, 8))
        
        subtitleLabel.addConstraint(top: (titleLabel.bottomAnchor, 8),
                                    leading: (titleLabel.leadingAnchor, 0))
        subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8).isActive = true
        
        isJoinedLabel.addConstraint(top: (subtitleLabel.bottomAnchor, 8),
                                    leading: (subtitleLabel.leadingAnchor, 0))
        
        sepratorView.addConstraint(bottom: (containerView.bottomAnchor, 0),
                                   leading: (titleLabel.leadingAnchor, 0),
                                   trailing: (dateLabel.trailingAnchor, 0))
        sepratorView.topAnchor.constraint(equalTo: isJoinedLabel.bottomAnchor, constant: 8).isActive = true
        sepratorView.setHeightConstraint(with: 1)
        
        dateLabel.addConstraint(top: (titleLabel.topAnchor, 0),
                                trailing: (containerView.trailingAnchor, -8))
        dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8).isActive = true
        
        
        sepratorView.isHidden = true
    }
    
    open func configure(with data: ContentModel) {
        titleLabel.text = data.chatroomName
        
        var attrText = GetAttributedTextWithRoutes.getAttributedText(
            from: data.message,
            andPrefix: "@",
            allowLink: false,
            allowHashtags: false
        )
        
        attrText = GetAttributedTextWithRoutes.detectAndHighlightText(in: attrText, text: data.highlightedText)
        
        let senderName = NSAttributedString(
            string: "\(data.senderName): ",
            attributes: [
                .foregroundColor: Appearance.shared.colors.textColor,
                .font: Appearance.shared.fonts.textFont1
            ]
        )
        
        attrText.insert(senderName, at: .zero)
        
        subtitleLabel.attributedText = attrText
        isJoinedLabel.isHidden = data.isJoined
        dateLabel.text = LMChatDateUtility.formatDate(data.date)
    }
}
