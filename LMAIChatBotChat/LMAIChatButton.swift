//
//  LMAIChatButton.swift
//  LikeMindsChatCore
//
//  Created by Arpit Verma on 11/04/25.
//

import UIKit
import LikeMindsChatUI

// Props class for LMChatAIButton
public class LMChatAIButtonProps {
    public var apiKey: String?
    public var uuid: String?
    public var userName: String?
    public var imageUrl: String?
    public var isGuest: Bool?
    public var accessToken: String?
    public var refreshToken: String?
    
    public init(
        apiKey: String? = nil,
        uuid: String? = nil,
        userName: String? = nil,
        imageUrl: String? = nil,
        isGuest: Bool? = nil,
        accessToken: String? = nil,
        refreshToken: String? = nil
    ) {
        self.apiKey = apiKey
        self.uuid = uuid
        self.userName = userName
        self.imageUrl = imageUrl
        self.isGuest = isGuest
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// Supporting Types
public enum IconPlacement {
    case start
    case end
}

// Delegate Protocol
public protocol LMChatAIButtonDelegate: AnyObject {
    func didTapAIButton(_ button: LMChatAIButton)
    func didTapAIButtonWithProps(_ button: LMChatAIButton, props: LMChatAIButtonProps)
}

@IBDesignable
open class LMChatAIButton: LMButton {
    // MARK: - Properties
    public weak var delegate: LMChatAIButtonDelegate?
    public var props: LMChatAIButtonProps?
    
    // Default values
    private let defaultText = "AI Bot"
    private let defaultTextSize: CGFloat = 14
    private let defaultTextColor = UIColor.white
    private let defaultBackgroundColor = UIColor(red: 2/255, green: 13/255, blue: 66/255, alpha: 1.0)
    private let defaultBorderRadius: CGFloat = 28
    private let defaultIcon = UIImage(named: "lm_ai_chat_bot")
    private let defaultSpacing: CGFloat = 8
    
    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultAppearance()
    }
    
    @available(*, unavailable, renamed: "init(frame:)")
    public required init?(coder: NSCoder) {
        fatalError("\(#function) not implemented in \(#filePath)")
    }
    
    // MARK: - Setup
    private func setupDefaultAppearance() {
        setTitle(defaultText, for: .normal)
        setFont(.systemFont(ofSize: defaultTextSize))
        setTitleColor(defaultTextColor, for: .normal)
        backgroundColor = defaultBackgroundColor
        layer.cornerRadius = defaultBorderRadius
        
        // Set default icon with proper spacing
        if let icon = defaultIcon {
                let resizedIcon = resizeImage(icon, targetSize: CGSize(width: 20, height: 20))
                setImage(resizedIcon, for: .normal)
            }
        configureIconPlacement(.start, spacing: defaultSpacing)
        
        // Add target for tap
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    
    private func configureIconPlacement(_ placement: IconPlacement, spacing: CGFloat) {
        switch placement {
        case .start:
            semanticContentAttribute = .forceLeftToRight
            setInsets(forContentPadding: .zero, imageTitlePadding: spacing)
        case .end:
            semanticContentAttribute = .forceRightToLeft
            setInsets(forContentPadding: .zero, imageTitlePadding: spacing)
        }
        
        // Adjust content insets to maintain proper padding around the content
        let horizontalInset = max(spacing, 16)
        setContentInsets(with: UIEdgeInsets(top: 8, left: horizontalInset, bottom: 8, right: horizontalInset))
    }
    
    // MARK: - Props Methods
    open func setProps(_ props: LMChatAIButtonProps) {
        self.props = props
    }
    
    // MARK: - Actions
    @objc private func buttonTapped() {
        delegate?.didTapAIButton(self)
        if let props = props {
            delegate?.didTapAIButtonWithProps(self, props: props)
        }
    }
    
    // MARK: - Layout
    open override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: max(44, size.height))
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the image and title are properly aligned
        contentHorizontalAlignment = .center
    }
}
