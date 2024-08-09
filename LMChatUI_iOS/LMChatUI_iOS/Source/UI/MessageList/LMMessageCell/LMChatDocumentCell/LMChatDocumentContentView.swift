//
//  LMChatDocumentContentView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import Foundation
import Kingfisher

@IBDesignable
open class LMChatDocumentContentView: LMChatMessageContentView {
    
    open private(set) lazy var docPreviewContainerStackView: LMStackView = {[unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 4
        view.widthAnchor.constraint(equalToConstant: widthViewSize).isActive = true
        return view
    }()
    
    public var onShowMoreCallback: (() -> Void)?
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        bubbleView.addArrangeSubview(docPreviewContainerStackView, atIndex: 2)
        docPreviewContainerStackView.addSubview(cancelRetryContainerStackView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        cancelRetryContainerStackView.centerXAnchor.constraint(equalTo: docPreviewContainerStackView.centerXAnchor).isActive = true
        cancelRetryContainerStackView.centerYAnchor.constraint(equalTo: docPreviewContainerStackView.centerYAnchor).isActive = true
    }
    
    open override func setDataView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        super.setDataView(data, index: index)
        updateRetryButton(data)
        if data.message?.isDeleted == true {
            docPreviewContainerStackView.isHidden = true
        } else {
            attachmentView(data, index: index)
        }
        bubbleView.layoutIfNeeded()
    }
    
    func attachmentView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        guard let attachments = data.message?.attachments,
              !attachments.isEmpty else {
            docPreviewContainerStackView.isHidden = true
            return
        }
        
        let updatedAttachments = data.message?.isShowMore == true ? attachments : Array(attachments.prefix(2))
        
        docPreview(updatedAttachments)
        
        if data.message?.isShowMore != true,
           attachments.count > 2 {
            let button = LMButton()
            button.setTitle("+ \(attachments.count - 2) More", for: .normal)
            button.setImage(nil, for: .normal)
            button.addTarget(self, action: #selector(didTapShowMore), for: .touchUpInside)
            button.setFont(Appearance.shared.fonts.buttonFont1)
            button.setTitleColor(Appearance.shared.colors.linkColor, for: .normal)
            docPreviewContainerStackView.addArrangedSubview(button)
        }
    }

    func docPreview(_ attachments: [LMChatMessageListView.ContentModel.Attachment]) {
        guard !attachments.isEmpty else {
            docPreviewContainerStackView.isHidden = true
            return
        }
        attachments.forEach { attachment in
            docPreviewContainerStackView.addArrangedSubview(createDocPreview(.init(fileUrl: attachment.fileUrl, thumbnailUrl: attachment.thumbnailUrl, fileSize: attachment.fileSize, numberOfPages: attachment.numberOfPages, fileType: attachment.fileType, fileName: attachment.fileName)))
        }
        docPreviewContainerStackView.isHidden = false
        docPreviewContainerStackView.bringSubviewToFront(cancelRetryContainerStackView)
    }
    
    func createDocPreview(_ data: LMChatMessageDocumentPreview.ContentModel) -> LMChatMessageDocumentPreview {
        let preview = LMUIComponents.shared.messageDocumentPreview.init().translatesAutoresizingMaskIntoConstraints()
        preview.widthAnchor.constraint(equalToConstant: widthViewSize).isActive = true
        preview.backgroundColor = .clear
        preview.setHeightConstraint(with: 60)
        preview.cornerRadius(with: 12)
        preview.setData(data)
        preview.delegate = self
        return preview
    }
    
    override func prepareToResuse() {
        super.prepareToResuse()
        docPreviewContainerStackView.removeAllArrangedSubviews()
    }
    
    @objc
    open func didTapShowMore() {
        onShowMoreCallback?()
    }
    
    func updateRetryButton(_ data: LMChatMessageCell.ContentModel) {
        loaderView.isHidden = !(data.message?.messageStatus == .sending)
        retryView.isHidden = !(data.message?.messageStatus == .failed)
    }
}

extension LMChatDocumentContentView: LMChatMessageDocumentPreviewDelegate {
    public func onClickAttachment(_ url: String) {
        delegate?.clickedOnAttachment(url)
    }
}
