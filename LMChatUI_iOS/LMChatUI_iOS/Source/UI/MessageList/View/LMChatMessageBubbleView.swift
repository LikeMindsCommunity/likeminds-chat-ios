//
//  LMChatMessageBubbleView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 27/03/24.
//

import Foundation

/// A view that displays a bubble around a message.
open class LMChatMessageBubbleView: LMView {
    
    var isIncoming = true
    
    var receivedBubble = Constants.shared.images.bubbleReceived.resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21), resizingMode: .stretch)
        .withRenderingMode(.alwaysTemplate)
    var sentBubble = Constants.shared.images.bubbleSent.resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21), resizingMode: .stretch)
        .withRenderingMode(.alwaysTemplate)
    
    open var incomingColor: UIColor {
        Appearance.shared.colors.incomingColor
    }
    
    open var outgoingColor: UIColor {
        Appearance.shared.colors.outgoingColor
    }
    
    var containerViewLeadingConstraint: NSLayoutConstraint?
    var containerViewTrailingConstraint: NSLayoutConstraint?
    
    open private(set) lazy var contentContainer: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.alignment = .leading
        view.distribution = .fill
        view.spacing = 6
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) var imageView: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.backgroundColor = Appearance.shared.colors.clear
        return image
    }()
    
    open private(set) lazy var timestampLabel: LMLabel = {
        let label =  LMLabel()
            .translatesAutoresizingMaskIntoConstraints()
        label.numberOfLines = 0
        label.font = Appearance.shared.fonts.subHeadingFont1
        label.textColor = Appearance.shared.colors.textColor
        label.text = ""
        return label
    }()
    
    var timestampTopConstraint: NSLayoutConstraint?
    var timestampTrailingConstraint: NSLayoutConstraint?
    
    /// A type describing the content of this view.
    public struct ContentModel {
        /// The background color of the bubble.
        public let backgroundColor: UIColor
        /// The mask saying which corners should be rounded.
        public let roundedCorners: CACornerMask
        
        public init(backgroundColor: UIColor, roundedCorners: CACornerMask) {
            self.backgroundColor = backgroundColor
            self.roundedCorners = roundedCorners
        }
    }
    
    
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.clear
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(imageView)
        addSubview(contentContainer)
        addSubview(timestampLabel)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        let leading: CGFloat = isIncoming ? 6 : 12
        let trailing: CGFloat = isIncoming ? 12 : 6
        containerViewLeadingConstraint = contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading)
        containerViewTrailingConstraint = contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailing)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            timestampLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            timestampLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 10),
        ])
        timestampTopConstraint = timestampLabel.topAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: 4)
        timestampTrailingConstraint = timestampLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        timestampTopConstraint?.isActive = true
        timestampTrailingConstraint?.isActive = true
        containerViewLeadingConstraint?.isActive = true
        containerViewTrailingConstraint?.isActive = true
    }
    
    func updateTimestampLabelTopConstraint(withConstant constant: CGFloat = 4) {
        timestampTopConstraint?.constant = constant
    }
    
    func updateTimestampLabelTrailingConstraint(withConstant constant: CGFloat = -16) {
        timestampTrailingConstraint?.constant = constant
    }
    
    open func addArrangeSubview(_ view: UIView, atIndex: Int? = nil) {
        guard let atIndex else {
            contentContainer.addArrangedSubview(view)
            return
        }
        contentContainer.insertArrangedSubview(view, at: atIndex)
    }
    
    open func bubbleFor(_ isInComing: Bool) {
        self.isIncoming = isInComing
        containerViewLeadingConstraint?.isActive = false
        containerViewTrailingConstraint?.isActive = false
        if isInComing {
            imageView.image = receivedBubble.withTintColor(incomingColor, renderingMode: .alwaysTemplate)
            imageView.tintColor = incomingColor
            containerViewLeadingConstraint?.constant = 12
            containerViewTrailingConstraint?.constant = -6
        } else {
            imageView.image = sentBubble.withTintColor(outgoingColor, renderingMode: .alwaysTemplate)
            imageView.tintColor = outgoingColor
            containerViewLeadingConstraint?.constant = 6
            containerViewTrailingConstraint?.constant = -12
        }
        containerViewLeadingConstraint?.isActive = true
        containerViewTrailingConstraint?.isActive = true
    }
}
