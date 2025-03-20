//
//  LMChatroomHeaderMessageCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 25/04/24.
//

import Foundation

public protocol LMChatroomHeaderMessageCellDelegate: AnyObject {
    func onClickReactionOfMessage(reaction: String, indexPath: IndexPath?)
    func didTapURL(url: URL)
    func didTapRoute(route: String)
}

@IBDesignable
open class LMChatroomHeaderMessageCell: LMTableViewCell {
    
    public struct ContentModel {
        public let message: ConversationViewData?
    }
    
    // MARK: UI Elements
    open private(set) lazy var chatMessageView: LMChatroomHeaderMessageView = {
        let view = LMUIComponents.shared.chatroomHeaderMessageView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        view.cornerRadius(with: 12)
        view.backgroundColor = Appearance.shared.colors.white
        return view
    }()
    
    open private(set) lazy var reactionsView: LMChatMessageReactionsView = {
        let view = LMUIComponents.shared.messageReactionView.init().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var reactionContainerStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 0
        view.addArrangedSubview(reactionsView)
        return view
    }()
    
    
    open override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    var currentIndexPath: IndexPath?
    var originalCenter = CGPoint()
    var replyActionHandler: (() -> Void)?
    weak var delegate: LMChatroomHeaderMessageCellDelegate?
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        contentView.addSubview(containerView)
        containerView.addSubview(chatMessageView)
        containerView.addSubview(reactionContainerStackView)
        reactionsView.delegate = self
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        contentView.pinSubView(subView: containerView)
        NSLayoutConstraint.activate([
            chatMessageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            chatMessageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            chatMessageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            reactionContainerStackView.topAnchor.constraint(equalTo: chatMessageView.bottomAnchor, constant: 2),
            reactionContainerStackView.leadingAnchor.constraint(equalTo: chatMessageView.leadingAnchor),
            reactionContainerStackView.trailingAnchor.constraint(lessThanOrEqualTo: chatMessageView.trailingAnchor),
            reactionContainerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.clear
        contentView.backgroundColor = Appearance.shared.colors.clear
        containerView.backgroundColor = Appearance.shared.colors.clear
    }
    
    
    // MARK: configure
    open func setData(with data: ContentModel, index: IndexPath) {
        chatMessageView.setData(.init(title: data.message?.message, createdBy: data.message?.createdBy, chatroomImageUrl: data.message?.member?.imageUrl, messageId: data.message?.id, customTitle: data.message?.memberTitle, createdTime: data.message?.createdAt))
        reactionsView(data)
    }
    
    
    func reactionsView(_ data: ContentModel?) {
        if let reactions = data?.message?.reactions, reactions.count > 0 {
            reactionsView.isHidden = false
            reactionsView.setData(reactions)
        } else {
            reactionsView.isHidden = true
        }
    }
}

extension LMChatroomHeaderMessageCell: LMChatMessageReactionsViewDelegate {
    
    public func clickedOnReaction(_ reaction: String) {
        delegate?.onClickReactionOfMessage(reaction: reaction, indexPath: currentIndexPath)
    }
}
