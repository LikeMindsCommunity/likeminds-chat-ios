//
//  LMBottomMessageReplyPreview.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 31/01/24.
//

import Foundation
import Kingfisher

public protocol LMBottomMessageReplyPreviewDelegate: AnyObject {
    func clearReplyPreview()
}

@IBDesignable
open class LMChatMessageReplyPreview: LMView {
    
    public struct ContentModel {
        public let username: String?
        public let replyMessage: String?
        public let attachmentsUrls: [(thumbnailUrl: String?, fileUrl: String?, fileType: AttachmentViewData.AttachmentType?)]?
        public let messageType: Int?
        public let isDeleted: Bool
        public let replyPrivatelyView: Bool
        
        public init(
            username: String?,
            replyMessage: String?,
            attachmentsUrls: [(thumbnailUrl: String?, fileUrl: String?, fileType: AttachmentViewData.AttachmentType?)]?,
            messageType: Int?,
            isDeleted: Bool = false,
            replyPrivatelyView: Bool = false
        ) {
            self.username = username
            self.replyMessage = replyMessage
            self.attachmentsUrls = attachmentsUrls
            self.messageType = messageType
            self.isDeleted = isDeleted
            self.replyPrivatelyView = replyPrivatelyView
        }
    }
    
    public weak var delegate: LMBottomMessageReplyPreviewDelegate?
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.previewBackgroundColor
        view.cornerRadius(with: 8)
        return view
    }()
    
    open private(set) lazy var sidePannelColorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.red
        return view
    }()
    
    open private(set) lazy var userNameLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.headingFont1
        label.textColor = Appearance.shared.colors.red
        label.numberOfLines = 1
        label.paddingTop = 2
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()
    
    open private(set) lazy var messageLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.subHeadingFont2
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 10
        label.textColor = Appearance.shared.colors.textColor
        return label
    }()
    
    open private(set) lazy var messageAttachmentImageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.backgroundColor = .clear
        return image
    }()
    
    open private(set) lazy var closeReplyButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(Constants.shared.images.xmarkIcon, for: .normal)
        button.tintColor = Appearance.shared.colors.textColor
        button.addTarget(self, action: #selector(cancelReply), for: .touchUpInside)
        button.backgroundColor = Appearance.shared.colors.white.withAlphaComponent(0.6)
        button.setWidthConstraint(with: 25)
        button.setHeightConstraint(with: 25)
        button.cornerRadius(with: 12.5)
        return button
    }()
    
    open private(set) lazy var horizontalReplyStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 8
        return view
    }()
    
    open private(set) lazy var verticleUsernameAndMessageContainerStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = 4
        return view
    }()
    
    open private(set) lazy var subviewContainer: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .clear
        return view
    }()
    
    var viewData: ContentModel?
    var onClickReplyPreview: (() -> Void)?
    
    var onClickCancelReplyPreview: (() -> Void)?
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(sidePannelColorView)
        containerView.addSubview(horizontalReplyStackView)
        containerView.addSubview(closeReplyButton)
        horizontalReplyStackView.addArrangedSubview(subviewContainer)
        horizontalReplyStackView.addArrangedSubview(messageAttachmentImageView)
        
        subviewContainer.addSubview(verticleUsernameAndMessageContainerStackView)
        verticleUsernameAndMessageContainerStackView.addArrangedSubview(userNameLabel)
        verticleUsernameAndMessageContainerStackView.addArrangedSubview(messageLabel)
        isUserInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(target: self, action: #selector(onReplyPreviewClicked))
        tapGuesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGuesture)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        pinSubView(subView: containerView)
        NSLayoutConstraint.activate([
            closeReplyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -2),
            closeReplyButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 2),
            
            sidePannelColorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            sidePannelColorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            sidePannelColorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sidePannelColorView.widthAnchor.constraint(equalToConstant: 4),
            
            horizontalReplyStackView.leadingAnchor.constraint(equalTo: sidePannelColorView.leadingAnchor, constant: 10),
            horizontalReplyStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            horizontalReplyStackView.topAnchor.constraint(equalTo: sidePannelColorView.topAnchor),
            horizontalReplyStackView.bottomAnchor.constraint(equalTo: sidePannelColorView.bottomAnchor),
            
            messageAttachmentImageView.widthAnchor.constraint(equalToConstant: 60),
            messageAttachmentImageView.heightAnchor.constraint(equalToConstant: 60),
            
            verticleUsernameAndMessageContainerStackView.leadingAnchor.constraint(equalTo: subviewContainer.leadingAnchor),
            verticleUsernameAndMessageContainerStackView.trailingAnchor.constraint(equalTo: subviewContainer.trailingAnchor, constant: -6),
            verticleUsernameAndMessageContainerStackView.topAnchor.constraint(greaterThanOrEqualTo: subviewContainer.topAnchor, constant: 2),
            verticleUsernameAndMessageContainerStackView.bottomAnchor.constraint(lessThanOrEqualTo: subviewContainer.bottomAnchor, constant: -2),
            verticleUsernameAndMessageContainerStackView.centerYAnchor.constraint(equalTo: subviewContainer.centerYAnchor)
            ])
    }
    
    open func setData(_ data: ContentModel) {
        viewData = data
        self.userNameLabel.text = data.username
        messageLabel.font = Appearance.shared.fonts.subHeadingFont2
        if data.isDeleted == true {
            messageLabel.text = data.replyMessage
            messageLabel.font = Appearance.shared.fonts.italicFont14
            messageAttachmentImageView.isHidden = true
            return
        }
        self.messageLabel.attributedText = createAttributedString(data)
        if let attachmentsUrls = data.attachmentsUrls,
           let firstUrl = (attachmentsUrls.first?.thumbnailUrl ?? attachmentsUrls.first?.fileUrl),
           let url = URL(string: firstUrl) {
           messageAttachmentImageView.kf.setImage(with: url)
            messageAttachmentImageView.isHidden = false
        } else {
            messageAttachmentImageView.isHidden = true
        }
    }
    
    open func setDataForEdit(_ data: ContentModel) {
        viewData = data
        self.userNameLabel.text = "Edit message"
        self.messageLabel.attributedText = createAttributedString(data)
        messageAttachmentImageView.isHidden = true
        
    }
    
    open func createAttributedString(_ data: ContentModel) -> NSAttributedString {
        let message = GetAttributedTextWithRoutes.getAttributedText(from: data.replyMessage ?? "", font: Appearance.shared.fonts.subHeadingFont2)
        let pointSize: CGFloat = Appearance.shared.fonts.subHeadingFont2.pointSize
        guard let count = data.attachmentsUrls?.count, count > 0, let fileType = data.attachmentsUrls?.first?.fileType  else {
            let attributedText = NSMutableAttributedString(string: "")
            if data.messageType == 10 {
                let image = Constants.shared.images.pollIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
                attributedText.append(NSAttributedString(attachment: NSTextAttachment(image: image)))
            }
            attributedText.append(message)
            return attributedText
        }
        var image: UIImage = UIImage()
        var initalType = ""
        switch fileType {
        case .image:
            image = Constants.shared.images.galleryIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            initalType = "Photo"
        case .video:
            image = Constants.shared.images.videoSystemIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            initalType = "Video"
        case .audio:
            image = Constants.shared.images.audioIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            initalType = "Audio"
        case .voiceNote:
            image = Constants.shared.images.micIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            initalType = "Voice note"
        case .pdf, .doc, .document:
            image = Constants.shared.images.documentsIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            initalType = "Document"
        case .link:
            image = Constants.shared.images.linkIcon.withSystemImageConfig(pointSize: pointSize)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
        case .gif:
            image = Constants.shared.images.gifBadgeIcon
            initalType = "GIF"
        default:
            break
        }
        
        let attributedText = NSMutableAttributedString(string: "")
        
        if fileType == .gif {
            let textAtt = NSTextAttachment(image: image)
            textAtt.bounds = CGRect(x: 0, y: -4, width: 24, height: 16)
            attributedText.append(NSAttributedString(attachment: textAtt))
            attributedText.append(NSAttributedString(string: " \(initalType) "))
        } else {
            if count > 1 {
                attributedText.append(NSAttributedString(attachment: NSTextAttachment(image: image)))
                attributedText.append(NSAttributedString(string: " (+\(count - 1) more) "))
            } else {
                attributedText.append(NSAttributedString(attachment: NSTextAttachment(image: image)))
                initalType = !initalType.isEmpty ? " \(initalType) " : " "
                attributedText.append(NSAttributedString(string: "\(initalType)"))
            }
        }
        attributedText.append(message)
        return attributedText
    }
    
    @objc open func cancelReply(_ sender:UIButton) {
        onClickCancelReplyPreview?()
    }
    
    @objc open func onReplyPreviewClicked(_ gesture: UITapGestureRecognizer) {
        onClickReplyPreview?()
    }
}
