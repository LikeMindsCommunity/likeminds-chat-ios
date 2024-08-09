//
//  LMChatHomeFeedChatroomView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 08/02/24.
//

import Foundation
import Kingfisher

@IBDesignable
open class LMChatHomeFeedChatroomView: LMView {
    
    public struct ContentModel {
        public let userName: String
        public let lastMessage: String
        public let chatroomName: String
        public let chatroomImageUrl: String?
        public let isMuted: Bool
        public let isSecret: Bool
        public let isAnnouncementRoom: Bool
        public let unreadCount: Int
        public let timestamp: String
        public let fileTypeWithCount: [(type: String, count: Int)]?
        public let messageType: Int
        public let isContainOgTags: Bool
        
        public init(userName: String, lastMessage: String, chatroomName: String, chatroomImageUrl: String?, isMuted: Bool, isSecret: Bool, isAnnouncementRoom: Bool, unreadCount: Int, timestamp: String, fileTypeWithCount: [(type: String, count: Int)]?, messageType: Int, isContainOgTags: Bool) {
            self.userName = userName
            self.lastMessage = lastMessage
            self.chatroomName = chatroomName
            self.chatroomImageUrl = chatroomImageUrl
            self.isMuted = isMuted
            self.isSecret = isSecret
            self.isAnnouncementRoom = isAnnouncementRoom
            self.unreadCount = unreadCount
            self.timestamp = timestamp
            self.fileTypeWithCount = fileTypeWithCount
            self.messageType = messageType
            self.isContainOgTags = isContainOgTags
        }
        
    }
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var subviewContainer: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.cornerRadius(with: 8)
        view.backgroundColor = Appearance.shared.colors.gray3
        return view
    }()
    
    open private(set) lazy var chatroomContainerStackView: LMStackView = { [unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fillProportionally
        view.alignment = .center
        view.spacing = 10
        return view
    }()
    
    open private(set) lazy var chatroomNameAndMessageContainerStackView: LMStackView = { [unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.distribution = .fillProportionally
        view.spacing = 5
        return view
    }()
    
    open private(set) lazy var chatroomNameContainerStackView: LMStackView = { [unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fillProportionally
        view.spacing = 2
        return view
    }()
    
    open private(set) lazy var chatroomMessageContainerStackView: LMStackView = { [unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fillProportionally
        view.spacing = 2
        return view
    }()
    
    open private(set) lazy var chatroomNameLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.headingFont1
        label.textColor = Appearance.shared.colors.black
        label.numberOfLines = 1
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    open private(set) lazy var customTitle: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.subHeadingFont1
        label.numberOfLines = 1
        label.textColor = Appearance.shared.colors.textColor
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    open private(set) lazy var lastMessageLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.textFont2
        label.numberOfLines = 1
        label.textColor = Appearance.shared.colors.textColor
        return label
    }()
    
    open private(set) lazy var timestampLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.textFont2
        label.numberOfLines = 1
        label.textColor = Appearance.shared.colors.textColor
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    open private(set) lazy var chatroomImageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.setWidthConstraint(with: 54)
        image.setHeightConstraint(with: 54)
        image.image = Constants.shared.images.personCircleFillIcon
        image.cornerRadius(with: 27)
        return image
    }()
    
    open private(set) lazy var lockAndAnnouncementIconContainerStackView: LMStackView = { [unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 5
        return view
    }()
    
    open private(set) lazy var lockIconImageView: LMImageView = { [unowned self] in
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.setWidthConstraint(with: 18)
        image.setHeightConstraint(with: 18)
        image.image = Constants.shared.images.lockFillIcon
        image.tintColor = .lightGray
        return image
    }()
    
    open private(set) lazy var announcementIconImageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.setWidthConstraint(with: 18)
        image.setHeightConstraint(with: 18)
        image.image = Constants.shared.images.annoucementIcon
        image.tintColor = .systemYellow
        return image
    }()
    
    open private(set) lazy var spacerBetweenLockAndTimestamp: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.setWidthConstraint(with: 4, relatedBy: .greaterThanOrEqual)
        return view
    }()
    
    open private(set) lazy var muteAndBadgeIconContainerStackView: LMStackView = { [unowned self] in
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 5
        return view
    }()
    
    open private(set) lazy var tagIconImageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.setWidthConstraint(with: 18)
        image.setHeightConstraint(with: 18)
        image.image = Constants.shared.images.tagFillIcon
        image.tintColor = .systemGreen
        return image
    }()
    
    open private(set) lazy var muteIconImageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.setWidthConstraint(with: 18)
        image.setHeightConstraint(with: 18)
        image.image = Constants.shared.images.muteFillIcon
        image.tintColor = .lightGray
        return image
    }()
    
    open private(set) lazy var chatroomCountBadgeLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.headingFont2
        label.numberOfLines = 1
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .systemGreen
        label.setWidthConstraint(with: 18, relatedBy: .greaterThanOrEqual)
        label.setHeightConstraint(with: 18)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.cornerRadius(with: 9)
        label.setPadding(with: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        return label
    }()
    
    open override func setupAppearance() {
        super.setupAppearance()
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(chatroomContainerStackView)
        muteAndBadgeIconContainerStackView.addArrangedSubview(tagIconImageView)
        muteAndBadgeIconContainerStackView.addArrangedSubview(muteIconImageView)
        muteAndBadgeIconContainerStackView.addArrangedSubview(chatroomCountBadgeLabel)
        lockAndAnnouncementIconContainerStackView.addArrangedSubview(lockIconImageView)
        lockAndAnnouncementIconContainerStackView.addArrangedSubview(announcementIconImageView)
        chatroomMessageContainerStackView.addArrangedSubview(lastMessageLabel)
        chatroomMessageContainerStackView.addArrangedSubview(muteAndBadgeIconContainerStackView)
        chatroomNameContainerStackView.addArrangedSubview(chatroomNameLabel)
        chatroomNameContainerStackView.addArrangedSubview(customTitle)
        chatroomNameContainerStackView.addArrangedSubview(lockAndAnnouncementIconContainerStackView)
        chatroomNameContainerStackView.addArrangedSubview(spacerBetweenLockAndTimestamp)
        chatroomNameContainerStackView.addArrangedSubview(timestampLabel)
        chatroomNameAndMessageContainerStackView.addArrangedSubview(chatroomNameContainerStackView)
        chatroomNameAndMessageContainerStackView.addArrangedSubview(chatroomMessageContainerStackView)
        chatroomContainerStackView.addArrangedSubview(chatroomImageView)
        chatroomContainerStackView.addArrangedSubview(chatroomNameAndMessageContainerStackView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        pinSubView(subView: containerView)
        NSLayoutConstraint.activate([
            chatroomContainerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            chatroomContainerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chatroomContainerStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            chatroomContainerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
        ])
        lastMessageLabel.setHeightConstraint(with: 18)
    }
    
    open func setData(_ data: ContentModel) {
        chatroomName(data.chatroomName)
        lastMessageLabelSet(data)
        muteIconImageView.isHidden = !data.isMuted
        announcementIconImageView.isHidden = !data.isAnnouncementRoom
        lockIconImageView.isHidden = !data.isSecret
        tagIconImageView.isHidden = true
        chatroomCountBadgeLabel.isHidden = data.unreadCount <= 0
        chatroomCountBadgeLabel.text = data.unreadCount > 99 ? "99+" : "\(data.unreadCount)"
        timestampLabel.text = data.timestamp
        let placeholder = UIImage.generateLetterImage(name: data.chatroomName.components(separatedBy: " ").first ?? "")
        if let imageUrl = data.chatroomImageUrl, let url = URL(string: imageUrl) {
            chatroomImageView.kf.setImage(with: url, placeholder: placeholder, options: [.fromMemoryCacheOrRefresh])
        } else {
            chatroomImageView.image = placeholder
        }
    }
    
    open func lastMessageLabelSet(_ data: ContentModel) {
        let attributedText = NSMutableAttributedString()
        
        for fileAttachmentType in (data.fileTypeWithCount ?? []) {
            let fileType = fileAttachmentType.type
            var initalType = ""
            var image = UIImage()
            switch fileType.lowercased() {
            case "image":
                image = Constants.shared.images.galleryIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
                initalType = "Photo"
            case "video":
                image = Constants.shared.images.videoSystemIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
                initalType = "Video"
            case "audio":
                image = Constants.shared.images.audioIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
                initalType = "Audio"
            case "voice_note":
                image = Constants.shared.images.micIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
                initalType = "Voice note"
            case "pdf", "doc":
                image = Constants.shared.images.documentsIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
                initalType = "Document"
            case "link":
                image = Constants.shared.images.linkIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            case "gif":
                image = Constants.shared.images.gifBadgeIcon
                initalType = "GIF"
            default:
                break
            }
            if fileType.lowercased() == "gif" {
                let textAtt = NSTextAttachment(image: image)
                textAtt.bounds = CGRect(x: 0, y: -4, width: 24, height: 16)
                attributedText.append(NSAttributedString(string: " "))
                attributedText.append(NSAttributedString(attachment: textAtt))
                attributedText.append(NSAttributedString(string: " \(initalType)"))
            } else {
                if fileAttachmentType.count > 1 {
                    attributedText.append(NSAttributedString(string: " \(fileAttachmentType.count) "))
                    attributedText.append(NSAttributedString(attachment: NSTextAttachment(image: image)))
                } else {
                    attributedText.append(NSAttributedString(string: " "))
                    attributedText.append(NSAttributedString(attachment: NSTextAttachment(image: image)))
                    initalType = !initalType.isEmpty ? " \(initalType)" : ""
                    attributedText.append(NSAttributedString(string: "\(initalType)"))
                }
            }
        }
        
        if data.messageType == 10 {
            let image = Constants.shared.images.pollIcon.withSystemImageConfig(pointSize: 14)?.withTintColor(Appearance.shared.colors.textColor) ?? UIImage()
            attributedText.append(NSAttributedString(string: " "))
            attributedText.append(NSAttributedString(attachment: NSTextAttachment(image: image)))
        }

        // Initialize mutable string
        if !data.userName.isEmpty {
            let completeText = NSMutableAttributedString()
            let textBeforeIcon = NSAttributedString(string:  data.userName + ":")
            let textAfterIcon = NSAttributedString(string: " " + (data.lastMessage))
            completeText.append(textBeforeIcon)
            completeText.append(attributedText)
            completeText.append(textAfterIcon)
            lastMessageLabel.attributedText = completeText
        }
    }
    
    func chatroomName(_ name: String) {
        let components = name.components(separatedBy: "\(Constants.shared.strings.dot)")
        chatroomNameLabel.text = components.first
        customTitle.isHidden = components.count < 2
        customTitle.text = "\(Constants.Strings.shared.dot) " + (components.last ?? "")
    }
}
