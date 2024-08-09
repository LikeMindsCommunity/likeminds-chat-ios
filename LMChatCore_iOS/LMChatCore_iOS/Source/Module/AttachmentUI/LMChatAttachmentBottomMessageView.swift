//
//  LMChatAttachmentBottomMessageView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 14/03/24.
//

import Foundation
import LikeMindsChatUI

public protocol LMAttachmentBottomMessageDelegate: AnyObject {
    func addMoreAttachment()
    func sendAttachment(message: String?)
    func addGifAttachment()
}

@IBDesignable
open class LMChatAttachmentBottomMessageView: LMView {
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .clear
        return view
    }()
    
    open private(set) lazy var topSeparatorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.gray155
        return view
    }()
    
    open private(set) lazy var addOnVerticleStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.distribution = .fill
        view.spacing = 0
        return view
    }()
    
    open private(set) lazy var horizontalStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.spacing = 12
        return view
    }()
    
    open private(set) lazy var inputTextContainerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) lazy var inputTextAndGifHorizontalStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.spacing = 8
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) lazy var inputTextView: LMChatTaggingTextView = {
        let view = LMChatTaggingTextView().translatesAutoresizingMaskIntoConstraints()
        view.placeHolderText = "Add message..."
        view.mentionDelegate = self
        view.isScrollEnabled = false
        view.typingTextColor = Appearance.shared.colors.white
        view.placeholderColor = Appearance.shared.colors.textColor
        view.font = Appearance.shared.fonts.textFont1
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) var inputTextViewHeightConstraint: NSLayoutConstraint?
    open private(set) var taggingViewHeightConstraints: NSLayoutConstraint?
    open weak var delegate: LMAttachmentBottomMessageDelegate?
    
    open private(set) lazy var gifButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(UIImage(systemName: "giftcard"), for: .normal)
        button.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        return button
    }()
    
    open private(set) lazy var sendButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(Constants.shared.images.sendButton.withSystemImageConfig(pointSize: 30), for: .normal)
        button.tintColor = Appearance.shared.colors.white
        button.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        button.addTarget(self, action: #selector(sendAttachmentButtonClicked), for: .touchUpInside)
        return button
    }()
    
    open private(set) lazy var attachmentButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(Constants.shared.images.galleryIcon.withSystemImageConfig(pointSize: 30), for: .normal)
        button.tintColor = Appearance.shared.colors.white
        button.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        button.addTarget(self, action: #selector(addMoreAttachmentButtonClicked), for: .touchUpInside)
        return button
    }()
    
    open private(set) lazy var replyMessageView: LMChatMessageReplyPreview = {
        let view = LMUIComponents.shared.messageReplyView.init().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var linkPreviewView: LMChatBottomMessageLinkPreview = {
        let view = LMUIComponents.shared.bottomLinkPreview.init().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var taggingListView: LMChatTaggingListView = {
        let view = LMChatTaggingListView().translatesAutoresizingMaskIntoConstraints()
        let viewModel = LMChatTaggingListViewModel(delegate: view)
        view.viewModel = viewModel
        view.delegate = self
        return view
    }()
    
    open private(set) lazy var seperatorLineView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.white
        view.setWidthConstraint(with: 2)
        return view
    }()
    
    let maxHeightOfTextView: CGFloat = 120
    let minHeightOfTextView: CGFloat = 44
    public var isTaggingEnable: Bool? = true
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(addOnVerticleStackView)
        containerView.addSubview(horizontalStackView)
        inputTextContainerView.addSubview(inputTextAndGifHorizontalStackView)
        inputTextAndGifHorizontalStackView.addArrangedSubview(inputTextView)
        
        horizontalStackView.addArrangedSubview(attachmentButton)
        horizontalStackView.addArrangedSubview(seperatorLineView)
        horizontalStackView.addArrangedSubview(inputTextContainerView)
        horizontalStackView.addArrangedSubview(sendButton)
        addOnVerticleStackView.insertArrangedSubview(taggingListView, at: 0)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeightOfTextView),
            //            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeightOfTextView),
            
            addOnVerticleStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addOnVerticleStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            addOnVerticleStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            
            horizontalStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            horizontalStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            horizontalStackView.topAnchor.constraint(equalTo: addOnVerticleStackView.bottomAnchor, constant: 4),
            horizontalStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
            
            inputTextAndGifHorizontalStackView.leadingAnchor.constraint(equalTo: inputTextContainerView.leadingAnchor),
            inputTextAndGifHorizontalStackView.trailingAnchor.constraint(equalTo: inputTextContainerView.trailingAnchor, constant: -10),
            inputTextAndGifHorizontalStackView.topAnchor.constraint(equalTo: inputTextContainerView.topAnchor),
            inputTextAndGifHorizontalStackView.bottomAnchor.constraint(equalTo: inputTextContainerView.bottomAnchor),
            inputTextContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        inputTextViewHeightConstraint = inputTextView.setHeightConstraint(with: 36)
        taggingViewHeightConstraints = taggingListView.setHeightConstraint(with: 0)
    }
    
    @objc func sendAttachmentButtonClicked(_ sender: UIButton) {
        
        var message = inputTextView.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        if message == inputTextView.placeHolderText || message.isEmpty {
            message = ""
        }
        inputTextView.text = ""
        contentHeightChanged()
        delegate?.sendAttachment(message: message)
    }
    
    @objc func addMoreAttachmentButtonClicked(_ sender: UIButton) {
        delegate?.addMoreAttachment()
    }
}

extension LMChatAttachmentBottomMessageView: LMChatTaggingTextViewProtocol {
    
    public func mentionStarted(with text: String, chatroomId: String) {
        guard isTaggingEnable == true else { return }
        taggingListView.fetchUsers(for: text, chatroomId: chatroomId)
    }
    
    public func mentionStopped() {
        guard isTaggingEnable == true else { return }
        taggingListView.stopFetchingUsers()
    }
    
    
    public func contentHeightChanged() {
        let width = inputTextView.frame.size.width
        
        let newSize = inputTextView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        
        inputTextView.isScrollEnabled = newSize.height > maxHeightOfTextView
        inputTextViewHeightConstraint?.constant = min(max(newSize.height, 36), maxHeightOfTextView)
    }
}

extension LMChatAttachmentBottomMessageView: LMChatTaggedUserFoundProtocol {
    
    public func userSelected(with route: String, and userName: String) {
        inputTextView.addTaggedUser(with: userName, route: route)
        mentionStopped()
    }
    
    public func updateHeight(with height: CGFloat) {
        taggingViewHeightConstraints?.constant = height
    }
    
}
