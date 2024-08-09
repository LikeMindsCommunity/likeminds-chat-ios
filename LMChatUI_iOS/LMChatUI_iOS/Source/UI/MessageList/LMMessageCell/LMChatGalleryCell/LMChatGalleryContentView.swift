//
//  LMChatGalleryContentView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import Foundation
import Kingfisher

@IBDesignable
open class LMChatGalleryContentView: LMChatMessageContentView {

    open private(set) lazy var galleryView: LMChatMessageGallaryView = {
        let image = LMUIComponents.shared.galleryView.init().translatesAutoresizingMaskIntoConstraints()
        image.backgroundColor = .clear
        image.cornerRadius(with: 12)
        return image
    }()
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        bubbleView.addArrangeSubview(galleryView, atIndex: 2)
        galleryView.addSubview(cancelRetryContainerStackView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        cancelRetryContainerStackView.centerXAnchor.constraint(equalTo: galleryView.centerXAnchor).isActive = true
        cancelRetryContainerStackView.centerYAnchor.constraint(equalTo: galleryView.centerYAnchor).isActive = true
    }
    
    open override func setDataView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        super.setDataView(data, index: index)
        updateRetryButton(data)
        if data.message?.isDeleted == true {
            galleryView.isHidden = true
        } else {
            attachmentView(data, index: index)
        }
        galleryView.bringSubviewToFront(cancelRetryContainerStackView)
        bubbleView.layoutIfNeeded()
    }
    
    func attachmentView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        guard let attachments = data.message?.attachments,
              !attachments.isEmpty else {
            galleryView.isHidden = true
            return
        }
        galleryPreview(attachments)
    }
    
    func galleryPreview(_ attachments: [LMChatMessageListView.ContentModel.Attachment]) {
        guard !attachments.isEmpty else {
            galleryView.isHidden = true
            return
        }
        if attachments.count > 0 {
            galleryView.isHidden = false
            let data: [LMChatMessageGallaryView.ContentModel] = attachments.compactMap({ attachment in
                    .init(fileUrl: attachment.fileUrl, thumbnailUrl: attachment.thumbnailUrl, fileSize: attachment.fileSize, duration: attachment.duration, fileType: attachment.fileType, fileName: attachment.fileName)
            })
            galleryView.setData(data)
        } else {
            galleryView.isHidden = true
        }
    }
    
    func updateRetryButton(_ data: LMChatMessageCell.ContentModel) {
        loaderView.isHidden = !(data.message?.messageStatus == .sending)
        retryView.isHidden = !(data.message?.messageStatus == .failed)
    }
    
    override func prepareToResuse() {
        super.prepareToResuse()
    }
}
