//
//  LMChatMessageListView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 21/03/24.
//

import Foundation

/// Represents the direction of scrolling in the chat message list.
/// Used to determine whether the user is scrolling up or down through messages.
public enum ScrollDirection: Int {
    /// Scrolling downward through messages (newer messages)
    case scroll_DOWN = 1
    /// Scrolling upward through messages (older messages)
    case scroll_UP = 0
    /// No scrolling direction (initial state)
    case none = -1
}

/// Base protocol for handling URL and route taps in chat messages.
/// Provides basic functionality for handling link interactions.
public protocol LMChatMessageBaseProtocol: AnyObject {
    /// Called when a URL in a message is tapped.
    /// - Parameter url: The URL that was tapped.
    func didTapURL(url: URL)

    /// Called when a route in a message is tapped.
    /// - Parameter route: The route string that was tapped.
    func didTapRoute(route: String)
}

/// Delegate protocol for handling various interactions in the chat message list view.
/// Extends LMChatMessageBaseProtocol to provide additional functionality.
public protocol LMChatMessageListViewDelegate: LMChatMessageBaseProtocol {
    /// Called when a cell in the message list is tapped.
    /// - Parameter indexPath: The index path of the tapped cell.
    func didTapOnCell(indexPath: IndexPath)

    /// Called when the user scrolls to fetch more messages.
    /// - Parameters:
    ///   - indexPath: The current index path where the scroll occurred.
    ///   - direction: The direction of the scroll.
    func fetchDataOnScroll(indexPath: IndexPath, direction: ScrollDirection)

    /// Called when a reaction is tapped on a message.
    /// - Parameters:
    ///   - reaction: The reaction string that was tapped.
    ///   - indexPath: The index path of the message.
    func didTappedOnReaction(reaction: String, indexPath: IndexPath)

    /// Called when an attachment in a message is tapped.
    /// - Parameters:
    ///   - url: The URL of the attachment.
    ///   - indexPath: The index path of the message.
    func didTappedOnAttachmentOfMessage(url: String, indexPath: IndexPath)

    /// Called when a gallery item in a message is tapped.
    /// - Parameters:
    ///   - attachmentIndex: The index of the tapped attachment in the gallery.
    ///   - indexPath: The index path of the message.
    func didTappedOnGalleryOfMessage(attachmentIndex: Int, indexPath: IndexPath)

    /// Called when a reply preview in a message is tapped.
    /// - Parameter indexPath: The index path of the message.
    func didTappedOnReplyPreviewOfMessage(indexPath: IndexPath)

    /// Called when a context menu item is clicked.
    /// - Parameters:
    ///   - type: The type of action that was selected.
    ///   - indexPath: The index path of the message.
    ///   - message: The message data associated with the action.
    func contextMenuItemClicked(
        withType type: LMMessageActionType,
        atIndex indexPath: IndexPath,
        message: ConversationViewData
    )

    /// Called when a reaction is added to a message.
    /// - Parameters:
    ///   - reaction: The reaction string that was added.
    ///   - indexPath: The index path of the message.
    func didReactOnMessage(reaction: String, indexPath: IndexPath)

    /// Returns the context menu for a specific message.
    /// - Parameters:
    ///   - indexPath: The index path of the message.
    ///   - item: The message data.
    /// - Returns: A UIMenu object containing the available actions.
    func getMessageContextMenu(
        _ indexPath: IndexPath,
        item: ConversationViewData
    ) -> UIMenu?

    /// Returns the swipe action for a specific row.
    /// - Parameter indexPath: The index path of the row.
    /// - Returns: A UIContextualAction object for the swipe action.
    func trailingSwipeAction(forRowAtIndexPath indexPath: IndexPath)
        -> UIContextualAction?

    /// Called when the table view is scrolled.
    /// - Parameter scrollView: The scroll view that was scrolled.
    func didScrollTableView(_ scrollView: UIScrollView)

    /// Called when uploading of a message is cancelled.
    /// - Parameters:
    ///   - tempId: The temporary ID of the message.
    ///   - messageId: The ID of the message.
    func didCancelUploading(tempId: String, messageId: String)

    /// Called when uploading of a message needs to be retried.
    /// - Parameter messageId: The ID of the message to retry.
    func didRetryUploading(message: ConversationViewData)

    /// Called when audio playback should be stopped.
    func stopPlayingAudio()
}

/// Represents different types of actions that can be performed on a message.
public enum LMMessageActionType: String {
    /// Delete the message
    case delete
    /// Reply to the message
    case reply
    /// Reply privately to the message
    case replyPrivately
    /// Copy the message content
    case copy
    /// Edit the message
    case edit
    /// Select the message
    case select
    /// Invite users
    case invite
    /// Report the message
    case report
    /// Set topic for the message
    case setTopic
}

/// Represents the current status of a message.
public enum LMMessageStatus: String {
    /// Message is currently being sent
    case sending
    /// Message has been successfully sent
    case sent
    /// Message failed to send
    case failed
}

/// A view that displays a list of chat messages in a table view format.
/// This class handles message display, scrolling, selection, and interaction with messages.
@IBDesignable
open class LMChatMessageListView: LMView {
    /// The message type identifier for chatroom header messages.
    public static var chatroomHeader = 111

    /// A model representing the content of a section in the message list.
    public struct ContentModel {
        /// Array of conversation data items in this section
        public var data: [ConversationViewData]
        /// The section header text
        public let section: String
        /// Timestamp for the section
        public let timestamp: Int

        /// Initializes a new content model.
        /// - Parameters:
        ///   - data: Array of conversation data items
        ///   - section: Section header text
        ///   - timestamp: Section timestamp
        public init(
            data: [ConversationViewData],
            section: String,
            timestamp: Int
        ) {
            self.data = data
            self.section = section
            self.timestamp = timestamp
        }
    }

    // MARK: UI Elements
    /// The main container view that holds the table view.
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()

    /// The table view that displays the chat messages.
    open private(set) lazy var tableView: LMTableView = { [unowned self] in
        let table = LMTableView().translatesAutoresizingMaskIntoConstraints()
        table.register(LMUIComponents.shared.chatMessageCell)
        table.register(LMUIComponents.shared.chatNotificationCell)
        table.register(LMUIComponents.shared.chatroomHeaderMessageCell)
        table.register(LMUIComponents.shared.chatMessageGalleryCell)
        table.register(LMUIComponents.shared.chatMessageDocumentCell)
        table.register(LMUIComponents.shared.chatMessageAudioCell)
        table.register(LMUIComponents.shared.chatMessageLinkPreviewCell)
        table.register(LMUIComponents.shared.chatMessagePollCell)
        table.register(LMUIComponents.shared.chatMessageCustomCell)
        table.dataSource = self
        table.delegate = self
        table.showsVerticalScrollIndicator = false
        table.clipsToBounds = true
        table.separatorStyle = .none
        table.backgroundView = loadingView
        table.contentInset = .init(top: 0, left: 0, bottom: 8, right: 0)
        return table
    }()

    /// The loading shimmer view shown while content is being loaded.
    private(set) lazy var loadingView: LMChatMessageLoadingShimmerView = {
        let view = LMChatMessageLoadingShimmerView()
            .translatesAutoresizingMaskIntoConstraints()
        view.setWidthConstraint(with: UIScreen.main.bounds.size.width)
        return view
    }()

    // MARK: Data Variables
    /// The default height for message cells
    public let cellHeight: CGFloat = 60
    /// The delegate for handling message list interactions
    public weak var delegate: LMChatMessageListViewDelegate?
    /// The delegate for handling cell-specific interactions
    public weak var cellDelegate: LMChatMessageCellDelegate?
    /// The delegate for handling poll interactions
    public weak var pollDelegate: LMChatPollViewDelegate?
    /// The delegate for handling chatroom header interactions
    public weak var chatroomHeaderCellDelegate:
        LMChatroomHeaderMessageCellDelegate?
    /// The delegate for handling audio playback
    public weak var audioDelegate: LMChatAudioProtocol?
    /// Array of content models representing sections in the table view
    public var tableSections: [ContentModel] = []
    /// The current playing audio message's index information
    public var audioIndex: (section: Int, messageID: String)?
    /// The tag format for the current logged-in user
    public var currentLoggedInUserTagFormat: String = ""
    /// The replacement tag format for the current logged-in user
    public var currentLoggedInUserReplaceTagFormat: String = ""

    /// The height of the reaction view
    public let reactionHeight: CGFloat = 50.0
    /// The spacing between reaction views
    public let spaceReactionHeight: CGFloat = 10.0
    /// The height of the context menu
    public let menuHeight: CGFloat = 200
    /// Whether multiple message selection is enabled
    public var isMultipleSelectionEnable: Bool = false
    /// Array of currently selected messages
    public var selectedItems: [ConversationViewData] = []

    /// The last content offset of the scroll view, used for scroll direction detection
    open var lastContentOffset: CGFloat = 0

    // MARK: setupViews
    /// Sets up the initial view hierarchy.
    /// This method is called during view initialization to add and configure subviews.
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(tableView)
    }

    /// Sets up the layout constraints for all subviews.
    /// This method configures the Auto Layout constraints to position all UI elements correctly.
    open override func setupLayouts() {
        super.setupLayouts()

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tableView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor
            ),
            tableView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor
            ),
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tableView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor
            ),
        ])
    }

    /// Configures the visual appearance of the view and its subviews.
    /// This method sets up colors, styles, and other visual properties.
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.backgroundColor
        containerView.backgroundColor = Appearance.shared.colors.backgroundColor
        tableView.backgroundColor = Appearance.shared.colors.backgroundColor
    }

    /// Reloads the table view data and removes the loading shimmer effect.
    /// This method should be called when the message data has been updated.
    /// The reload is performed on the main thread to ensure UI updates are thread-safe.
    public func reloadData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Optionally sort your tableSections if needed:
            // self.tableSections.sort { $0.timestamp < $1.timestamp }
            self.removeShimmer()
            self.tableView.reloadData()
        }
    }

    /// Removes the loading shimmer effect from the table view if there is data to display.
    /// This method is called internally when data is loaded and the shimmer effect is no longer needed.
    public func removeShimmer() {
        if !tableSections.isEmpty { tableView.backgroundView = nil }
    }

    /// Scrolls the table view to the bottom of the content.
    /// - Parameter animation: A boolean indicating whether the scroll should be animated. Defaults to false.
    /// - Note: This method includes a small delay to ensure proper layout before scrolling.
    public func scrollToBottom(animation: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            let indexPath = IndexPath(
                row: self.tableView.numberOfRows(
                    inSection: self.tableView.numberOfSections - 1
                ) - 1,
                section: self.tableView.numberOfSections - 1
            )
            if hasRowAtIndexPath(indexPath: indexPath) {
                self.tableView.scrollToRow(
                    at: indexPath,
                    at: .bottom,
                    animated: animation
                )
            }
        }

        func hasRowAtIndexPath(indexPath: IndexPath) -> Bool {
            return indexPath.section < tableView.numberOfSections
                && indexPath.row
                    < tableView.numberOfRows(inSection: indexPath.section)
        }
    }

    /// Scrolls the table view to a specific message at the given index path.
    /// - Parameters:
    ///   - indexPath: The index path of the message to scroll to.
    ///   - animation: A boolean indicating whether the scroll should be animated. Defaults to false.
    /// - Note: After scrolling, the target message cell will be highlighted briefly to draw attention to it.
    public func scrollAtIndexPath(indexPath: IndexPath, animation: Bool = false)
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            self.tableView.scrollToRow(
                at: indexPath,
                at: .middle,
                animated: animation
            )
            let messageCell =
                tableView.cellForRow(at: indexPath) as? LMChatMessageCell
            let chatroomCell =
                tableView.cellForRow(at: indexPath)
                as? LMChatroomHeaderMessageCell
            let cell = messageCell ?? chatroomCell
            guard let cell else { return }
            cell.containerView.backgroundColor = Appearance.shared.colors
                .linkColor.withAlphaComponent(0.4)
            UIView.animate(
                withDuration: 2,
                delay: 1,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 1,
                options: .allowUserInteraction,
                animations: { cell.containerView.backgroundColor = .clear }
            ) { _ in }
        }
    }

    /// Resets the audio playback state for the currently playing audio message.
    /// This method should be called when audio playback needs to be stopped or reset.
    public func resetAudio() {
        if let audioIndex,
            tableSections.indices.contains(audioIndex.section),
            let index = tableSections[audioIndex.section].data.firstIndex(
                where: { $0.id == audioIndex.messageID })
        {
            (tableView.cellForRow(
                at: .init(row: index, section: audioIndex.section)
            )
                as? LMChatAudioViewCell)?.resetAudio()
        }
    }
}

// MARK: UITableView
extension LMChatMessageListView: UITableViewDataSource, UITableViewDelegate {
    /// Returns the number of sections in the table view.
    /// - Parameter tableView: The table view requesting the information.
    /// - Returns: The number of sections in the table view.
    open func numberOfSections(in tableView: UITableView) -> Int {
        tableSections.count
    }

    /// Returns the number of rows in a given section.
    /// - Parameters:
    ///   - tableView: The table view requesting the information.
    ///   - section: The index of the section.
    /// - Returns: The number of rows in the specified section.
    open func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        tableSections[section].data.count
    }

    /// Configures and returns a cell for the specified index path.
    /// - Parameters:
    ///   - tableView: The table view requesting the cell.
    ///   - indexPath: The index path specifying the location of the cell.
    /// - Returns: A configured UITableViewCell object.
    /// - Note: This method handles different types of message cells based on the message content type.
    open func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let item = tableSections[indexPath.section].data[indexPath.row]
        var tableViewCell: UITableViewCell = UITableViewCell()
        switch item.messageType {
        case 0:
            tableViewCell = cellFor(rowAt: indexPath, tableView: tableView)
        case 10:
            tableViewCell = pollCellFor(
                rowAt: indexPath,
                tableView: tableView
            )
        case Self.chatroomHeader:
            if let cell = tableView.dequeueReusableCell(
                LMUIComponents.shared.chatroomHeaderMessageCell
            ) {
                cell.setData(with: .init(message: item), index: indexPath)
                cell.currentIndexPath = indexPath
                cell.delegate = chatroomHeaderCellDelegate
                tableViewCell = cell
            }
        case -99:
            return chatMessageShimmer()
        default:
            if let cell = tableView.dequeueReusableCell(
                LMUIComponents.shared.chatNotificationCell
            ) {
                cell.setData(
                    with: .init(
                        message: item,
                        loggedInUserTag: currentLoggedInUserTagFormat,
                        loggedInUserReplaceTag:
                            currentLoggedInUserReplaceTagFormat
                    )
                )
                cell.delegate = delegate
                tableViewCell = cell
            }
        }
        tableViewCell.setNeedsDisplay()
        return tableViewCell
    }

    /// Creates and returns a shimmer cell for loading state.
    /// - Returns: A UITableViewCell configured as a shimmer loading cell.
    func chatMessageShimmer() -> UITableViewCell {
        var cell: LMChatMessageLoadingShimmerViewCell
        cell = LMChatMessageLoadingShimmerViewCell.init()
        cell.backgroundColor = Appearance.shared.colors.backgroundColor
        return cell
    }

    /// Configures and returns a poll cell for the specified index path.
    /// - Parameters:
    ///   - rowAt: The index path of the row.
    ///   - tableView: The table view requesting the cell.
    /// - Returns: A configured LMChatMessageCell for displaying polls.
    func pollCellFor(rowAt indexPath: IndexPath, tableView: UITableView)
        -> LMChatMessageCell
    {
        let item = tableSections[indexPath.section].data[indexPath.row]
        var cell: LMChatMessageCell?
        cell = tableView.dequeueReusableCell(
            LMUIComponents.shared.chatMessagePollCell
        )
        guard let cell else { return LMChatMessageCell() }
        let isSelected = selectedItems.firstIndex(where: {
            $0.id == item.id
        })
        cell.pollDelegate = pollDelegate
        cell.delegate = cellDelegate
        cell.setData(
            with: .init(message: item, isSelected: isSelected != nil),
            index: indexPath
        )
        cell.currentIndexPath = indexPath
        if self.isMultipleSelectionEnable, item.isDeleted == false {
            cell.selectedButton.isHidden = false
        } else {
            cell.selectedButton.isHidden = true
        }
        return cell
    }

    /// Configures and returns a message cell for the specified index path.
    /// - Parameters:
    ///   - rowAt: The index path of the row.
    ///   - tableView: The table view requesting the cell.
    /// - Returns: A configured LMChatMessageCell for displaying messages.
    func cellFor(rowAt indexPath: IndexPath, tableView: UITableView)
        -> LMChatMessageCell
    {
        let item = tableSections[indexPath.section].data[indexPath.row]
        var cell: LMChatMessageCell?
        if item.widget != nil {
            if let lmMeta = item.widget?.lmMeta, lmMeta.type == .REPLY_PRIVATELY
            {
                cell = tableView.dequeueReusableCell(
                    LMUIComponents.shared.chatMessageCell
                )
            } else {
                // For any other type of content, handle it with a custom widget
                cell = tableView.dequeueReusableCell(
                    LMUIComponents.shared.chatMessageCustomCell
                )
            }
        } else if let attachments = item.attachments,
            !attachments.isEmpty,
            let type = attachments.first?.type
        {
            switch type {
            case .image, .video, .gif:
                cell = tableView.dequeueReusableCell(
                    LMUIComponents.shared.chatMessageGalleryCell
                )
            case .pdf, .doc, .document:
                cell = tableView.dequeueReusableCell(
                    LMUIComponents.shared.chatMessageDocumentCell
                )
            case .audio, .voiceNote:
                cell = tableView.dequeueReusableCell(
                    LMUIComponents.shared.chatMessageAudioCell
                )
            default:
                cell = tableView.dequeueReusableCell(
                    LMUIComponents.shared.chatMessageCell
                )
            }
        } else if item.ogTags != nil {
            cell = tableView.dequeueReusableCell(
                LMUIComponents.shared.chatMessageLinkPreviewCell
            )
        } else {
            cell = tableView.dequeueReusableCell(
                LMUIComponents.shared.chatMessageCell
            )
        }
        guard let cell else { return LMChatMessageCell() }
        let isSelected = selectedItems.firstIndex(where: {
            $0.id == item.id
        })
        cell.currentIndexPath = indexPath
        cell.delegate = cellDelegate
        cell.audioDelegate = audioDelegate
        cell.setData(
            with: .init(message: item, isSelected: isSelected != nil),
            index: indexPath
        )

        if self.isMultipleSelectionEnable, item.isDeleted == false {
            cell.selectedButton.isHidden = false
        } else {
            cell.selectedButton.isHidden = true
        }
        return cell
    }

    /// Handles the selection of a row in the table view.
    /// - Parameters:
    ///   - tableView: The table view informing the delegate about the row selection.
    ///   - indexPath: The index path of the selected row.
    /// - Note: Selection behavior varies based on whether multiple selection is enabled.
    open func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if !self.isMultipleSelectionEnable {
            self.delegate?.didTapOnCell(indexPath: indexPath)
        }
    }

    /// Configures and returns the view to be used for the header of a section.
    /// - Parameters:
    ///   - tableView: The table view requesting the header view.
    ///   - section: The index of the section whose header view is being requested.
    /// - Returns: A view to be used as the header of the specified section.
    open func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        if let cell = tableView.dequeueReusableCell(
            LMUIComponents.shared.chatNotificationCell
        ) {
            cell.infoLabel.text = tableSections[section].section
            cell.containerView.backgroundColor = Appearance.shared.colors.clear
            return cell
        }
        return LMView()
    }

    /// Configures the swipe actions for a row.
    /// - Parameters:
    ///   - tableView: The table view requesting the swipe actions configuration.
    ///   - indexPath: The index path of the row.
    /// - Returns: A UISwipeActionsConfiguration object containing the swipe actions.
    /// - Note: Swipe actions are only available for non-deleted, sent messages when multiple selection is disabled.
    public func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = tableSections[indexPath.section].data[indexPath.row]
        guard
            (item.messageType == 0 || item.messageType == 10)
                && item.isDeleted == false && item.messageStatus == .sent
                && !isMultipleSelectionEnable
        else { return nil }
        guard
            let replyAction = delegate?.trailingSwipeAction(
                forRowAtIndexPath: indexPath
            )
        else { return nil }
        let swipeConfig = UISwipeActionsConfiguration(actions: [replyAction])
        swipeConfig.performsFirstActionWithFullSwipe = true
        return swipeConfig
    }

    /// Handles the beginning of row editing.
    /// - Parameters:
    ///   - tableView: The table view informing the delegate about the editing state.
    ///   - indexPath: The index path of the row being edited.
    /// - Note: This method automatically disables editing after a short delay.
    public func tableView(
        _ tableView: UITableView,
        willBeginEditingRowAt indexPath: IndexPath
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tableView.isEditing = false
        }
    }

    /// Determines whether multiple selection interaction should begin at the specified index path.
    /// - Parameters:
    ///   - tableView: The table view requesting the information.
    ///   - indexPath: The index path where the interaction would begin.
    /// - Returns: A boolean indicating whether multiple selection should be allowed.
    public func tableView(
        _ tableView: UITableView,
        shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
    ) -> Bool {

        return true
    }

    /// Handles the beginning of multiple selection interaction.
    /// - Parameters:
    ///   - tableView: The table view informing the delegate about the multiple selection state.
    ///   - indexPath: The index path where the multiple selection interaction began.
    public func tableView(
        _ tableView: UITableView,
        didBeginMultipleSelectionInteractionAt indexPath: IndexPath
    ) {
        //        self.setEditing(true, animated: true)
    }

    /// Handles the end of multiple selection interaction.
    /// - Parameter tableView: The table view informing the delegate about the end of multiple selection.
    public func tableViewDidEndMultipleSelectionInteraction(
        _ tableView: UITableView
    ) {
    }

    /// Determines whether a row can be edited.
    /// - Parameters:
    ///   - tableView: The table view requesting the information.
    ///   - indexPath: The index path of the row.
    /// - Returns: A boolean indicating whether the row can be edited.
    /// - Note: Only non-deleted messages of type 0 or 10 can be edited.
    public func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool {

        let item = tableSections[indexPath.section].data[indexPath.row]
        guard
            (item.messageType == 0 || item.messageType == 10)
                && item.isDeleted == false
        else { return false }
        return true
    }

    /// Handles the beginning of scroll view dragging.
    /// - Parameter scrollView: The scroll view that will begin dragging.
    /// - Note: This method stores the current content offset for scroll direction detection.
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }

    /// Handles scroll view scrolling.
    /// - Parameter scrollView: The scroll view that is scrolling.
    /// - Note: This method notifies the delegate about scroll events.
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.didScrollTableView(scrollView)
    }

    /// Configures the context menu for a row.
    /// - Parameters:
    ///   - tableView: The table view requesting the context menu configuration.
    ///   - indexPath: The index path of the row.
    ///   - point: The location of the interaction in the table view's coordinate space.
    /// - Returns: A UIContextMenuConfiguration object containing the context menu configuration.
    /// - Note: Context menu is only available for non-deleted, sent messages when multiple selection is disabled.
    @available(iOS 13.0, *)
    public func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let item = tableSections[indexPath.section].data[indexPath.row]
        guard !self.isMultipleSelectionEnable,
            (item.messageType == 0 || item.messageType == 10
                || item.messageType == Self.chatroomHeader)
                && item.messageStatus == .sent && (item.isDeleted != true)
        else { return nil }
        let identifier = NSString(
            string: "\(indexPath.row),\(indexPath.section)"
        )
        return UIContextMenuConfiguration(
            identifier: identifier,
            previewProvider: nil
        ) { [weak self] _ in
            guard let self = self else { return nil }
            return delegate?.getMessageContextMenu(indexPath, item: item)
        }
    }

    /// Handles the end of cell display.
    /// - Parameters:
    ///   - tableView: The table view informing the delegate about the cell.
    ///   - cell: The cell that ended displaying.
    ///   - indexPath: The index path of the cell.
    /// - Note: This method handles cleanup of audio playback when cells are removed from view.
    open func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        (cell as? LMChatAudioViewCell)?.resetAudio()
        if let audioIndex,
            tableSections.indices.contains(audioIndex.section),
            indexPath.section == audioIndex.section,
            let row = tableSections[indexPath.section].data.firstIndex(where: {
                $0.id == audioIndex.messageID
            }),
            row == indexPath.row
        {
            delegate?.stopPlayingAudio()
        }
    }

    @available(iOS 13.0, *)
    public func tableView(
        _ tableView: UITableView,
        previewForHighlightingContextMenuWithConfiguration configuration:
            UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        makeTargetedPreview(for: configuration)
    }

    @available(iOS 13.0, *)
    public func tableView(
        _ tableView: UITableView,
        previewForDismissingContextMenuWithConfiguration configuration:
            UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        makeTargetedDismissPreview(for: configuration)
    }

    @available(iOS 13.0, *)
    public func tableView(
        _ tableView: UITableView,
        willPerformPreviewActionForMenuWith configuration:
            UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        animator.preferredCommitStyle = .pop
    }

    /// Creates and returns a targeted preview for the context menu.
    /// - Parameter configuration: The context menu configuration.
    /// - Returns: A UITargetedPreview object for the context menu.
    @available(iOS 13.0, *)
    func makeTargetedPreview(for configuration: UIContextMenuConfiguration)
        -> UITargetedPreview?
    {
        guard let identifier = configuration.identifier as? String else {
            return nil
        }
        let values = identifier.components(separatedBy: ",")
        guard let row = Int(values.first ?? "0") else { return nil }
        guard let section = Int(values.last ?? "0") else { return nil }
        let indexPath = IndexPath(row: row, section: section)
        let messageCell =
            tableView.cellForRow(at: indexPath) as? LMChatMessageCell
        let chatroomCell =
            tableView.cellForRow(at: indexPath) as? LMChatroomHeaderMessageCell
        let cell = messageCell ?? chatroomCell
        guard let cell else { return nil }
        guard
            let snapshot = cell.resizableSnapshotView(
                from: CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: cell.bounds.width,
                        height: min(
                            cell.bounds.height,
                            UIScreen.main.bounds.height - reactionHeight
                                - spaceReactionHeight - menuHeight
                        )
                    )
                ),
                afterScreenUpdates: false,
                withCapInsets: UIEdgeInsets.zero
            )
        else { return nil }

        let reactionView = LMChatReactionPopupView()
        reactionView.onReaction = { [weak self] reactionType in
            guard let self = self else { return }
            delegate?.didReactOnMessage(
                reaction: reactionType.rawValue,
                indexPath: indexPath
            )
            (delegate as? UIViewController)?.dismiss(animated: true)
        }
        reactionView.layer.cornerRadius = 10
        reactionView.layer.masksToBounds = true
        reactionView.translatesAutoresizingMaskIntoConstraints = false

        snapshot.layer.cornerRadius = 10
        snapshot.layer.masksToBounds = true
        snapshot.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(
                    width: cell.bounds.width,
                    height: snapshot.bounds.height + reactionHeight
                        + spaceReactionHeight
                )
            )
        )
        container.backgroundColor = .clear
        container.addSubview(reactionView)
        container.addSubview(snapshot)

        snapshot.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            .isActive = true
        snapshot.topAnchor.constraint(equalTo: container.topAnchor).isActive =
            true
        snapshot.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            .isActive = true
        snapshot.bottomAnchor.constraint(
            equalTo: reactionView.topAnchor,
            constant: -spaceReactionHeight
        ).isActive = true

        reactionView.leadingAnchor.constraint(
            equalTo: container.leadingAnchor,
            constant: 10
        ).isActive = true
        reactionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            .isActive = true
        reactionView.heightAnchor.constraint(equalToConstant: reactionHeight)
            .isActive = true

        let centerPoint = CGPoint(x: cell.center.x, y: cell.center.y + 26)
        let previewTarget = UIPreviewTarget(
            container: tableView,
            center: centerPoint
        )
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            parameters.shadowPath = UIBezierPath()
        }
        return UITargetedPreview(
            view: container,
            parameters: parameters,
            target: previewTarget
        )
    }

    /// Creates and returns a targeted preview for dismissing the context menu.
    /// - Parameter configuration: The context menu configuration.
    /// - Returns: A UITargetedPreview object for dismissing the context menu.
    @available(iOS 13.0, *)
    func makeTargetedDismissPreview(
        for configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? String else {
            return nil
        }
        let values = identifier.components(separatedBy: ",")
        guard let row = Int(values.first ?? "0") else { return nil }
        guard let section = Int(values.last ?? "0") else { return nil }
        let indexPath = IndexPath(row: row, section: section)
        let messageCell =
            tableView.cellForRow(at: indexPath) as? LMChatMessageCell
        let chatroomCell =
            tableView.cellForRow(at: indexPath) as? LMChatroomHeaderMessageCell
        let cell = messageCell ?? chatroomCell
        guard let cell else { return nil }
        guard
            let snapshot = cell.resizableSnapshotView(
                from: CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: cell.bounds.width,
                        height: min(
                            cell.bounds.height,
                            UIScreen.main.bounds.height - reactionHeight
                                - spaceReactionHeight - menuHeight
                        )
                    )
                ),
                afterScreenUpdates: false,
                withCapInsets: UIEdgeInsets.zero
            )
        else { return nil }

        let centerPoint = CGPoint(x: cell.center.x, y: cell.center.y)
        let previewTarget = UIPreviewTarget(
            container: tableView,
            center: centerPoint
        )
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        if #available(iOS 14.0, *) {
            parameters.shadowPath = UIBezierPath()
        }
        return UITargetedPreview(
            view: snapshot,
            parameters: parameters,
            target: previewTarget
        )
    }
}
