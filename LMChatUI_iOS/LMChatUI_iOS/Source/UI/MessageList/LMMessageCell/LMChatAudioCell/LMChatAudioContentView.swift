//
//  LMChatAudioContentView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/05/24.
//

import Foundation

@IBDesignable
open class LMChatAudioContentView: LMChatMessageContentView {
    open private(set) lazy var audioPreviewContainerStackView: LMStackView = {[unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 4
        view.widthAnchor.constraint(equalToConstant: widthViewSize).isActive = true
        return view
    }()
    
    public var onShowMoreCallback: (() -> Void)?
    weak var audioDelegate: LMChatAudioProtocol?
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        bubbleView.addArrangeSubview(audioPreviewContainerStackView, atIndex: 2)
        audioPreviewContainerStackView.addSubview(cancelRetryContainerStackView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        cancelRetryContainerStackView.centerXAnchor.constraint(equalTo: audioPreviewContainerStackView.centerXAnchor).isActive = true
        cancelRetryContainerStackView.centerYAnchor.constraint(equalTo: audioPreviewContainerStackView.centerYAnchor).isActive = true
    }
    
    open override func setDataView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        super.setDataView(data, index: index)
        updateRetryButton(data)
        if data.message?.isDeleted == true {
            audioPreviewContainerStackView.isHidden = true
        } else {
            attachmentView(data, delegate: audioDelegate, index: index)
        }
        audioPreviewContainerStackView.bringSubviewToFront(cancelRetryContainerStackView)
        bubbleView.layoutIfNeeded()
    }
    
    func attachmentView(_ data: LMChatMessageCell.ContentModel, delegate: LMChatAudioProtocol?, index: IndexPath) {
        guard let attachments = data.message?.attachments,
              !attachments.isEmpty,
        let type = attachments.first?.fileType else {
            audioPreviewContainerStackView.isHidden = true
            return
        }
        
        let updatedAttachments = data.message?.isShowMore == true ? attachments : Array(attachments.prefix(2))
        
        switch type {
        case "audio":
            audioPreview(updatedAttachments, delegate: delegate, index: index)
        case "voice_note":
            voiceNotePreview(updatedAttachments, delegate: delegate, index: index)
        default:
            break
        }
        
        
        if data.message?.isShowMore != true,
           attachments.count > 2 {
            let button = LMButton()
            button.setTitle("+ \(attachments.count - 2) More", for: .normal)
            button.setImage(nil, for: .normal)
            button.addTarget(self, action: #selector(didTapShowMore), for: .touchUpInside)
            button.setFont(Appearance.shared.fonts.buttonFont1)
            button.setTitleColor(Appearance.shared.colors.linkColor, for: .normal)
            audioPreviewContainerStackView.addArrangedSubview(button)
        }
        
        audioPreviewContainerStackView.isHidden = false
    }
    

    func audioPreview(_ attachments: [LMChatMessageListView.ContentModel.Attachment], delegate: LMChatAudioProtocol?, index: IndexPath) {
        guard !attachments.isEmpty else {
            audioPreviewContainerStackView.isHidden = true
            return
        }
        attachments.forEach { attachment in
            let preview = LMUIComponents.shared.audioPreview.init()
            preview.translatesAutoresizingMaskIntoConstraints = false
            preview.configure(with: .init(fileName: attachment.fileName, url: attachment.fileUrl, duration: attachment.duration ?? 0, thumbnail: attachment.thumbnailUrl), delegate: delegate, index: index)
            preview.widthAnchor.constraint(equalToConstant: widthViewSize).isActive = true
            preview.cornerRadius(with: 12)
            preview.setHeightConstraint(with: 72)
            audioPreviewContainerStackView.addArrangedSubview(preview)
        }
    }

    func voiceNotePreview(_ attachments: [LMChatMessageListView.ContentModel.Attachment], delegate: LMChatAudioProtocol?, index: IndexPath) {
        guard !attachments.isEmpty else {
            audioPreviewContainerStackView.isHidden = true
            return
        }
        attachments.forEach { attachment in
            audioPreviewContainerStackView.addArrangedSubview(createAudioPreview(with: .init(fileName: attachment.fileName, url: attachment.fileUrl, duration: attachment.duration ?? 0, thumbnail: attachment.thumbnailUrl), delegate: delegate, index: index))
        }
    }
    
    func createAudioPreview(with data: LMChatAudioContentModel, delegate: LMChatAudioProtocol?, index: IndexPath) -> LMChatVoiceNotePreview {
        let preview =  LMUIComponents.shared.voiceNotePreview.init().translatesAutoresizingMaskIntoConstraints()
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.widthAnchor.constraint(equalToConstant: widthViewSize).isActive = true
        preview.backgroundColor = .clear
        preview.cornerRadius(with: 12)
        preview.configure(with: data, delegate: delegate, index: index)
        return preview
    }
    
    override func prepareToResuse() {
        super.prepareToResuse()
        audioPreviewContainerStackView.removeAllArrangedSubviews()
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

extension LMChatAudioContentView {
    public func resetAudio() {
        audioPreviewContainerStackView.subviews.forEach { sub in
            (sub as? LMChatVoiceNotePreview)?.resetView()
            (sub as? LMChatAudioPreview)?.resetView()
        }
    }
    
    public func seekSlider(to position: Float, url: String) {
        audioPreviewContainerStackView.subviews.forEach { sub in
            (sub as? LMChatVoiceNotePreview)?.updateSeekerValue(with: position, for: url)
            (sub as? LMChatAudioPreview)?.updateSeekerValue(with: position, for: url)
        }
    }
}
