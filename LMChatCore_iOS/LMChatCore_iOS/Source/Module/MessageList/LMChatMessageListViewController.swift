//
//  LMChatMessageListViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 18/03/24.
//

import AVFoundation
import GiphyUISDK
import LikeMindsChatData
import LikeMindsChatUI
import UIKit

open class LMChatMessageListViewController: LMViewController {
    // MARK: UI Elements
    open private(set) lazy var bottomMessageBoxView:
        LMChatBottomMessageComposerView = {
            [unowned self] in
            let view = LMChatBottomMessageComposerView()
                .translatesAutoresizingMaskIntoConstraints()
            view.layer.cornerRadius = 16
            view.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
            ]
            view.delegate = self
            view.inputTextView.mentionDelegate = self
            return view
        }()

    open private(set) lazy var scrollToBottomButton: LMButton = {
        [unowned self] in
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(
            Constants.shared.images.downChevronArrowIcon,
            for: .normal
        )
        button.contentMode = .scaleToFill
        button.isHidden = true
        button.setWidthConstraint(with: 40)
        button.setHeightConstraint(with: 40)
        button.backgroundColor = Appearance.shared.colors.white
            .withAlphaComponent(0.8)
        button.tintColor = Appearance.shared.colors.black
        button.cornerRadius(with: 20)
        button.addTarget(
            self,
            action: #selector(scrollToBottomClicked),
            for: .touchUpInside
        )
        return button
    }()

    open private(set) lazy var messageListView: LMChatMessageListView = {
        [unowned self] in
        let view = LMChatMessageListView()
            .translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .systemGroupedBackground
        view.delegate = self
        view.cellDelegate = self
        view.audioDelegate = self
        view.pollDelegate = self
        view.chatroomHeaderCellDelegate = self
        return view
    }()

    open private(set) lazy var chatroomTopicBar: LMChatroomTopicView = {
        let view = LMChatroomTopicView()
            .translatesAutoresizingMaskIntoConstraints()
        view.isHidden = true
        return view
    }()

    open private(set) lazy var taggingListView: LMChatTaggingListView = {
        [unowned self] in
        let view = LMChatTaggingListView()
            .translatesAutoresizingMaskIntoConstraints()
        let viewModel = LMChatTaggingListViewModel(delegate: view)
        view.viewModel = viewModel
        view.delegate = self
        return view
    }()

    open private(set) lazy var bottomMessageLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.textAlignment = .center
        label.font = Appearance.shared.fonts.normalFontSize12
        label.textColor = Appearance.shared.colors.previewSubtitleTextColor
        label.backgroundColor = Appearance.shared.colors.clear
        label.numberOfLines = 0
        label.paddingTop = 6
        label.paddingBottom = 16
        label.paddingLeft = 8
        label.paddingRight = 8
        label.isHidden = true
        return label
    }()

    open private(set) lazy var bottomLabelContainerView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 2
        view.backgroundColor = Appearance.shared.colors.backgroundColor
        return view
    }()

    open private(set) var taggingViewHeightConstraints: NSLayoutConstraint?

    public var viewModel: LMChatMessageListViewModel?
    var linkDetectorTimer: Timer?
    var bottomTextViewContainerBottomConstraints: NSLayoutConstraint?

    open private(set) lazy var deleteMessageBarItem: UIBarButtonItem = {
        [unowned self] in
        let buttonItem = UIBarButtonItem(
            image: Constants.shared.images.deleteIcon,
            style: .plain,
            target: self,
            action: #selector(deleteSelectedMessageAction)
        )
        return buttonItem
    }()

    open private(set) lazy var cancelSelectionsBarItem: UIBarButtonItem = {
        [unowned self] in
        let buttonItem = UIBarButtonItem(
            image: Constants.shared.images.crossIcon,
            style: .plain,
            target: self,
            action: #selector(cancelSelectedMessageAction)
        )
        return buttonItem
    }()

    open private(set) lazy var copySelectedMessagesBarItem: UIBarButtonItem = {
        [unowned self] in
        let buttonItem = UIBarButtonItem(
            image: Constants.shared.images.copyIcon,
            style: .plain,
            target: self,
            action: #selector(copySelectedMessageAction)
        )
        return buttonItem
    }()

    var isLoadingMoreData: Bool = false
    var lastSectionItem: LMChatMessageListView.ContentModel?
    var lastRowItem: ConversationViewData?
    let backButtonItem = LMBarButtonItem()

    open override func viewDidLoad() {
        super.viewDidLoad()

        setNavigationTitleAndSubtitle(
            with: "Chatroom",
            subtitle: nil,
            alignment: .center
        )
        setupNavigationBar()

        viewModel?.getInitialData()
        viewModel?.syncConversation()

        // Update send button state after getting initial data
        bottomMessageBoxView.updateSendButtonState()

        handleReplyPrivatelyViewConfiguration()

        setRightNavigationWithAction(
            title: nil,
            image: Constants.shared.images.ellipsisCircleIcon,
            style: .plain,
            target: self,
            action: #selector(chatroomActions)
        )
        // Sets the right most action for searching conversation in the chatroom
        setRightNavigationWithAction(
            title: nil,
            image: Constants.shared.images.searchIcon,
            style: .plain,
            target: self,
            action: #selector(navigateToSearchConversationScreen)
        )
        setupBackButtonItemWithImageView()
        self.navigationController?.interactivePopGestureRecognizer?.delegate =
            nil
        let attText = GetAttributedTextWithRoutes.getAttributedText(
            from: LMSharedPreferences.getString(
                forKey: viewModel?.chatroomId ?? "NA"
            ) ?? ""
        )
        if !attText.string.isEmpty {
            bottomMessageBoxView.inputTextView.attributedText = attText
            bottomMessageBoxView.tagSendButtonOnBasisOfText(attText.string)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                [weak self] in
                self?.bottomMessageBoxView.inputTextView.becomeFirstResponder()
            }
        }
        LMChatCore.analytics?.trackEvent(
            for: .chatRoomOpened,
            eventProperties: [
                LMChatAnalyticsKeys.chatroomId.rawValue: viewModel?.chatroomId,
                LMChatAnalyticsKeys.chatroomType.rawValue: viewModel?
                    .chatroomViewData?.type?.value,
                LMChatAnalyticsKeys.chatroomName.rawValue: viewModel?
                    .chatroomViewData?.header,
                LMChatAnalyticsKeys.communityId.rawValue: viewModel?
                    .chatroomViewData?.communityId,
                LMChatAnalyticsKeys.source.rawValue: "home_feed",
            ]
        )
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel?.isConversationSyncCompleted == true {
            viewModel?.addObserveConversations()
        }
        bottomMessageBoxView.inputTextView.mentionDelegate?
            .contentHeightChanged()
        LMChatCore.openedChatroomId = viewModel?.chatroomId
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LMChatCore.openedChatroomId = nil
    }

    func setupBackButtonItemWithImageView() {
        backButtonItem.actionButton.addTarget(
            self,
            action: #selector(dismissViewController),
            for: .touchUpInside
        )
        navigationItem.leftItemsSupplementBackButton = false
        navigationItem.leftBarButtonItem = backButtonItem
    }

    open override func setupAppearance() {
        super.setupAppearance()
        scrollToBottomButton.addShadow()
        chatroomTopicBar.addShadow()
    }

    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        self.view.addSubview(messageListView)
        self.view.addSubview(bottomMessageBoxView)
        self.view.addSubview(chatroomTopicBar)
        self.view.addSubview(bottomLabelContainerView)
        self.view.addSubview(scrollToBottomButton)

        bottomLabelContainerView.addArrangedSubview(bottomMessageLabel)
        bottomMessageBoxView.addOnVerticleStackView.insertArrangedSubview(
            taggingListView,
            at: 0
        )
        bottomMessageBoxView.inputTextView.placeHolderText =
            "Type your response"
        chatroomTopicBar.onTopicViewClick = { [weak self] topicId in
            self?.topicBarClicked(topicId: topicId)
        }
    }

    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        bottomTextViewContainerBottomConstraints = bottomMessageBoxView
            .bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            )
        bottomTextViewContainerBottomConstraints?.isActive = true

        NSLayoutConstraint.activate([
            chatroomTopicBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            chatroomTopicBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            chatroomTopicBar.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),

            messageListView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            messageListView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            messageListView.bottomAnchor.constraint(
                equalTo: bottomMessageBoxView.topAnchor
            ),
            messageListView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),

            bottomLabelContainerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            bottomLabelContainerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            bottomLabelContainerView.bottomAnchor.constraint(
                equalTo: bottomMessageBoxView.topAnchor
            ),

            scrollToBottomButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -10
            ),
            scrollToBottomButton.bottomAnchor.constraint(
                equalTo: bottomLabelContainerView.topAnchor,
                constant: -10
            ),

            bottomMessageBoxView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            bottomMessageBoxView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
        ])
        taggingViewHeightConstraints = taggingListView.setHeightConstraint(
            with: 0
        )
    }

    @objc
    open override func keyboardWillShow(_ sender: Notification) {
        guard let userInfo = sender.userInfo,
            let frame =
                (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                .cgRectValue
        else {
            return
        }
        self.bottomTextViewContainerBottomConstraints?.isActive = false
        self.bottomTextViewContainerBottomConstraints?.constant =
            -((frame.size.height - self.view.safeAreaInsets.bottom))
        self.bottomTextViewContainerBottomConstraints?.isActive = true
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    @objc
    open override func keyboardWillHide(_ sender: Notification) {
        self.bottomTextViewContainerBottomConstraints?.isActive = false
        self.bottomTextViewContainerBottomConstraints?.constant = 0
        self.bottomTextViewContainerBottomConstraints?.isActive = true
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    open override func setupObservers() {
        super.setupObservers()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioEnded),
            name: .LMChatAudioEnded,
            object: nil
        )
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        LMChatAudioRecordManager.shared.deleteAudioRecording()
        LMChatAudioPlayManager.shared.resetAudioPlayer()
        viewModel?.removeObserveConversations()
        viewModel?.markChatroomAsRead()
        self.view.endEditing(true)
    }

    @objc
    open func chatroomActions() {
        self.view.endEditing(true)
        guard let actions = viewModel?.chatroomActionData?.chatroomActions
        else { return }
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections =
            UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(
            x: self.view.bounds.midX,
            y: self.view.bounds.midY,
            width: 0,
            height: 0
        )
        for item in actions {
            let actionItem = UIAlertAction(
                title: item.title,
                style: UIAlertAction.Style.default
            ) { [weak self] (UIAlertAction) in
                self?.viewModel?.performChatroomActions(action: item)
            }
            alert.addAction(actionItem)
        }
        let cancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertAction.Style.cancel
        ) { (UIAlertAction) in
        }
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }

    /**
     Navigates to the search conversation screen.
     This method attempts to create a search conversation module corresponding to the current chatroom by performing the following steps:
     */
    @objc
    open func navigateToSearchConversationScreen() {
        do {
            let searchListVC =
                try LMChatSearchConversationListViewModel.createModule(
                    chatroomId: viewModel?.chatroomId ?? ""
                )

            self.navigationController?.pushViewController(
                searchListVC,
                animated: true
            )
        } catch _ {
            self.showErrorAlert(message: "An error occurred")
        }
    }

    @objc
    open func scrollToBottomClicked(_ sender: UIButton) {
        self.scrollToBottomButton.isHidden = true
        viewModel?.fetchBottomConversations(onButtonClicked: true)
    }

    @objc
    open func deleteSelectedMessageAction() {
        guard !messageListView.selectedItems.isEmpty else { return }
        deleteMessageConfirmation(
            messageListView.selectedItems.compactMap({ $0.id })
        )
    }

    func deleteMessageConfirmation(_ conversationIds: [String]) {
        let alert = UIAlertController(
            title: "Delete Message?",
            message: Constants.shared.strings.warningMessageForDeletion,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: "Delete",
                style: .destructive,
                handler: { [weak self] action in
                    self?.viewModel?.deleteConversations(
                        conversationIds: conversationIds
                    )
                    self?.cancelSelectedMessageAction()
                }
            )
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    @objc
    open func copySelectedMessageAction() {
        guard !messageListView.selectedItems.isEmpty else { return }
        viewModel?.copyConversation(
            conversationIds: messageListView.selectedItems.compactMap({ $0.id })
        )
        cancelSelectedMessageAction()
    }

    @objc
    open func cancelSelectedMessageAction() {
        messageListView.isMultipleSelectionEnable = false
        messageListView.selectedItems.removeAll()
        navigationItem.rightBarButtonItems = nil
        setRightNavigationWithAction(
            title: nil,
            image: Constants.shared.images.ellipsisCircleIcon,
            style: .plain,
            target: self,
            action: #selector(chatroomActions)
        )
        // Set the right most action for search conversation in chatroom
        setRightNavigationWithAction(
            title: nil,
            image: Constants.shared.images.searchIcon,
            style: .plain,
            target: self,
            action: #selector(navigateToSearchConversationScreen)
        )
        updateChatroomSubtitles()
        memberRightsCheck()
        messageListView.reloadData()
    }

    open func multipleSelectionEnable() {
        let barButtonItems: [UIBarButtonItem] = [
            cancelSelectionsBarItem, copySelectedMessagesBarItem,
            deleteMessageBarItem,
        ]
        navigationItem.rightBarButtonItems = barButtonItems
        bottomMessageBoxView.enableOrDisableMessageBox(
            withMessage: "",
            isEnable: false
        )
        navigationTitleView.isHidden = true
    }

    public func updateChatroomSubtitles() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            navigationTitleView.isHidden = false
        }

        guard viewModel?.isChatroomType(type: .directMessage) == false else {
            return
        }
        let participantCount =
            viewModel?.chatroomActionData?.participantCount ?? 0
        let subtitle =
            participantCount > 0 ? "\(participantCount) participants" : ""
        setNavigationTitleAndSubtitle(
            with: viewModel?.chatroomViewData?.header,
            subtitle: subtitle
        )
        memberRightsCheck()
        // Update send button state after updating chatroom subtitles
        bottomMessageBoxView.updateSendButtonState()
    }

    func topicBarClicked(topicId: String) {
        guard let chatroom = viewModel?.chatroomViewData else {
            return
        }
        viewModel?.fetchIntermediateConversations(
            chatroom: chatroom,
            conversationId: topicId
        )
    }

    public func memberRightsCheck() {
        guard viewModel?.isChatroomType(type: .directMessage) == false else {
            directMessageStatus()
            return
        }
        if viewModel?.chatroomViewData?.type == .purpose
            && viewModel?.memberState?.state == 1
        {
            bottomMessageBoxView.enableOrDisableMessageBox(
                withMessage: "",
                isEnable: true
            )
        } else if viewModel?.chatroomViewData?.type == .purpose
            && viewModel?.memberState?.state != 1
        {
            bottomMessageBoxView.enableOrDisableMessageBox(
                withMessage: Constants.shared.strings.restrictForAnnouncement,
                isEnable: false
            )
        } else if viewModel?.chatroomViewData?.isSecret == true
            && viewModel?.chatroomViewData?.followStatus == false
        {
            bottomMessageBoxView.enableOrDisableMessageBox(
                withMessage: Constants.shared.strings
                    .secretChatroomRestrictionMessage,
                isEnable: false
            )
        } else if viewModel?.checkMemberRight(.respondsInChatRoom) == false
            || viewModel?.chatroomViewData?.memberCanMessage == false
        {
            bottomMessageBoxView.enableOrDisableMessageBox(
                withMessage: Constants.shared.strings.restrictByManager,
                isEnable: false
            )
        } else {
            if let canMessage = viewModel?.chatroomViewData?.memberCanMessage,
                let hasRight = viewModel?.checkMemberRight(.respondsInChatRoom)
            {
                bottomMessageBoxView.enableOrDisableMessageBox(
                    withMessage: Constants.shared.strings.restrictByManager,
                    isEnable: canMessage && hasRight
                )
            } else {
                bottomMessageBoxView.enableOrDisableMessageBox(
                    withMessage: "",
                    isEnable: true
                )
            }
        }
        // Update send button state after updating direct message status
        bottomMessageBoxView.updateSendButtonState()
    }

    public func directMessageValidation() {
        if viewModel?.loggedInUserData?.sdkClientInfo?.uuid
            == viewModel?.chatroomViewData?.chatWithUser?.sdkClientInfo?.uuid
        {
            setNavigationTitleAndSubtitle(
                with: viewModel?.chatroomViewData?.member?.name,
                subtitle: nil
            )
            backButtonItem.imageView.kf.setImage(
                with: URL(
                    string: viewModel?.chatroomViewData?.member?.imageUrl ?? ""
                ),
                placeholder: UIImage.generateLetterImage(
                    name: viewModel?.directMessageUserName().components(
                        separatedBy: " "
                    ).first ?? ""
                )
            )
        } else {
            setNavigationTitleAndSubtitle(
                with: viewModel?.chatroomViewData?.chatWithUser?.name,
                subtitle: nil
            )
            backButtonItem.imageView.kf.setImage(
                with: URL(
                    string: viewModel?.chatroomViewData?.chatWithUser?.imageUrl
                        ?? ""
                ),
                placeholder: UIImage.generateLetterImage(
                    name: viewModel?.directMessageUserName().components(
                        separatedBy: " "
                    ).first ?? ""
                )
            )
        }
        if viewModel?.dmStatus?.showDM == false {
            bottomMessageBoxView.enableOrDisableMessageBox(
                withMessage: Constants.shared.strings.m2mDirectMessageDisable,
                isEnable: false
            )
        }
        let isDMWithRequestEnabled = LMSharedPreferences.bool(
            forKey: LMSharedPreferencesKeys.isDMWithRequestEnabled.rawValue
        )
        if viewModel?.chatroomViewData?.chatRequestState == nil {
            if isDMWithRequestEnabled == true {
                bottomMessageBoxView.sendButton.tag =
                    bottomMessageBoxView.messageButtonTag
                bottomMessageBoxView.sendButton.setImage(
                    bottomMessageBoxView.sendButtonIcon,
                    for: .normal
                )
                bottomMessageBoxView.attachmentButton.isHidden = true
                bottomMessageBoxView.gifButton.isHidden = true
                bottomMessageLabel.text = String(
                    format: Constants.shared.strings.bottomMessage,
                    viewModel?.directMessageUserName() ?? ""
                )
                bottomMessageLabel.isHidden =
                    !(viewModel?.chatroomViewData?.isPrivateMember == true)
            }
        } else {
            bottomMessageLabel.isHidden = true
            switch viewModel?.chatroomViewData?.chatRequestState {
            case .initiated:
                bottomMessageBoxView.enableOrDisableMessageBox(
                    withMessage: Constants.shared.strings.pendingChatRequest,
                    isEnable: false
                )
                if viewModel?.loggedInUserData?.sdkClientInfo?.uuid
                    == viewModel?.chatroomViewData?.chatRequestedByUser?
                    .sdkClientInfo?.uuid
                {
                    bottomMessageBoxView.enableOrDisableMessageBox(
                        withMessage: Constants.shared.strings
                            .pendingChatRequest,
                        isEnable: false
                    )
                } else {
                    updateBottomBar(
                        footerView: LMChatDirectMessageFooterView.createView(
                            Constants.shared.strings.approveRejectViewTitle,
                            delegate: self
                        )
                    )
                }
            case .approved:
                bottomMessageBoxView.enableOrDisableMessageBox(
                    withMessage: nil,
                    isEnable: true
                )
                bottomMessageBoxView.attachmentButton.isHidden = false
                bottomMessageBoxView.gifButton.isHidden = false
                break
            case .rejected:
                bottomMessageBoxView.enableOrDisableMessageBox(
                    withMessage: Constants.shared.strings.pendingChatRequest,
                    isEnable: false
                )
                if viewModel?.loggedInUser()?.sdkClientInfo?.uuid
                    == viewModel?.chatroomViewData?.chatRequestedByUser?
                    .sdkClientInfo?.uuid
                {
                    // Tap to undo in converstion state 19
                    bottomMessageBoxView.enableOrDisableMessageBox(
                        withMessage: Constants.shared.strings
                            .rejectedChatRequest,
                        isEnable: false
                    )
                } else {
                    // remove Tap to undo in converstion state 19
                }
            default:
                break
            }
        }
        // Update send button state after updating direct message status
        bottomMessageBoxView.updateSendButtonState()
    }

    func updateBottomBar(footerView: UITableViewHeaderFooterView) {
        footerView.widthAnchor.constraint(
            equalToConstant: messageListView.tableView.frame.width
        ).isActive = true
        messageListView.tableView.tableFooterView = footerView
        messageListView.tableView.tableFooterView?.layoutIfNeeded()
        if let footer = messageListView.tableView.tableFooterView {
            var frame = footer.frame
            frame.size.height = 170
            footer.frame = frame
            messageListView.tableView.tableFooterView = footer
        }
    }

}

extension LMChatMessageListViewController: LMMessageListViewModelProtocol {
    public func toggleRetryButtonWithMessage(
        indexPath: IndexPath,
        isHidden: Bool
    ) {
        // Ensure UI updates occur on the main thread
        DispatchQueue.main.async {
            if let cell = self.messageListView.tableView.cellForRow(
                at: indexPath
            ) as? LMChatMessageCell {
                cell.toggleRetryButtonView(isHidden: isHidden)
            }
        }
    }

    public func hideGifButton() {
        bottomMessageBoxView.gifButton.isHidden = true
        bottomMessageBoxView.gifButton.removeFromSuperview()
    }

    public func reloadMessage(at index: IndexPath) {
        guard let sectionData = viewModel?.messagesList[index.section] else {
            return
        }
        messageListView.tableSections[index.section] = sectionData
        messageListView.tableView.reloadData()
    }

    public func approveRejectView(isShow: Bool) {
        if !isShow {
            messageListView.tableView.tableFooterView = nil
        }
    }

    public func viewProfile(route: String) {
        LMChatCore.shared.coreCallback?.userProfileViewHandle(withRoute: route)
    }

    public func showToastMessage(message: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.bottomMessageBoxView.inputTextView.resignFirstResponder()
            self?.displayToast(
                message ?? "",
                font: Appearance.shared.fonts.headingFont1
            )
        }

    }

    public func scrollToSpecificConversation(
        indexPath: IndexPath,
        isExistingIndex: Bool = false
    ) {
        if isExistingIndex {
            self.messageListView.scrollAtIndexPath(indexPath: indexPath)
        } else {
            reloadChatMessageList()
            self.messageListView.scrollAtIndexPath(indexPath: indexPath)
        }
    }

    public func reloadChatMessageList() {
        messageListView.tableSections = (viewModel?.messagesList ?? [])
        messageListView.currentLoggedInUserTagFormat =
            viewModel?.loggedInUserTagValue ?? ""
        messageListView.currentLoggedInUserReplaceTagFormat =
            viewModel?.loggedInUserReplaceTagValue ?? ""
        messageListView.tableSections.sort(by: { $0.timestamp < $1.timestamp })
        modifyMessageWithTapToUndo()
        messageListView.reloadData()
        bottomMessageBoxView.inputTextView.chatroomId =
            viewModel?.chatroomViewData?.id ?? ""
        hideShowTopicBarView()
        // Update send button state after reloading messages
        bottomMessageBoxView.updateSendButtonState()
    }

    func modifyMessageWithTapToUndo() {
        guard viewModel?.isChatroomType(type: .directMessage) == true else {
            return
        }
        let section = messageListView.tableSections.count - 1
        let row = messageListView.tableSections[section].data.count - 1
        let message = messageListView.tableSections[section].data[row]
        guard
            let modifiedMessage = viewModel?
                .addTapToUndoForRejectedNotification(message)
        else { return }
        messageListView.tableSections[section].data[row] = modifiedMessage
    }

    func hideShowTopicBarView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if let firstSection = messageListView.tableSections.first,
                let message = firstSection.data.first,
                message.messageType == LMChatMessageListView.chatroomHeader,
                messageListView.tableView.cellForRow(
                    at: IndexPath(row: 0, section: 0)
                ) != nil
            {
                hideTopicBar(true)
            } else {
                hideTopicBar(false)
            }
        }
    }

    func hideTopicBar(_ isHidden: Bool) {
        if viewModel?.chatroomViewData?.type == .directMessage {
            self.chatroomTopicBar.isHidden = true
        } else if chatroomTopicBar.nameLabel.text?.isEmpty == false {
            self.chatroomTopicBar.isHidden = isHidden
        }
    }

    public func reloadData(at: ScrollDirection) {
        if at == .scroll_UP {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                [weak self] in
                guard let self else { return }
                messageListView.tableSections = viewModel?.messagesList ?? []
                messageListView.tableSections.sort(by: {
                    $0.timestamp < $1.timestamp
                })
                messageListView.reloadData()
                guard let lastSectionItem,
                    let lastRowItem,
                    let section = messageListView.tableSections.firstIndex(
                        where: { $0.section == lastSectionItem.section }),
                    let row = messageListView.tableSections[section].data
                        .firstIndex(where: { $0.id == lastRowItem.id })
                else { return }

                messageListView.tableView.scrollToRow(
                    at: IndexPath(row: row, section: section),
                    at: .top,
                    animated: false
                )
            }
        } else {
            messageListView.tableSections = viewModel?.messagesList ?? []
            messageListView.tableSections.sort(by: {
                $0.timestamp < $1.timestamp
            })
            messageListView.reloadData()
        }
    }

    public func scrollToBottom(forceToBottom: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            if self?.viewModel?.fetchingInitialBottomData == true {
                self?.messageListView.tableView.alpha = 0.001
            }
            self?.reloadChatMessageList()
            self?.bottomMessageBoxView.inputTextView.chatroomId =
                self?.viewModel?.chatroomViewData?.id ?? ""
            self?.updateChatroomSubtitles()
            if forceToBottom || ((self?.scrollToBottomButton.isHidden) != nil) {
                LMChatAudioPlayManager.shared.resetAudioPlayer()
                self?.messageListView.scrollToBottom()
                self?.scrollToBottomButton.isHidden = true
            }
            if self?.viewModel?.fetchingInitialBottomData == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    [weak self] in
                    self?.messageListView.tableView.alpha = 1
                }
            }
            self?.hideShowTopicBarView()
        }
    }

    public func insertLastMessageRow(section: String, conversationId: String) {
        messageListView.tableSections = viewModel?.messagesList ?? []
        messageListView.tableSections.sort(by: { $0.timestamp < $1.timestamp })
        if let sectionIndex = messageListView.tableSections.firstIndex(where: {
            $0.section == section
        }),
            let row = messageListView.tableSections[sectionIndex].data
                .firstIndex(where: { $0.id == conversationId })
        {
            let indexPath = IndexPath(
                row: row,
                section: sectionIndex
            )
            if self.messageListView.tableView.cellForRow(at: indexPath) == nil {
                self.scrollToBottomButton.isHidden = true
                self.messageListView.tableView.beginUpdates()
                self.messageListView.tableView.insertRows(
                    at: [indexPath],
                    with: .bottom
                )
                self.messageListView.tableView.endUpdates()
            } else {
                self.messageListView.tableView.beginUpdates()
                self.messageListView.tableView.reloadRows(
                    at: [indexPath],
                    with: .automatic
                )
                self.messageListView.tableView.endUpdates()
            }
        }
    }

    public func updateTopicBar() {
        if let topic = viewModel?.chatroomTopic {
            chatroomTopicBar.setData(
                .init(
                    title: GetAttributedTextWithRoutes.getAttributedText(
                        from: topic.answer
                    ).string,
                    createdBy: topic.member?.name ?? "",
                    chatroomImageUrl: topic.member?.imageUrl ?? "",
                    topicId: topic.id ?? "",
                    titleHeader: "Current Topic",
                    type: topic.state.rawValue,
                    attachmentsUrls: topic.attachments?.compactMap({
                        ($0.thumbnailUrl, $0.url, $0.type?.rawValue)
                    })
                )
            )
        } else {
            chatroomTopicBar.setData(
                .init(
                    title: viewModel?.chatroomViewData?.title ?? "",
                    createdBy: viewModel?.chatroomViewData?.member?.name ?? "",
                    chatroomImageUrl: viewModel?.chatroomViewData?
                        .chatroomImageUrl ?? "",
                    topicId: viewModel?.chatroomViewData?.id ?? "",
                    titleHeader: viewModel?.chatroomViewData?.member?.name
                        ?? "",
                    type: 1,
                    attachmentsUrls: []
                )
            )
        }

        if viewModel?.loggedInUserData?.sdkClientInfo?.uuid
            == viewModel?.chatroomViewData?.chatWithUser?.sdkClientInfo?.uuid
        {
            setNavigationTitleAndSubtitle(
                with: viewModel?.chatroomViewData?.member?.name,
                subtitle: nil
            )
        } else {
            setNavigationTitleAndSubtitle(
                with: viewModel?.chatroomViewData?.chatWithUser?.name,
                subtitle: nil
            )
        }
        if viewModel?.isChatroomType(type: .directMessage) == true {
            backButtonItem.imageView.kf.setImage(
                with: URL(
                    string: viewModel?.chatroomViewData?.chatroomImageUrl ?? ""
                ),
                placeholder: UIImage.generateLetterImage(
                    name: viewModel?.directMessageUserName().components(
                        separatedBy: " "
                    ).first ?? ""
                )
            )
        } else {
            backButtonItem.imageView.kf.setImage(
                with: URL(
                    string: viewModel?.chatroomViewData?.chatroomImageUrl ?? ""
                ),
                placeholder: UIImage.generateLetterImage(
                    name: viewModel?.chatroomViewData?.header?.components(
                        separatedBy: " "
                    ).first ?? ""
                )
            )
        }
        hideShowTopicBarView()
    }

    public func directMessageStatus() {
        directMessageValidation()
        // Update send button state after updating direct message status
        bottomMessageBoxView.updateSendButtonState()
    }
}

extension LMChatMessageListViewController: LMChatMessageListViewDelegate {
    public func stopPlayingAudio() {
        LMChatAudioPlayManager.shared.resetAudioPlayer()
    }

    public func didCancelUploading(tempId: String, messageId: String) {
        LMChatAWSManager.shared.cancelAllTaskFor(groupId: tempId)
        viewModel?.updateConversationUploadingStatus(
            messageId: messageId,
            withStatus: .failed
        )
    }

    public func didRetryUploading(message: ConversationViewData) {

        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections =
            UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(
            x: self.view.bounds.midX,
            y: self.view.bounds.midY,
            width: 0,
            height: 0
        )

        let tryAction = UIAlertAction(
            title: "Try again",
            style: UIAlertAction.Style.default
        ) { [weak self] (UIAlertAction) in
            guard let self else { return }
            viewModel?.retryConversation(conversation: message)
        }
        let retryIcon = Constants.shared.images.retryIcon
        tryAction.setValue(retryIcon, forKey: "image")

        let deleteAction = UIAlertAction(
            title: "Delete",
            style: UIAlertAction.Style.default
        ) { [weak self] (UIAlertAction) in
            guard let self else { return }
            viewModel?.deleteTempConversation(conversationId: message.id ?? "")
        }
        let deleteIcon = Constants.shared.images.trashIcon
        deleteAction.setValue(deleteIcon, forKey: "image")

        let cancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertAction.Style.cancel
        )

        alert.addAction(tryAction)
        alert.addAction(deleteAction)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }

    public func didScrollTableView(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height

        if let lastSection = messageListView.tableSections.last {
            let indexPath = IndexPath(
                row: (lastSection.data.count - 1),
                section: messageListView.tableSections.count - 1
            )
            if messageListView.tableView.cellForRow(at: indexPath) != nil {
                scrollToBottomButton.isHidden = true
            } else {
                scrollToBottomButton.isHidden = false
            }
        }

        if let firstSection = messageListView.tableSections.first,
            let message = firstSection.data.first,
            message.messageType == LMChatMessageListView.chatroomHeader,
            messageListView.tableView.cellForRow(
                at: IndexPath(row: 0, section: 0)
            ) != nil
        {
            hideTopicBar(true)
        } else {
            hideTopicBar(false)
        }

        // Check if user scrolled to the top
        if contentOffsetY <= 20 && !isLoadingMoreData
            && viewModel?.fetchingInitialBottomData == false
        {
            guard
                let visibleIndexPaths = messageListView.tableView
                    .indexPathsForVisibleRows,
                let firstIndexPath = visibleIndexPaths.first
            else { return }
            isLoadingMoreData = true

            fetchDataOnScroll(indexPath: firstIndexPath, direction: .scroll_UP)
        }

        // Check if user scrolled to the bottom
        if contentOffsetY + frameHeight >= contentHeight && !isLoadingMoreData
            && viewModel?.fetchingInitialBottomData == false
        {
            guard
                let visibleIndexPaths = messageListView.tableView
                    .indexPathsForVisibleRows,
                let lastIndexPath = visibleIndexPaths.last
            else { return }
            isLoadingMoreData = true
            fetchDataOnScroll(indexPath: lastIndexPath, direction: .scroll_DOWN)
        }
    }

    public func getMessageContextMenu(
        _ indexPath: IndexPath,
        item: ConversationViewData
    ) -> UIMenu? {

        if viewModel?.checkMemberRight(.respondsInChatRoom) == false
            || viewModel?.chatroomViewData?.memberCanMessage == false
        {
            contextMenuItemClicked(
                withType: .select,
                atIndex: indexPath,
                message: item
            )
            return nil
        }

        if viewModel?.isChatroomType(type: .directMessage) == true
            && viewModel?.chatroomViewData?.chatRequestState != .approved
        {
            return nil
        }

        if item.messageType == LMChatMessageListView.chatroomHeader {
            return contextMenuForChatroomData(indexPath, item: item)
        }
        var actions: [UIAction] = []
        if viewModel?.chatroomViewData?.isSecret == true
            && viewModel?.chatroomViewData?.followStatus == false
        {
            if !item.answer.isEmpty {
                let copyAction = UIAction(
                    title: Constants.shared.strings.copy,
                    image: Constants.shared.images.copyIcon
                ) { [weak self] action in
                    self?.contextMenuItemClicked(
                        withType: .copy,
                        atIndex: indexPath,
                        message: item
                    )
                }
                actions.append(copyAction)
            }
            let selectAction = UIAction(
                title: Constants.shared.strings.select,
                image: Constants.shared.images.checkmarkCircleIcon
            ) { [weak self] action in
                self?.contextMenuItemClicked(
                    withType: .select,
                    atIndex: indexPath,
                    message: item
                )
            }
            actions.append(selectAction)
            return UIMenu(title: "", children: actions)
        }

        let replyAction = UIAction(
            title: Constants.shared.strings.reply,
            image: Constants.shared.images.replyIcon
        ) { [weak self] action in
            self?.contextMenuItemClicked(
                withType: .reply,
                atIndex: indexPath,
                message: item
            )
        }
        actions.append(replyAction)

        // Check if Reply Privately should be shown
        if let dmStatus = viewModel?.dmStatus,
            let chatroomType = viewModel?.chatroomViewData?.type?.rawValue,
            LMConversationUtils.toShowReplyPrivatelyOption(
                selectedConversation: item,
                selectedChatTheme: LMChatCore.currentTheme,
                checkDMStatusResponse: dmStatus,
                chatroomType: chatroomType
            )
        {
            let replyPrivatelyAction = UIAction(
                title: Constants.shared.strings.replyPrivately,
                image: Constants.shared.images.replyIcon
            ) { [weak self] action in
                self?.handleReplyPrivately(for: item)
            }
            actions.append(replyPrivatelyAction)
        }

        if !item.answer.isEmpty {
            let copyAction = UIAction(
                title: Constants.shared.strings.copy,
                image: Constants.shared.images.copyIcon
            ) { [weak self] action in
                self?.contextMenuItemClicked(
                    withType: .copy,
                    atIndex: indexPath,
                    message: item
                )
            }
            actions.append(copyAction)
        }

        if viewModel?.isAdmin() == true {
            let setTopicAction = UIAction(
                title: Constants.shared.strings.setTopic,
                image: Constants.shared.images.documentsIcon
            ) { [weak self] action in
                self?.contextMenuItemClicked(
                    withType: .setTopic,
                    atIndex: indexPath,
                    message: item
                )
            }
            actions.append(setTopicAction)
        }

        if item.isIncoming == false,
            viewModel?.checkMemberRight(.respondsInChatRoom) == true
        {
            if item.answer.isEmpty == false {
                let editAction = UIAction(
                    title: Constants.shared.strings.edit,
                    image: Constants.shared.images.pencilIcon
                ) { [weak self] action in
                    self?.contextMenuItemClicked(
                        withType: .edit,
                        atIndex: indexPath,
                        message: item
                    )
                }
                actions.append(editAction)
            }

            let deleteAction = UIAction(
                title: Constants.shared.strings.delete,
                image: Constants.shared.images.trashIcon,
                attributes: .destructive
            ) { [weak self] action in
                self?.contextMenuItemClicked(
                    withType: .delete,
                    atIndex: indexPath,
                    message: item
                )
            }
            actions.append(deleteAction)
        } else {
            let reportAction = UIAction(
                title: Constants.shared.strings.reportMessage
            ) { [weak self] action in
                self?.contextMenuItemClicked(
                    withType: .report,
                    atIndex: indexPath,
                    message: item
                )
            }
            actions.append(reportAction)
        }

        let selectAction = UIAction(
            title: Constants.shared.strings.select,
            image: Constants.shared.images.checkmarkCircleIcon
        ) { [weak self] action in
            self?.contextMenuItemClicked(
                withType: .select,
                atIndex: indexPath,
                message: item
            )
        }
        actions.append(selectAction)

        return UIMenu(title: "", children: actions)
    }

    private func handleReplyPrivately(for conversation: ConversationViewData) {
        guard
            let memberUUID = conversation.member?.sdkClientInfo?.uuid,
            let chatroomName = viewModel?.chatroomViewData?.header
        else {
            self.showErrorAlert(message: "Something went wrong")
            return
        }

        let extra = LMChatReplyPrivatelyExtra(
            sourceChatroomName: chatroomName,
            sourceChatroomId: viewModel?.chatroomId ?? "",
            sourceConversation: conversation
        )

        let checkDMLimitRequest = CheckDMLimitRequest.builder().uuid(
            memberUUID
        ).build()

        LMChatClient.shared.checkDMLimit(request: checkDMLimitRequest) {
            [weak self] response in
            if response.success {
                if let chatroomId = response.data?.chatroomId {
                    DispatchQueue.main.async {
                        NavigationScreen.shared.perform(
                            .chatroom(
                                chatroomId: "\(chatroomId)",
                                conversationID: nil,
                                replyPrivatelyExtras: extra
                            ),
                            from: self!,
                            params: extra
                        )
                    }
                } else {
                    if LMDMChatUtil.isDMRequestEnabled() {
                        if response.data?.isRequestDMLimitExceeded == false {
                            LMDMChatUtil.createOrGetExistingDMChatroom(
                                userUUID: memberUUID
                            ) { [weak self] chatroomId, errorMessage in
                                guard let self else { return }

                                if let errorMessage = errorMessage {
                                    // Show error in snackbar (consistent with other error handling in the class)
                                    self.showErrorAlert(message: errorMessage)
                                    return
                                }

                                guard let chatroomId = chatroomId else {
                                    return
                                }

                                // Use the existing navigation pattern
                                DispatchQueue.main.async {
                                    NavigationScreen.shared.perform(
                                        .chatroom(
                                            chatroomId: chatroomId,
                                            conversationID: nil,
                                            replyPrivatelyExtras: extra
                                        ),
                                        from: self,
                                        params: extra
                                    )
                                }
                            }
                        } else {
                            self?.showErrorAlert(message: response.errorMessage)
                        }
                    } else {
                        LMDMChatUtil.createOrGetExistingDMChatroom(
                            userUUID: memberUUID
                        ) { [weak self] chatroomId, errorMessage in
                            guard let self else { return }

                            if let errorMessage = errorMessage {
                                // Show error in snackbar (consistent with other error handling in the class)
                                self.showErrorAlert(message: errorMessage)
                                return
                            }

                            guard let chatroomId = chatroomId else { return }

                            // Use the existing navigation pattern
                            DispatchQueue.main.async {
                                NavigationScreen.shared.perform(
                                    .chatroom(
                                        chatroomId: chatroomId,
                                        conversationID: nil,
                                        replyPrivatelyExtras: extra
                                    ),
                                    from: self,
                                    params: extra
                                )
                            }
                        }
                    }
                }
            } else {
                self?.showErrorAlert(message: response.errorMessage)
            }
        }
    }

    public func contextMenuForChatroomData(
        _ indexPath: IndexPath,
        item: ConversationViewData
    ) -> UIMenu {
        var actions: [UIAction] = []
        let replyAction = UIAction(
            title: Constants.shared.strings.reply,
            image: Constants.shared.images.replyIcon
        ) { [weak self] action in
            self?.contextMenuItemClicked(
                withType: .reply,
                atIndex: indexPath,
                message: item
            )
        }
        actions.append(replyAction)
        if !item.answer.isEmpty {
            let copyAction = UIAction(
                title: Constants.shared.strings.copy,
                image: Constants.shared.images.copyIcon
            ) { [weak self] action in
                self?.contextMenuItemClicked(
                    withType: .copy,
                    atIndex: indexPath,
                    message: item
                )
            }
            actions.append(copyAction)
        }

        return UIMenu(title: "", children: actions)
    }

    public func trailingSwipeAction(forRowAtIndexPath indexPath: IndexPath)
        -> UIContextualAction?
    {
        let item = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        guard viewModel?.checkMemberRight(.respondsInChatRoom) == true,
            item.isDeleted == false,
            viewModel?.chatroomViewData?.memberCanMessage == true
        else { return nil }
        if viewModel?.isChatroomType(type: .directMessage) == true
            && viewModel?.chatroomViewData?.chatRequestState != .approved
        {
            return nil
        }
        if viewModel?.chatroomViewData?.isSecret == true
            && viewModel?.chatroomViewData?.followStatus == false
        {
            return nil
        }
        let action = UIContextualAction(
            style: .normal,
            title: ""
        ) {
            [weak self]
            (
                contextAction: UIContextualAction,
                sourceView: UIView,
                completionHandler: (Bool) -> Void
            ) in
            self?.contextMenuItemClicked(
                withType: .reply,
                atIndex: indexPath,
                message: item
            )
            completionHandler(true)
        }
        let swipeReplyImage = Constants.shared.images.replyIcon
        action.image = swipeReplyImage
        action.backgroundColor = UIColor(
            red: 208.0 / 255.0,
            green: 216.0 / 255.0,
            blue: 226.0 / 255.0,
            alpha: 1.0
        )
        return action
    }

    public func didReactOnMessage(reaction: String, indexPath: IndexPath) {
        let message = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        if reaction == "more" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                guard let self else { return }
                let emojiPicker: NavigationActions =
                    message.messageType == LMChatMessageListView.chatroomHeader
                    ? .emojiPicker(conversationId: nil, chatroomId: message.id)
                    : .emojiPicker(conversationId: message.id, chatroomId: nil)
                NavigationScreen.shared.perform(
                    emojiPicker,
                    from: self,
                    params: nil
                )
            }
        } else {
            if message.messageType == LMChatMessageListView.chatroomHeader {
                viewModel?.putChatroomReaction(
                    chatroomId: message.id ?? "",
                    reaction: reaction
                )
            } else {
                viewModel?.putConversationReaction(
                    conversationId: message.id ?? "",
                    reaction: reaction
                )
            }
        }
    }

    public func contextMenuItemClicked(
        withType type: LMMessageActionType,
        atIndex indexPath: IndexPath,
        message: ConversationViewData
    ) {
        switch type {
        case .delete:
            deleteMessageConfirmation([message.id ?? ""])
        case .edit:
            viewModel?.editConversation(conversationId: message.id ?? "")
            guard
                let messageText = viewModel?.editChatMessage?.answer
                    .replacingOccurrences(
                        of: GiphyAPIConfiguration.gifMessage,
                        with: ""
                    ).trimmingCharacters(in: .whitespacesAndNewlines),
                !messageText.isEmpty
            else {
                viewModel?.editChatMessage = nil
                return
            }
            bottomMessageBoxView.inputTextView.becomeFirstResponder()
            bottomMessageBoxView.inputTextView.setAttributedText(
                from: messageText
            )
            bottomMessageBoxView.showEditView(
                withData: .init(
                    username: "",
                    replyMessage: messageText,
                    attachmentsUrls: [],
                    messageType: message.messageType
                )
            )
            break
        case .reply:
            bottomMessageBoxView.inputTextView.becomeFirstResponder()
            viewModel?.replyConversation(conversationId: message.id ?? "")
            var attachments = message.attachments?.compactMap({
                ($0.thumbnailUrl, $0.url, $0.type)
            })

            attachments =
                ((attachments?.count ?? 0) > 0)
                ? attachments
                : ((message.ogTags != nil)
                    ? [(message.ogTags?.url, message.ogTags?.url, .link)] : nil)

            bottomMessageBoxView.showReplyView(
                withData: .init(
                    username: message.member?.name,
                    replyMessage: message.answer,
                    attachmentsUrls: attachments,
                    messageType: message.messageType
                )
            )
            break
        case .copy:
            viewModel?.copyConversation(conversationIds: [message.id ?? ""])
            break
        case .report:
            NavigationScreen.shared.perform(
                .report(
                    chatroomId: nil,
                    conversationId: message.id ?? "",
                    memberId: nil,
                    type: getConversationType(message.attachments)
                ),
                from: self,
                params: nil
            )
        case .select:
            messageListView.isMultipleSelectionEnable = true
            messageListView.reloadData()
            multipleSelectionEnable()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                self?.didTappedOnSelectionButton(indexPath: indexPath)
                self?.messageListView.tableView.reloadRows(
                    at: [indexPath],
                    with: .none
                )
            }
        case .setTopic:
            viewModel?.setAsCurrentTopic(conversationId: message.id ?? "")
        case .replyPrivately:
            guard
                let conversation = viewModel?.chatMessages.first(where: {
                    $0.id == message.id ?? ""
                }),
                let uuid = conversation.member?.sdkClientInfo?.uuid
            else { return }

            var senderId =
                LMChatClient.shared.getLoggedInUser()?.sdkClientInfo?.uuid ?? ""

            LMChatCore.analytics?.trackEvent(
                for: LMChatAnalyticsEventName.replyPrivately,
                eventProperties: [
                    LMChatAnalyticsKeys.senderId.rawValue: senderId,
                    LMChatAnalyticsKeys.receiverId.rawValue: uuid,
                    LMChatAnalyticsKeys.chatroomId.rawValue: viewModel?
                        .chatroomId ?? "",
                    LMChatAnalyticsKeys.conversationId.rawValue: conversation
                        .id,
                ]
            )

            LMChatDMCreationHandler.shared.openDMChatroom(
                uuid: uuid,
                viewController: self
            ) { [weak self] chatroomId in
                guard let self, let chatroomId else { return }

                DispatchQueue.main.async {
                    NavigationScreen.shared.perform(
                        .chatroom(chatroomId: chatroomId, conversationID: nil),
                        from: self,
                        params: nil
                    )
                }
            }
        default:
            break
        }
    }

    public func didTappedOnReplyPreviewOfMessage(indexPath: IndexPath) {
        let message = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        guard let chatroom = viewModel?.chatroomViewData,
            let repliedId = message.replyConversation?.id
        else {
            return
        }

        if let mediumConversation = viewModel?.chatMessages.first(where: {
            $0.id == repliedId
        }) {
            guard
                let section = messageListView.tableSections.firstIndex(where: {
                    $0.section == mediumConversation.date
                }),
                let index = messageListView.tableSections[section].data
                    .firstIndex(where: { $0.id == mediumConversation.id })
            else { return }
            scrollToSpecificConversation(
                indexPath: IndexPath(row: index, section: section),
                isExistingIndex: true
            )
            return
        }

        viewModel?.fetchIntermediateConversations(
            chatroom: chatroom,
            conversationId: repliedId
        )
    }

    public func didTappedOnAttachmentOfMessage(
        url: String,
        indexPath: IndexPath
    ) {
        guard let fileUrl = URL(string: url.getLinkWithHttps()) else { return }
        let message = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        var eventProps =
            viewModel?.trackEventBasicParams(messageId: message.id) ?? [:]
        eventProps["url"] = url
        eventProps["type"] = "Link"
        LMChatCore.analytics?.trackEvent(
            for: .chatLinkClicked,
            eventProperties: eventProps
        )
        NavigationScreen.shared.perform(
            .browser(url: fileUrl),
            from: self,
            params: nil
        )
    }

    public func didTappedOnGalleryOfMessage(
        attachmentIndex: Int,
        indexPath: IndexPath
    ) {
        let message = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        guard let attachments = message.attachments, !attachments.isEmpty else {
            return
        }

        let eventProps =
            viewModel?.trackEventBasicParams(messageId: message.id) ?? [:]
        LMChatCore.analytics?.trackEvent(
            for: .imageViewed,
            eventProperties: eventProps
        )

        let mediaData: [LMChatMediaPreviewViewModel.DataModel.MediaModel] =
            attachments.compactMap {
                .init(
                    mediaType: MediaType(rawValue: ($0.type?.rawValue ?? ""))
                        ?? .image,
                    thumbnailURL: $0.thumbnailUrl,
                    mediaURL: $0.url ?? ""
                )
            }

        let data: LMChatMediaPreviewViewModel.DataModel = .init(
            userName: message.member?.name ?? "User",
            senDate: LMCoreTimeUtils.generateCreateAtDate(
                miliseconds: Double((message.createdEpoch ?? 0)),
                format: "dd MMM yyyy, HH:mm"
            ),
            media: mediaData
        )

        NavigationScreen.shared.perform(
            .mediaPreview(data: data, startIndex: attachmentIndex),
            from: self,
            params: nil
        )
    }

    public func didTappedOnReaction(reaction: String, indexPath: IndexPath) {
        let message = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        if message.messageType == LMChatMessageListView.chatroomHeader {

            let eventProps =
                viewModel?.trackEventBasicParams(messageId: message.id) ?? [:]
            LMChatCore.analytics?.trackEvent(
                for: .reactionListOpened,
                eventProperties: eventProps
            )

            NavigationScreen.shared.perform(
                .reactionSheet(
                    reactions: (viewModel?.chatroomViewData?.reactions ?? [])
                        .reversed(),
                    selectedReaction: reaction,
                    conversation: nil,
                    chatroomId: message.id
                ),
                from: self,
                params: nil
            )
            return
        }
        guard
            let conversation = viewModel?.chatMessages.first(where: {
                $0.id == message.id
            }),
            let reactions = conversation.reactions
        else { return }

        LMChatCore.analytics?.trackEvent(
            for: .reactionListOpened,
            eventProperties: [:]
        )

        NavigationScreen.shared.perform(
            .reactionSheet(
                reactions: reactions.reversed(),
                selectedReaction: reaction,
                conversation: conversation.id,
                chatroomId: nil
            ),
            from: self,
            params: nil
        )
    }

    public func fetchDataOnScroll(
        indexPath: IndexPath,
        direction: ScrollDirection
    ) {
        let message = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        lastRowItem = message
        lastSectionItem = messageListView.tableSections[indexPath.section]
        viewModel?.getMoreConversations(
            conversationId: message.id ?? "",
            direction: direction
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoadingMoreData = false
        }
    }

    public func didTapOnCell(indexPath: IndexPath) {
        self.bottomMessageBoxView.inputTextView.resignFirstResponder()
    }
}

extension LMChatMessageListViewController: LMChatBottomMessageComposerDelegate {
    /// Determines if the other user in the chatroom is an AI chatbot.
    /// - Returns: `true` if the other user is an AI chatbot, `false` otherwise.
    public func isOtherUserAIChatbotInChatroom() -> Bool {
        // Check if chatroomViewData is available in the viewModel
        if let chatroomViewData = viewModel?.chatroomViewData {
            // Check if the other user in the chatroom is an AI chatbot
            return isOtherUserAIChatbot(chatroom: chatroomViewData)
        }
        // Return false if chatroomViewData is not available
        return false
    }

    public func askForMicrophoneAccess() {
        LMChatCheckMediaAccess.askForMicrophoneAccess(from: self)
    }

    func clearTextView() {
        bottomMessageBoxView.inputTextView.text = ""
        bottomMessageBoxView.checkSendButtonGestures()
        bottomMessageBoxView.inputTextView.mentionDelegate?
            .contentHeightChanged()
    }

    public func cancelReply() {
        viewModel?.replyChatMessage = nil
        viewModel?.replyChatMessage = nil
        viewModel?.editChatMessage = nil
        bottomMessageBoxView.replyMessageViewContainer.isHidden = true
    }

    public func cancelReplyPrivatelyView() {
        viewModel?.chatroomDetailsExtra.replyPrivatelyExtras = nil
        bottomMessageBoxView.replyMessageViewContainer.isHidden = true
    }

    public func handleReplyPrivatelyViewConfiguration() {
        cancelReply()
        if let replyPrivatelyExtras = viewModel?.chatroomDetailsExtra
            .replyPrivatelyExtras
        {
            bottomMessageBoxView
                .showReplyPrivatelyView(
                    with: .init(replyPrivatelyExtra: replyPrivatelyExtras)
                )
        }

    }

    public func cancelLinkPreview() {
        viewModel?.currentDetectedOgTags = nil
        bottomMessageBoxView.linkPreviewView.isHidden = true
    }

    public func composeMessage(message: String, composeLink: String?) {

        if viewModel?.chatroomViewData?.type == .directMessage
            && viewModel?.chatroomViewData?.chatRequestState == nil
        {
            let isDMWithRequestEnabled = LMSharedPreferences.bool(
                forKey: LMSharedPreferencesKeys.isDMWithRequestEnabled.rawValue
            )
            if isDMWithRequestEnabled == true {
                if message.count > 300 {
                    self.showErrorAlert(
                        message: Constants.shared.strings.dmRequestTextLimit
                    )
                } else {
                    
                    if viewModel?.chatroomViewData?.isPrivateMember == true {
                        bottomMessageBoxView.inputTextView
                            .resignFirstResponder()
                        self.showAlertWithActions(
                            title: Constants.shared.strings.sendDMRequestTitle,
                            message: Constants.shared.strings
                                .sendDMRequestMessage,
                            withActions: [
                                ("Cancel", nil),
                                (
                                    "Confirm",
                                    { [weak self] in
                                        self?.bottomMessageBoxView
                                            .resetInputTextView()
                                        
                                        var metadata = self?.viewModel?.createMetadataForReplyPrivately()
                                        
                                        self?.viewModel?.sendDMRequest(
                                            text: message,
                                            requestState: .initiated,
                                            metadata: metadata
                                        )
                                        self?.bottomMessageBoxView
                                            .enableOrDisableMessageBox(
                                                withMessage: Constants.shared
                                                    .strings.pendingChatRequest,
                                                isEnable: false
                                            )
                                    }
                                ),
                            ]
                        )
                    } else {
                        bottomMessageBoxView.resetInputTextView()
                        var metadata = self.viewModel?.createMetadataForReplyPrivately()
                        viewModel?.sendDMRequest(
                            text: message,
                            requestState: .approved,
                            isAutoApprove: true,
                            metadata: metadata
                        )
                        bottomMessageLabel.isHidden = true
                    }
                }
            } else {
                bottomMessageBoxView.resetInputTextView()
                viewModel?.sendDMRequest(
                    text: message,
                    requestState: .approved,
                    isAutoApprove: true
                )
                bottomMessageLabel.isHidden = true
            }
            return
        }
        bottomMessageBoxView.resetInputTextView()
        if let chatMessage = viewModel?.editChatMessage {
            viewModel?.editChatMessage = nil
            viewModel?.postEditedConversation(
                text: message,
                shareLink: composeLink,
                conversation: chatMessage
            )
        } else {
            viewModel?.postMessage(
                message: message,
                filesUrls: nil,
                shareLink: composeLink,
                replyConversationId: viewModel?.replyChatMessage?.id,
                replyChatRoomId: viewModel?.replyChatroom,
                temporaryId: nil
            )
        }
        cancelReply()
        cancelLinkPreview()
    }

    @objc open func composeAttachment() {

        var isAIChatBot: Bool

        if let chatroomViewData = viewModel?.chatroomViewData {
            isAIChatBot = isOtherUserAIChatbot(chatroom: chatroomViewData)
        } else {
            isAIChatBot = false
        }

        LMSharedPreferences.setString(
            bottomMessageBoxView.inputTextView.getText(),
            forKey: viewModel?.chatroomId ?? "NA"
        )

        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.permittedArrowDirections =
            UIPopoverArrowDirection()
        alert.popoverPresentationController?.sourceRect = CGRect(
            x: self.view.bounds.midX,
            y: self.view.bounds.midY,
            width: 0,
            height: 0
        )
        let camera = UIAlertAction(
            title: "Camera",
            style: UIAlertAction.Style.default
        ) { [weak self] (UIAlertAction) in
            guard let self else { return }
            LMChatCheckMediaAccess.checkCameraAccess(
                viewController: self,
                delegate: self
            )
        }
        let cameraImage = Constants.shared.images.cameraIcon
        camera.setValue(cameraImage, forKey: "image")

        let photo = UIAlertAction(
            title: "Photo & Video",
            style: UIAlertAction.Style.default
        ) { [weak self] (UIAlertAction) in
            guard let self else { return }
            MediaPickerManager.shared.presentPicker(
                viewController: self,
                delegate: self,
                selectionLimit: isAIChatBot ? 1 : 10
            )
        }

        let photoImage = Constants.shared.images.galleryIcon
        photo.setValue(photoImage, forKey: "image")

        let audio = UIAlertAction(
            title: "Audio",
            style: UIAlertAction.Style.default
        ) { [weak self] (UIAlertAction) in
            guard let self else { return }
            MediaPickerManager.shared.presentAudioAndDocumentPicker(
                viewController: self,
                delegate: self,
                fileType: .audio,
                multipleAllowed: isAIChatBot ? false : true
            )
        }

        let audioImage = Constants.shared.images.micIcon
        audio.setValue(audioImage, forKey: "image")

        let document = UIAlertAction(
            title: "Document",
            style: UIAlertAction.Style.default
        ) { [weak self] (UIAlertAction) in
            guard let self else { return }
            MediaPickerManager.shared.presentAudioAndDocumentPicker(
                viewController: self,
                delegate: self,
                fileType: .pdf
            )
        }

        alert.addAction(camera)
        alert.addAction(photo)
        alert.addAction(audio)

        if let chatroomViewData = viewModel?.chatroomViewData,
            !isOtherUserAIChatbot(chatroom: chatroomViewData)
        {
            let documentImage = Constants.shared.images.documentsIcon
            document.setValue(documentImage, forKey: "image")
            alert.addAction(document)
        }

        let cancel = UIAlertAction(
            title: "Cancel",
            style: UIAlertAction.Style.cancel
        )

        if viewModel?.checkMemberRight(.createPolls) == true,
            viewModel?.isChatroomType(type: .directMessage) == false
        {
            let microPollAction = UIAlertAction(title: "Poll", style: .default)
            {
                [weak self] alertView in
                guard let self else { return }
                NavigationScreen.shared.perform(
                    .createPoll(delegate: self),
                    from: self,
                    params: nil
                )
            }
            let pollImage = Constants.shared.images.pollIcon
            microPollAction.setValue(pollImage, forKey: "image")
            alert.addAction(microPollAction)
        }

        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }

    public func composeAudio() {
        if let audioURL = LMChatAudioRecordManager.shared.recordingStopped() {
            let newURL = URL(fileURLWithPath: audioURL.absoluteString)
            let mediaModel = MediaPickerModel(with: newURL, type: .voice_note)

            let eventProps =
                viewModel?.trackEventBasicParams(messageId: nil) ?? [:]
            LMChatCore.analytics?.trackEvent(
                for: .voiceNoteSent,
                eventProperties: eventProps
            )

            postConversationWithAttchments(
                message: nil,
                attachments: [mediaModel]
            )
        }
        LMChatAudioRecordManager.shared.resetAudioParameters()
    }

    public func composeGif() {
        let giphy = GiphyViewController()
        giphy.mediaTypeConfig = [.gifs]
        giphy.theme = GPHTheme(type: .lightBlur)
        giphy.showConfirmationScreen = false
        giphy.rating = .ratedPG
        giphy.delegate = self
        self.present(giphy, animated: true, completion: nil)
    }

    public func linkDetected(_ link: String) {
        linkDetectorTimer?.invalidate()
        linkDetectorTimer = Timer.scheduledTimer(
            withTimeInterval: 0.3,
            repeats: false,
            block: { [weak self] timer in
                print("detected first link: \(link)")
                self?.viewModel?.decodeUrl(url: link) { [weak self] ogTags in
                    guard let ogTags else { return }
                    if self?.bottomMessageBoxView.detectedFirstLink != nil
                        && self?.bottomMessageBoxView.detectedFirstLink
                            == ogTags.url
                    {
                        self?.bottomMessageBoxView.linkPreviewView.isHidden =
                            false
                        self?.bottomMessageBoxView.linkPreviewView.setData(
                            .init(
                                title: ogTags.title,
                                description: ogTags.description,
                                link: ogTags.url,
                                imageUrl: ogTags.image
                            )
                        )
                    }
                }
            }
        )
    }

    public func audioRecordingStarted() {
        LMChatAudioPlayManager.shared.stopAudio {}
        // If Any Audio is playing, stop audio and reset audio view
        resetAudio()

        do {
            let canRecord = try LMChatAudioRecordManager.shared.recordAudio(
                audioDelegate: self
            )
            if canRecord {
                bottomMessageBoxView.showRecordingView()
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(updateRecordDuration),
                    name: .audioDurationUpdate,
                    object: nil
                )
                LMChatCore.analytics?.trackEvent(
                    for: .voiceNoteRecorded,
                    eventProperties: [
                        LMChatAnalyticsKeys.chatroomId.rawValue: "",
                        LMChatAnalyticsKeys.communityId.rawValue: "",
                        LMChatAnalyticsKeys.chatroomType.rawValue: "",
                    ]
                )
            } else {
                // TODO: Show Error Alert if false
            }
        } catch let error {
            // TODO: Show Error Alert
            print(error.localizedDescription)
        }
    }

    public func audioRecordingEnded() {
        if let url = LMChatAudioRecordManager.shared.recordingStopped() {
            print(url)
            bottomMessageBoxView.showPlayableRecordView()
        } else {
            bottomMessageBoxView.resetRecordingView()
        }
    }

    public func playRecording() {
        guard let url = LMChatAudioRecordManager.shared.audioURL else { return }

        let eventProps = viewModel?.trackEventBasicParams(messageId: nil) ?? [:]
        LMChatCore.analytics?.trackEvent(
            for: .voiceNotePreviewed,
            eventProperties: eventProps
        )

        LMChatAudioPlayManager.shared.startAudio(fileURL: url.absoluteString) {
            [weak self] progress in
            self?.bottomMessageBoxView.updateRecordTime(
                with: progress,
                isPlayback: true
            )
        }
    }

    public func stopRecording(_ onStop: (() -> Void)) {
        LMChatAudioPlayManager.shared.stopAudio(stopCallback: onStop)
    }

    public func deleteRecording() {

        let eventProps = viewModel?.trackEventBasicParams(messageId: nil) ?? [:]
        LMChatCore.analytics?.trackEvent(
            for: .voiceNoteCanceled,
            eventProperties: eventProps
        )

        LMChatAudioRecordManager.shared.deleteAudioRecording()
    }

    @objc
    open func updateRecordDuration(_ notification: Notification) {
        if let val = notification.object as? Int {
            bottomMessageBoxView.updateRecordTime(with: val)
        }
    }
}

extension LMChatMessageListViewController: MediaPickerDelegate {
    func filePicker(
        _ picker: UIViewController,
        didFinishPicking results: [MediaPickerModel],
        fileType: MediaType
    ) {
        postConversationWithAttchments(message: nil, attachments: results)
    }

    func mediaPicker(
        _ picker: UIViewController,
        didFinishPicking results: [MediaPickerModel]
    ) {
        picker.dismiss(animated: true)
        NavigationScreen.shared.perform(
            .messageAttachmentWithData(
                data: results,
                delegate: self,
                chatroomId: viewModel?.chatroomId,
                mediaType: .image
            ),
            from: self,
            params: nil
        )
    }
}

extension LMChatMessageListViewController: UIDocumentPickerDelegate {
    public func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        var results: [MediaPickerModel] = []
        for item in urls {
            guard
                let localPath = MediaPickerManager.shared
                    .createLocalURLfromPickedAssetsUrl(url: item)
            else { continue }
            switch MediaPickerManager.shared.fileTypeForDocument {
            case .audio:
                if let mediaDetails = FileUtils.getDetail(
                    forVideoUrl: localPath
                ) {
                    let mediaModel = MediaPickerModel(
                        with: localPath,
                        type: .audio,
                        thumbnailPath: mediaDetails.thumbnailUrl
                    )
                    mediaModel.duration = mediaDetails.duration
                    mediaModel.fileSize = Int(mediaDetails.fileSize ?? 0)
                    results.append(mediaModel)
                }
            case .pdf:
                if let pdfDetail = FileUtils.getDetail(forPDFUrl: localPath) {
                    let mediaModel = MediaPickerModel(
                        with: localPath,
                        type: .pdf,
                        thumbnailPath: pdfDetail.thumbnailUrl
                    )
                    mediaModel.numberOfPages = pdfDetail.pageCount
                    mediaModel.fileSize = Int(pdfDetail.fileSize ?? 0)
                    results.append(mediaModel)
                }
            default:
                continue
            }
        }
        NavigationScreen.shared.perform(
            .messageAttachmentWithData(
                data: results,
                delegate: self,
                chatroomId: viewModel?.chatroomId,
                mediaType: MediaPickerManager.shared.fileTypeForDocument
            ),
            from: self,
            params: nil
        )
    }
}

extension LMChatMessageListViewController: LMChatAttachmentViewDelegate {
    public func postConversationWithAttchments(
        message: String?,
        attachments: [MediaPickerModel]
    ) {

        let attachmentMedia: [AttachmentViewData] = attachments.compactMap {
            media in
            var mediaData = AttachmentViewData.Builder()
                .url(media.url?.absoluteString)
                .localPickedURL(media.url)
                .localFilePath(media.url?.absoluteString)
                .type(
                    AttachmentViewData.AttachmentType(
                        rawValue: media.mediaType.rawValue
                    )
                )
                .name(media.url?.lastPathComponent)
                .image(media.photo)

            var metadataBuilder: AttachmentMetaViewData.Builder =
                AttachmentMetaViewData.Builder()

            switch media.mediaType {
            case .video, .audio, .voice_note:
                if let url = media.url,
                    let videoDetails = FileUtils.getDetail(forVideoUrl: url)
                {
                    metadataBuilder = metadataBuilder.duration(
                        videoDetails.duration
                    ).size(Int(videoDetails.fileSize ?? 0))
                    mediaData = mediaData.localPickedThumbnailURL(
                        videoDetails.thumbnailUrl
                    ).thumbnailLocalFilePath(
                        videoDetails.thumbnailUrl?.absoluteString
                    )
                }
            case .pdf:
                if let url = media.url,
                    let pdfDetail = FileUtils.getDetail(forPDFUrl: url)
                {
                    metadataBuilder = metadataBuilder.numberOfPage(
                        pdfDetail.pageCount
                    ).size(Int(pdfDetail.fileSize ?? 0))
                    mediaData = mediaData.localPickedThumbnailURL(
                        pdfDetail.thumbnailUrl
                    )
                }
            case .image, .gif:
                if let url = media.url {
                    let dimension = FileUtils.imageDimensions(with: url)
                    metadataBuilder = metadataBuilder.size(
                        Int(FileUtils.fileSizeInByte(url: media.url) ?? 0)
                    )
                    mediaData = mediaData.width(dimension?.width)
                        .height(dimension?.height)
                }
            default:
                break
            }
            mediaData = mediaData.meta(metadataBuilder.build())
            return mediaData.build()
        }
        viewModel?.postMessage(
            message: message,
            filesUrls: attachmentMedia,
            shareLink: self.viewModel?.currentDetectedOgTags?.url,
            replyConversationId: viewModel?.replyChatMessage?.id,
            replyChatRoomId: viewModel?.replyChatroom
        )
        cancelReply()
        cancelLinkPreview()
        clearTextView()
    }
}

// MARK: Audio Recording
extension LMChatMessageListViewController: AVAudioRecorderDelegate {
    @objc
    open func audioEnded(_ notification: Notification) {
        let duration: Int = (notification.object as? Int) ?? 0
        bottomMessageBoxView.resetAudioDuration(with: duration)
        messageListView.resetAudio()
    }
}

extension LMChatMessageListViewController: UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{

    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey:
            Any]
    ) {
        picker.dismiss(animated: true)
        var mediaType: MediaType = .image
        var mediaData: [MediaPickerModel] = []
        if let videoURL = info[.mediaURL] as? URL,
            let localPath = MediaPickerManager.shared
                .createLocalURLfromPickedAssetsUrl(url: videoURL),
            let videoDetails = FileUtils.getDetail(forVideoUrl: localPath)
        {
            mediaType = .video
            mediaData = [
                .init(
                    with: localPath,
                    type: .video,
                    thumbnailPath: videoDetails.thumbnailUrl
                )
            ]
        } else if let imageUrl = info[.imageURL] as? URL,
            let localPath = MediaPickerManager.shared
                .createLocalURLfromPickedAssetsUrl(url: imageUrl)
        {
            mediaType = .image
            mediaData = [.init(with: localPath, type: .image)]
        } else if let capturedImage = info[.originalImage] as? UIImage,
            let localPath = MediaPickerManager.shared.saveImageIntoDirecotry(
                image: capturedImage
            )
        {
            mediaType = .image
            mediaData = [.init(with: localPath, type: .image)]
        }
        NavigationScreen.shared.perform(
            .messageAttachmentWithData(
                data: mediaData,
                delegate: self,
                chatroomId: viewModel?.chatroomId,
                mediaType: mediaType
            ),
            from: self,
            params: nil
        )
    }

    public func imagePickerControllerDidCancel(
        _ picker: UIImagePickerController
    ) {
        picker.dismiss(animated: true, completion: nil)
    }

}

extension LMChatMessageListViewController: LMChatEmojiListViewDelegate {
    func emojiSelected(
        emoji: String,
        conversationId: String?,
        chatroomId: String?
    ) {
        if let conversationId {
            viewModel?.putConversationReaction(
                conversationId: conversationId,
                reaction: emoji
            )
        } else if let chatroomId {
            viewModel?.putChatroomReaction(
                chatroomId: chatroomId,
                reaction: emoji
            )
        }
    }
}

extension LMChatMessageListViewController: LMReactionViewControllerDelegate {
    public func reactionDeleted(chatroomId: String?, conversationId: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.viewModel?.updateDeletedReaction(
                conversationId: conversationId,
                chatroomId: chatroomId
            )
        }
    }
}

// MARK: LMChatAudioProtocol
extension LMChatMessageListViewController: LMChatAudioProtocol {

    public func didTapPlayPauseButton(for url: String, index: IndexPath) {
        resetAudio()

        guard messageListView.tableSections.indices.contains(index.section),
            messageListView.tableSections[index.section].data.indices.contains(
                index.row
            )
        else { return }

        let messageID =
            messageListView.tableSections[index.section].data[index.row].id
            ?? ""

        messageListView.audioIndex = (index.section, messageID)

        LMChatAudioPlayManager.shared.startAudio(url: url) {
            [weak self] progress in
            (self?.messageListView.tableView.cellForRow(at: index)
                as? LMChatAudioViewCell)?.seekSlider(
                    to: Float(progress),
                    url: url
                )
        }
    }

    public func didSeekTo(_ position: Float, _ url: String, index: IndexPath) {
        LMChatAudioPlayManager.shared.seekAt(position, url: url)
    }

    public func resetAudio() {
        if let audioIndex = messageListView.audioIndex,
            messageListView.tableSections.indices.contains(audioIndex.section),
            let row = messageListView.tableSections[audioIndex.section].data
                .firstIndex(where: { $0.id == audioIndex.messageID })
        {

            (messageListView.tableView.cellForRow(
                at: .init(row: row, section: audioIndex.section)
            )
                as? LMChatAudioViewCell)?.resetAudio()
        }

        messageListView.audioIndex = nil
    }
}

extension LMChatMessageListViewController: LMChatMessageCellDelegate,
    LMChatroomHeaderMessageCellDelegate
{
    public func didTapOnReplyPrivatelyCell(indexPath: IndexPath) {
        let item = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]

        guard let chatroomId = item.widget?.lmMeta?.sourceChatroomId,
            let conversationId = item.widget?.lmMeta?.sourceConversation?.id
        else {
            return
        }
        DispatchQueue.main.async {
            NavigationScreen.shared.perform(
                .chatroom(
                    chatroomId: chatroomId,
                    conversationID: conversationId,
                    replyPrivatelyExtras: nil
                ),
                from: self,
                params: nil
            )
        }
    }

    public func onRetryButtonClicked(conversation: ConversationViewData) {
        viewModel?.retryConversation(conversation: conversation)
    }

    public func didTapURL(url: URL) {
        if url.absoluteString.hasPrefix("http") {
            NavigationScreen.shared.perform(
                .browser(url: url),
                from: self,
                params: nil
            )
        } else {
            UIApplication.shared.open(url)
        }
    }

    public func didTapRoute(route: String) {
        if route == "route://tap_to_undo" {
            viewModel?.blockDMMember(status: .unblock, source: "tap_to_unblock")
        } else {
            viewProfile(route: route)
        }
    }

    public func pauseAudioPlayer() {
        LMChatAudioPlayManager.shared.stopAudio {}
    }
    public func onClickOfSeeMore(for messageID: String, indexPath: IndexPath) {
        guard messageListView.tableSections.indices.contains(indexPath.section),
            let row = messageListView.tableSections[indexPath.section].data
                .firstIndex(where: { $0.id == messageID })
        else { return }

        messageListView.tableSections[indexPath.section].data[row].isShowMore
            .toggle()
        messageListView.tableView.beginUpdates()
        messageListView.tableView.reloadRows(
            at: [.init(row: row, section: indexPath.section)],
            with: .none
        )
        messageListView.tableView.endUpdates()
    }

    public func didCancelAttachmentUploading(indexPath: IndexPath) {
        let item = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        didCancelUploading(
            tempId: item.temporaryId ?? "",
            messageId: item.id ?? ""
        )
    }

    public func didRetryAttachmentUploading(indexPath: IndexPath) {
        let item = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]
        didRetryUploading(message: item)
    }

    public func didTappedOnSelectionButton(indexPath: IndexPath?) {
        guard let indexPath else { return }
        let item = messageListView.tableSections[indexPath.section].data[
            indexPath.row
        ]

        // Toggle selection
        if let itemIndex = messageListView.selectedItems.firstIndex(where: {
            $0.id == item.id
        }) {
            messageListView.selectedItems.remove(at: itemIndex)
        } else {
            messageListView.selectedItems.append(item)
        }

        // Update UI based on selection
        if messageListView.selectedItems.isEmpty {
            cancelSelectedMessageAction()
            return
        }

        // Configure bar buttons
        deleteMessageBarItem.isEnabled = false
        copySelectedMessagesBarItem.isEnabled = shouldEnableCopyButton()

        // Additional permission checks
        if viewModel?.chatroomViewData?.isSecret == true
            && viewModel?.chatroomViewData?.followStatus == false
        {
            return
        }

        if viewModel?.memberState?.state != 1 {
            deleteMessageBarItem.isEnabled = !messageListView.selectedItems
                .contains {
                    $0.isIncoming == true
                }
        } else {
            deleteMessageBarItem.isEnabled = true
        }
    }

    private func shouldEnableCopyButton() -> Bool {
        // Only enable if ALL selected items are copyable (text-only or links)
        return !messageListView.selectedItems.contains { message in
            // If message has non-text attachments, it's not copyable
            if hasNonTextAttachments(message) {
                return true
            }

            // If message is empty (no text and no attachments), it's not copyable
            if message.answer.isEmpty && (message.attachments?.isEmpty ?? true)
            {
                return true
            }

            return false
        }
    }
    private func hasNonTextAttachments(_ message: ConversationViewData) -> Bool
    {
        // Check if message has any non-text attachments
        guard let attachments = message.attachments else { return false }

        return !attachments.isEmpty
    }

    public func onClickReplyOfMessage(indexPath: IndexPath?) {
        guard let indexPath else { return }
        didTappedOnReplyPreviewOfMessage(indexPath: indexPath)
    }

    public func onClickAttachmentOfMessage(url: String, indexPath: IndexPath?) {
        guard let indexPath else { return }
        didTappedOnAttachmentOfMessage(url: url, indexPath: indexPath)
    }

    public func onClickGalleryOfMessage(
        attachmentIndex: Int,
        indexPath: IndexPath?
    ) {
        guard let indexPath else { return }
        didTappedOnGalleryOfMessage(
            attachmentIndex: attachmentIndex,
            indexPath: indexPath
        )
    }

    public func onClickReactionOfMessage(
        reaction: String,
        indexPath: IndexPath?
    ) {
        guard let indexPath else { return }
        didTappedOnReaction(reaction: reaction, indexPath: indexPath)
    }

    public func didTapOnProfileLink(route: String) {
        LMChatCore.shared.coreCallback?.userProfileViewHandle(withRoute: route)
    }

}

extension LMChatMessageListViewController: LMChatApproveRejectDelegate {

    public func approveRequest() {
        self.showAlertWithActions(
            title: Constants.shared.strings.dmRequestApproveTitle,
            message: Constants.shared.strings.dmRequestApproveMessage,
            withActions: [
                ("Cancel", nil),
                (
                    "Accept",
                    { [weak self] in
                        self?.viewModel?.sendDMRequest(
                            text: nil,
                            requestState: .approved
                        )
                    }
                ),
            ]
        )

    }

    public func rejectRequest() {
        self.showAlertWithActions(
            title: Constants.shared.strings.dmRequestRejectTitle,
            message: Constants.shared.strings.dmRequestRejectMessage,
            withActions: [
                (
                    "Reject",
                    { [weak self] in
                        self?.viewModel?.sendDMRequest(
                            text: nil,
                            requestState: .rejected
                        )
                    }
                ),
                ("Cancel", nil),
                (
                    "Report And Reject",
                    { [weak self] in
                        guard let self,
                            let reportView =
                                try? LMChatReportViewModel.createModule(
                                    reportContentId: (
                                        viewModel?.chatroomId, nil, nil, nil
                                    )
                                )
                        else { return }
                        reportView.delegate = self
                        self.navigationController?.pushViewController(
                            reportView,
                            animated: true
                        )
                    }
                ),
            ]
        )
    }
}

extension LMChatMessageListViewController: LMChatReportViewDelegate {
    public func didReportActionCompleted(reason: String?) {
        viewModel?.sendDMRequest(
            text: nil,
            requestState: .rejected,
            reason: reason
        )
    }
}

extension LMChatMessageListViewController: LMChatTaggedUserFoundProtocol {
    public func userSelected(with route: String, and userName: String) {
        bottomMessageBoxView.inputTextView.addTaggedUser(
            with: userName,
            route: route
        )
        mentionStopped()
    }

    public func updateHeight(with height: CGFloat) {
        taggingViewHeightConstraints?.constant = height
    }
}

extension LMChatMessageListViewController: LMChatTaggingTextViewProtocol {

    public func mentionStarted(with text: String, chatroomId: String) {
        guard viewModel?.isChatroomType(type: .directMessage) == false else {
            return
        }
        taggingListView.fetchUsers(for: text, chatroomId: chatroomId)
    }

    public func mentionStopped() {
        guard viewModel?.isChatroomType(type: .directMessage) == false else {
            return
        }
        taggingListView.stopFetchingUsers()
    }

    public func contentHeightChanged() {
        let width = bottomMessageBoxView.inputTextView.frame.size.width

        let newSize = bottomMessageBoxView.inputTextView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )

        bottomMessageBoxView.inputTextView.isScrollEnabled =
            newSize.height > bottomMessageBoxView.maxHeightOfTextView
        bottomMessageBoxView.inputTextViewHeightConstraint?.constant = min(
            max(newSize.height, 36),
            bottomMessageBoxView.maxHeightOfTextView
        )
        LMSharedPreferences.setString(
            bottomMessageBoxView.inputTextView.getText(),
            forKey: viewModel?.chatroomId ?? "NA"
        )
    }

    public func textViewDidChange(_ textView: UITextView) {
        if viewModel?.isChatroomType(type: .directMessage) == true,
            viewModel?.chatroomViewData?.chatRequestState == nil
        {
            bottomMessageBoxView.sendButton.tag =
                bottomMessageBoxView.messageButtonTag
            bottomMessageBoxView.sendButton.setImage(
                bottomMessageBoxView.sendButtonIcon,
                for: .normal
            )
        } else {
            bottomMessageBoxView.checkSendButtonGestures()
        }

        // Find first url link here and ignore email
        let links = textView.text.detectedLinks
        if !bottomMessageBoxView.isLinkPreviewCancel, !links.isEmpty,
            let link = links.first(where: { !$0.isEmail() })
        {
            bottomMessageBoxView.detectedFirstLink = link
            bottomMessageBoxView.delegate?.linkDetected(link)
        } else {
            bottomMessageBoxView.linkPreviewView.isHidden = true
            bottomMessageBoxView.detectedFirstLink = nil
        }
    }
}

extension LMChatMessageListViewController: LMChatCreatePollViewDelegate {

    public func updatePollDetails(with data: LMChatCreatePollDataModel) {
        viewModel?.postPollConversation(pollData: data)
    }

    public func cancelledPollCreation() {

    }
}

extension LMChatMessageListViewController: LMChatPollViewDelegate {

    public func didTapVoteCountButton(
        for chatroomId: String,
        messageId: String,
        optionID: String?
    ) {
        guard
            let poll = viewModel?.chatMessages.first(where: {
                $0.id == messageId
            })
        else { return }
        if poll.isAnonymous == true {
            self.showErrorAlert(
                LMStringConstant.shared.anonymousPollTitle,
                message: LMStringConstant.shared.anonymousPollMessage
            )
            return
        } else if (poll.toShowResults == false)
            && (poll.expiryTime ?? 0) > Int(Date().millisecondsSince1970)
        {
            self.showErrorAlert(
                nil,
                message: LMStringConstant.shared.endPollVisibleResultMessage
            )
            return
        }

        guard
            let polls = viewModel?.chatMessages.first(where: {
                $0.id == messageId
            })?.polls,
            let optionId = (optionID ?? polls.first?.id)
        else { return }
        viewModel?.trackEventForPoll(
            eventName: .pollAnswersViewed,
            pollId: messageId
        )
        NavigationScreen.shared.perform(
            .pollResult(
                conversationId: messageId,
                pollOptions: DataModelConverter.shared
                    .convertPollOptionsIntoResultPollOptions(polls),
                selectedOptionId: optionId
            ),
            from: self,
            params: nil
        )
    }

    public func didTapToVote(
        for chatroomId: String,
        messageId: String,
        optionID: String
    ) {
        viewModel?.pollOptionSelected(messageId: messageId, optionId: optionID)
    }

    public func didTapSubmitVote(for chatroomId: String, messageId: String) {
        viewModel?.pollSubmit(messageId: messageId)
    }

    public func editVoteTapped(for chatroomId: String, messageId: String) {
        viewModel?.editVote(messageId: messageId)
    }

    public func didTapAddOption(for chatroomId: String, messageId: String) {

        let alert = UIAlertController(
            title: Constants.shared.strings.addNewPollTitle,
            message: Constants.shared.strings.addNewPollMessage,
            preferredStyle: .alert
        )
        alert.addTextField { pollTextField in
            pollTextField.placeholder = "Type New Option"
        }
        alert.addAction(
            UIAlertAction(
                title: LMStringConstant.shared.cancel,
                style: .cancel,
                handler: { _ in
                    alert.dismiss(animated: true, completion: nil)
                }
            )
        )
        alert.addAction(
            UIAlertAction(
                title: Constants.shared.strings.submit,
                style: .default,
                handler: { [weak self] action in
                    if let textFields = alert.textFields,
                        let firstField = textFields.first,
                        let pollOption = firstField.text,
                        pollOption != ""
                    {
                        self?.viewModel?.addPollOption(
                            pollId: messageId,
                            option: pollOption
                        )
                    }
                }
            )
        )
        self.present(alert, animated: true)
    }
}
