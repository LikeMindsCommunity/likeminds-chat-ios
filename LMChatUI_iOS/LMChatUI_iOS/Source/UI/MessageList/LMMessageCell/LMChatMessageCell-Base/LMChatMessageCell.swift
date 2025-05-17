//
//  LMChatMessageCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 22/03/24.
//

import Foundation
import Kingfisher

/// Protocol that defines the delegate methods for handling various message cell interactions.
/// This protocol extends LMChatMessageBaseProtocol to provide additional functionality for message cell interactions.
public protocol LMChatMessageCellDelegate: LMChatMessageBaseProtocol {
    /// Called when a user taps on a reaction emoji in a message.
    /// This method allows the delegate to handle reaction interactions and update the UI accordingly.
    /// - Parameters:
    ///   - reaction: The reaction string (emoji) that was tapped
    ///   - indexPath: The index path of the message cell in the table view
    func onClickReactionOfMessage(reaction: String, indexPath: IndexPath?)

    /// Called when a user taps on an attachment in a message.
    /// This method allows the delegate to handle attachment interactions like opening files or media.
    /// - Parameters:
    ///   - url: The URL of the attachment that was tapped
    ///   - indexPath: The index path of the message cell in the table view
    func onClickAttachmentOfMessage(url: String, indexPath: IndexPath?)

    /// Called when a user taps on the gallery view in a message.
    /// This method allows the delegate to handle gallery interactions for multiple attachments.
    /// - Parameters:
    ///   - attachmentIndex: The index of the attachment in the gallery view
    ///   - indexPath: The index path of the message cell in the table view
    func onClickGalleryOfMessage(attachmentIndex: Int, indexPath: IndexPath?)

    /// Called when a user taps on the reply preview section of a message.
    /// This method allows the delegate to handle reply interactions and navigate to the original message.
    /// - Parameter indexPath: The index path of the message cell in the table view
    func onClickReplyOfMessage(indexPath: IndexPath?)

    /// Called when a user taps on the selection button of a message.
    /// This method allows the delegate to handle message selection for bulk actions.
    /// - Parameter indexPath: The index path of the message cell in the table view
    func didTappedOnSelectionButton(indexPath: IndexPath?)

    /// Called when a user taps on the "See More" button of a message.
    /// This method allows the delegate to handle expanding collapsed messages.
    /// - Parameters:
    ///   - messageID: The unique identifier of the message
    ///   - indexPath: The index path of the message cell in the table view
    func onClickOfSeeMore(for messageID: String, indexPath: IndexPath)

    /// Called when a user cancels an attachment upload.
    /// This method allows the delegate to handle cancellation of ongoing uploads.
    /// - Parameter indexPath: The index path of the message cell in the table view
    func didCancelAttachmentUploading(indexPath: IndexPath)

    /// Called when a user requests to retry a failed attachment upload.
    /// This method allows the delegate to handle retry attempts for failed uploads.
    /// - Parameter indexPath: The index path of the message cell in the table view
    func didRetryAttachmentUploading(indexPath: IndexPath)

    /// Called when a user taps on a profile link in a message.
    /// This method allows the delegate to handle navigation to user profiles.
    /// - Parameter route: The route string containing the profile navigation information
    func didTapOnProfileLink(route: String)

    /// Called when a user taps the retry button for a failed message.
    /// This method allows the delegate to handle retry attempts for failed message sends.
    /// - Parameter conversation: The conversation data containing the message to retry
    func onRetryButtonClicked(conversation: ConversationViewData)

    func didTapOnReplyPrivatelyCell(indexPath: IndexPath)
}

/// A custom table view cell that displays chat messages with various interactive features.
/// This cell supports message display, reactions, attachments, replies, and selection functionality.
/// The cell is designed to be reusable and configurable through its ContentModel.
@IBDesignable
open class LMChatMessageCell: LMTableViewCell {

    /// Model containing the message data and selection state.
    /// This struct encapsulates all the data needed to display and manage a chat message.
    public struct ContentModel {
        /// The conversation view data containing the message content and metadata
        public let message: ConversationViewData
        /// Whether the message is currently selected for bulk actions
        public var isSelected: Bool = false
    }

    // MARK: UI Elements

    /// The main content view that displays the message content.
    /// This view handles the layout and display of message text, attachments, and metadata.
    open internal(set) lazy var chatMessageView: LMChatMessageContentView = {
        let view = LMUIComponents.shared.messageContentView.init()
            .translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()

    /// A stack view that contains the retry button for failed messages.
    /// This view is positioned at the trailing edge of the message cell.
    open private(set) lazy var retryContainerStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 0
        view.addArrangedSubview(retryButton)
        return view
    }()

    /// A button that appears when a message fails to send.
    /// This button allows users to retry sending failed messages.
    open private(set) lazy var retryButton: LMButton = {
        let button = LMButton()
            .translatesAutoresizingMaskIntoConstraints()
        button.addTarget(
            self,
            action: #selector(retrySendMessage),
            for: .touchUpInside
        )
        button.setImage(
            Constants.shared.images.retryIcon.withSystemImageConfig(
                pointSize: 25
            ),
            for: .normal
        )
        button.backgroundColor = Appearance.shared.colors.clear
        button.tintColor = Appearance.shared.colors.red
        button.setWidthConstraint(with: 30)
        button.setHeightConstraint(with: 30)
        button.isHidden = true
        return button
    }()

    /// A button that appears when the cell is in selection mode.
    /// This button allows users to select messages for bulk actions.
    open private(set) lazy var selectedButton: LMButton = {
        let button = LMButton()
            .translatesAutoresizingMaskIntoConstraints()
        button.addTarget(
            self,
            action: #selector(selectedRowButton),
            for: .touchUpInside
        )
        button.isHidden = true
        button.backgroundColor = Appearance.shared.colors.clear
        return button
    }()

    /// The delegate that handles message cell interactions
    weak var delegate: LMChatMessageCellDelegate?

    /// The delegate that handles audio message playback
    weak var audioDelegate: LMChatAudioProtocol?

    /// The delegate that handles poll interactions
    weak var pollDelegate: LMChatPollViewDelegate?

    /// The current data model containing the message and selection state
    public var data: ContentModel?

    /// The current index path of the cell in the table view
    var currentIndexPath: IndexPath?

    /// The original center position of the cell before any animations
    var originalCenter = CGPoint()

    /// A closure that handles reply action callbacks
    var replyActionHandler: (() -> Void)?

    /// Prepares the cell for reuse by resetting its state.
    /// This method is called when the cell is about to be reused in the table view.
    /// It resets the retry button visibility and prepares the message view for reuse.
    open override func prepareForReuse() {
        super.prepareForReuse()
        retryButton.isHidden = true
        chatMessageView.prepareToResuse()
    }

    /// Handles the selection button tap event.
    /// This method toggles the selection state of the cell and updates its visual appearance.
    /// - Parameter sender: The button that was tapped
    @objc func selectedRowButton(_ sender: UIButton) {
        let isSelected = !sender.isSelected
        sender.backgroundColor =
            isSelected
            ? Appearance.shared.colors.linkColor.withAlphaComponent(0.4)
            : Appearance.shared.colors.clear
        sender.isSelected = isSelected
        delegate?.didTappedOnSelectionButton(indexPath: currentIndexPath)
    }

    /// Sets up the initial view hierarchy and constraints.
    /// This method adds all subviews to the cell and configures their initial state.
    open override func setupViews() {
        super.setupViews()
        contentView.addSubview(containerView)
        containerView.addSubview(chatMessageView)
        containerView.addSubview(retryContainerStackView)
        contentView.addSubview(selectedButton)
        chatMessageView.textLabel.canPerformActionRestriction = true
        chatMessageView.textLabel.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(tappedTextView)
            )
        )
    }

    /// Sets up the layout constraints for all subviews.
    /// This method configures the Auto Layout constraints for proper positioning of all elements.
    open override func setupLayouts() {
        super.setupLayouts()
        contentView.pinSubView(subView: containerView)
        NSLayoutConstraint.activate([
            retryContainerStackView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -8
            ),
            retryContainerStackView.centerYAnchor.constraint(
                equalTo: chatMessageView.centerYAnchor
            ),

            chatMessageView.topAnchor.constraint(
                equalTo: containerView.topAnchor
            ),
            chatMessageView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: 8
            ),
            chatMessageView.trailingAnchor.constraint(
                equalTo: retryContainerStackView.leadingAnchor
            ),
            chatMessageView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor
            ),
        ])
        contentView.pinSubView(subView: selectedButton)
    }

    /// Sets up the visual appearance of the cell and its subviews.
    /// This method configures colors, backgrounds, and other visual properties.
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.clear
        contentView.backgroundColor = Appearance.shared.colors.clear
        chatMessageView.backgroundColor = Appearance.shared.colors.clear
        containerView.backgroundColor = Appearance.shared.colors.clear
    }

    /// Handles tap gestures on the text view to detect links and routes.
    /// This method processes taps on text to handle URL and route navigation.
    /// - Parameter tapGesture: The tap gesture recognizer that triggered this method
    @objc
    open func tappedTextView(tapGesture: UITapGestureRecognizer) {
        guard let textView = tapGesture.view as? LMTextView,
            let position = textView.closestPosition(
                to: tapGesture.location(in: textView)
            ),
            let text = textView.textStyling(at: position, in: .forward)
        else { return }
        if let url = text[.link] as? URL {
            didTapURL(url: url)
        } else if let route = text[.route] as? String {
            didTapRoute(route: route)
        }
    }

    /// Handles tapping on a route link.
    /// This method delegates the route navigation to the delegate.
    /// - Parameter route: The route string to navigate to
    open func didTapRoute(route: String) {
        delegate?.didTapRoute(route: route)
    }

    /// Handles tapping on a URL link.
    /// This method delegates the URL handling to the delegate.
    /// - Parameter url: The URL that was tapped
    open func didTapURL(url: URL) {
        delegate?.didTapURL(url: url)
    }

    /// Configures the cell with the provided data.
    /// This method sets up all the visual elements and state based on the provided content model.
    /// - Parameters:
    ///   - data: The content model containing message data and selection state
    ///   - index: The index path of the cell in the table view
    open func setData(with data: ContentModel, index: IndexPath) {
        self.data = data
        retryButton.isHidden = true
        chatMessageView.setDataView(data, index: index)
        chatMessageView.loaderView.delegate = self
        chatMessageView.retryView.delegate = self
        updateSelection(data: data)
        chatMessageView.delegate = self
        if data.message.isIncoming == false {
            intialiseRetryView()
        }
        if data.message.hideLeftProfileImage == true {
            chatMessageView.chatProfileImageView.isHidden = true
            chatMessageView.usernameLabel.isHidden = true
        }

    }

    /// Initializes the retry view based on message status and timestamps.
    /// This method shows the retry button if a message has failed or if an attachment upload is pending for more than 30 seconds.
    /// The method handles both regular messages and messages with attachments differently.
    open func intialiseRetryView() {
        if !(data?.message.id?.hasPrefix("-") ?? false) {
            // The string starts with "-", so we return early.
            return
        }

        if data?.message.messageStatus == .failed {
            toggleRetryButtonView(isHidden: false)
        }

        let currentTimeStampEpoch = Int(Date().timeIntervalSince1970 * 1000)
        if data?.message.attachments?.isEmpty ?? true {
            if currentTimeStampEpoch
                - (data?.message.localCreatedEpoch ?? currentTimeStampEpoch)
                > 30000
            {
                guard let data else { return }
                toggleRetryButtonView(isHidden: false)

                delegate?.onRetryButtonClicked(
                    conversation: data.message
                )
            }
        } else {
            if currentTimeStampEpoch
                - (data?.message.attachmentUploadedEpoch
                    ?? currentTimeStampEpoch) > 30000
            {
                toggleRetryButtonView(isHidden: false)
            }
        }
    }

    /// Updates the selection state of the cell.
    /// This method updates the visual appearance of the selection button based on the selection state.
    /// - Parameter data: The content model containing the selection state
    open func updateSelection(data: ContentModel) {
        let isSelected = data.isSelected
        selectedButton.backgroundColor =
            isSelected
            ? Appearance.shared.colors.linkColor.withAlphaComponent(0.4)
            : Appearance.shared.colors.clear
        selectedButton.isSelected = isSelected
    }

    /// Handles the retry button tap event for failed messages.
    /// This method triggers the retry action for failed message sends.
    /// - Parameter sender: The button that was tapped
    @objc open func retrySendMessage(_ sender: UIButton) {
        guard let data else { return }
        data.message.localCreatedEpoch = Int(
            Date().timeIntervalSince1970 * 1000
        )
        delegate?.onRetryButtonClicked(conversation: data.message)
    }

    /// Toggles the visibility of the retry button.
    /// This method controls whether the retry button is shown or hidden.
    /// - Parameter isHidden: Whether the retry button should be hidden
    open func toggleRetryButtonView(isHidden: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.retryButton.isHidden = isHidden
            self?.chatMessageView.loaderView.isHidden = !isHidden
            self?.chatMessageView.retryView.isHidden = isHidden
        }
    }
}

/// Extension that handles attachment loader view delegate methods.
/// This extension manages the UI state when attachment uploads are cancelled.
extension LMChatMessageCell: LMAttachmentLoaderViewDelegate {
    /// Called when the user cancels an attachment upload.
    /// This method updates the UI to show the retry view and hides the loader view.
    public func cancelUploadingAttachmentClicked() {
        guard let currentIndexPath else { return }
        chatMessageView.loaderView.isHidden = true
        chatMessageView.retryView.isHidden = false
        delegate?.didCancelAttachmentUploading(indexPath: currentIndexPath)
    }
}

/// Extension that handles attachment upload retry view delegate methods.
/// This extension manages the UI state when attachment uploads are retried.
extension LMChatMessageCell: LMAttachmentUploadRetryViewDelegate {
    /// Called when the user requests to retry an attachment upload.
    /// This method updates the UI to show the loader view and hides the retry view.
    public func retryUploadingAttachmentClicked() {
        guard let currentIndexPath else { return }
        chatMessageView.loaderView.isHidden = false
        chatMessageView.retryView.isHidden = true
        delegate?.didRetryAttachmentUploading(indexPath: currentIndexPath)
    }
}

/// Extension that handles chat message content view delegate methods.
/// This extension manages various interactions with the message content.
extension LMChatMessageCell: LMChatMessageContentViewDelegate {
    public func didTapOnReplyPrivatelyCell() {
        if let indexPath = currentIndexPath {
            delegate?.didTapOnReplyPrivatelyCell(indexPath: indexPath)
        }

    }

    /// Called when the user taps on a reply preview.
    /// This method delegates the reply interaction to the cell delegate.
    public func didTapOnReplyPreview() {
        delegate?.onClickReplyOfMessage(indexPath: currentIndexPath)
    }

    /// Called when the user taps on a profile link.
    /// This method delegates the profile navigation to the cell delegate.
    /// - Parameter route: The route string for profile navigation
    public func didTapOnProfileLink(route: String) {
        delegate?.didTapOnProfileLink(route: route)
    }

    /// Called when the user taps on a reaction.
    /// This method delegates the reaction interaction to the cell delegate.
    /// - Parameter reaction: The reaction string that was tapped
    public func clickedOnReaction(_ reaction: String) {
        delegate?.onClickReactionOfMessage(
            reaction: reaction,
            indexPath: currentIndexPath
        )
    }

    /// Called when the user taps on an attachment.
    /// This method delegates the attachment interaction to the cell delegate.
    /// - Parameter url: The URL of the attachment that was tapped
    public func clickedOnAttachment(_ url: String) {
        delegate?.onClickAttachmentOfMessage(
            url: url,
            indexPath: currentIndexPath
        )
    }

}
