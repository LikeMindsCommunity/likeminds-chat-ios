//
//  LMCommunityChatViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/02/24.
//

import Foundation
import LikeMindsChatUI

open class LMCommunityChatViewController: LMViewController {

    var viewModel: LMCommunityChatViewModel?

    open private(set) lazy var feedListView: LMChatHomeFeedListView = {
        let view = LMChatHomeFeedListView()
            .translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .systemGroupedBackground
        return view
    }()

    open private(set) lazy var profileIcon: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.setWidthConstraint(with: 36)
        image.setHeightConstraint(with: 36)
        image.cornerRadius(with: 18)
        return image
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationTitleAndSubtitle(
            with: "Community", subtitle: nil, alignment: .center)
        LMChatCore.analytics?.trackEvent(
            for: .homeFeedPageOpened,
            eventProperties: [
                LMChatAnalyticsKeys.communityId.rawValue: viewModel?
                    .getCommunityId() ?? ""
            ])
        feedListView.delegate = self
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let deeplinkUrl = LMSharedPreferences.getString(
            forKey: .tempDeeplinkUrl)
        {
            LMSharedPreferences.removeValue(forKey: .tempDeeplinkUrl)
            DeepLinkManager.sharedInstance.routeToScreen(
                routeUrl: deeplinkUrl, fromNotification: false,
                fromDeeplink: true)
        }
        viewModel?.getChatrooms()
        viewModel?.syncChatroom()
        profileIcon.kf.setImage(
            with: URL(string: viewModel?.memberProfile?.imageUrl ?? ""),
            placeholder: UIImage.generateLetterImage(
                name: viewModel?.memberProfile?.name?.components(
                    separatedBy: " "
                ).first ?? ""))
        viewModel?.getExploreTabCount()
        // Check if secret chatroom invite feature is enabled or not
        if LMChatCore.isSecretChatroomInviteEnabled {
            // If enabled call getChannelInvites method to
            // get all the invite for the current user
            viewModel?.secretChatroomInvites.removeAll()
            viewModel?.getChannelInvites()
        }
    }

    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        self.view.addSubview(feedListView)
    }

    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        self.view.safeAreaPinSubView(subView: feedListView)
    }

    func setupRightItemBars() {
        let profileItem = UIBarButtonItem(customView: profileIcon)
        let searchItem = UIBarButtonItem(
            image: Constants.shared.images.searchIcon, style: .plain,
            target: self, action: #selector(searchBarItemClicked))
        searchItem.tintColor = Appearance.shared.colors.textColor
        profileItem.customView?.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self, action: #selector(profileItemClicked)))
        if let vc = self.navigationController?.viewControllers.first {
            vc.navigationItem.rightBarButtonItems = [profileItem, searchItem]
            (vc as? LMViewController)?.setNavigationTitleAndSubtitle(
                with: "Community", subtitle: nil)
        } else {
            navigationItem.rightBarButtonItems = [profileItem, searchItem]
        }
    }

    @objc open func searchBarItemClicked() {
        LMChatCore.analytics?.trackEvent(
            for: .searchIconClicked,
            eventProperties: [
                LMChatAnalyticsKeys.source.rawValue: LMChatAnalyticsSource
                    .homeFeed.rawValue
            ])
        NavigationScreen.shared.perform(.searchScreen, from: self, params: nil)
    }

    @objc open func profileItemClicked() {
        LMChatCore.shared.coreCallback?.userProfileViewHandle(
            withRoute: LMStringConstant.shared.profileRoute
                + (viewModel?.memberProfile?.sdkClientInfo?.uuid ?? ""))
    }
}

extension LMCommunityChatViewController: LMCommunityChatViewModelProtocol {

    public func updateHomeFeedChatroomsData() {
        let chatrooms = (viewModel?.chatrooms ?? []).compactMap({ chatroom in
            LMChatHomeFeedChatroomCell.ContentModel(
                contentView: viewModel?.chatroomContentView(chatroom: chatroom))
        })
        feedListView.updateChatroomsData(chatroomData: chatrooms)
    }

    public func updateHomeFeedExploreCountData() {
        guard let countData = viewModel?.exploreTabCountData else { return }
        feedListView.updateExploreTabCount(
            exploreTabCount: LMChatHomeFeedExploreTabCell.ContentModel(
                totalChatroomsCount: countData.totalChatroomCount,
                unseenChatroomsCount: countData.unseenChatroomCount))
    }

    /**
     Updates the home feed with secret chatroom invites data and optionally navigates to a specific chatroom.

     This method performs the following steps:
     1. Retrieves secret chatroom invites data from the view model. If no data is available, the method returns early.
     2. Transforms the raw secret chatroom invites data into an array of `LMChatHomeFeedSecretChatroomInviteCell.ContentModel` objects.
        - For each invite, it converts associated chatroom and invite sender/receiver data into view data formats.
     3. Updates the home feed view (via `feedListView`) with the transformed secret chatroom invites.
     4. If a `chatroomId` is provided, navigates to the chatroom using the shared navigation screen.

     - Parameter chatroomId: An optional string representing the chatroom identifier. If provided, the method
       will trigger a navigation to that chatroom after updating the feed.
     */
    public func updateHomeFeedSecretChatroomInvitesData(chatroomId: String?) {
        // Ensure that secret chatroom invites data exists in the view model.
        guard let secretChatroomInvites = viewModel?.secretChatroomInvites
        else { return }

        // Map the raw secret chatroom invite objects into the cell content models for display.
        var secretChatroomInviteContentList:
            [LMChatHomeFeedSecretChatroomInviteCell.ContentModel] =
                viewModel?.secretChatroomInvites.compactMap { invite in
                    return LMChatHomeFeedSecretChatroomInviteCell.ContentModel(
                        chatroom: invite.chatroom.toViewData(),
                        createdAt: invite.createdAt,
                        id: invite.id,
                        inviteStatus: invite.inviteStatus,
                        updatedAt: invite.updatedAt,
                        inviteSender: invite.inviteSender.toViewData(),
                        inviteReceiver: invite.inviteReceiver.toViewData()
                    )
                } ?? []

        // Update the feed list view with the newly mapped secret chatroom invite content.
        feedListView.updateSecretChatroomInviteCell(
            secretChatroomInvites: secretChatroomInviteContentList)

        // If a chatroom ID is provided, navigate to the corresponding chatroom.
        if let chatroomId {
            NavigationScreen.shared.perform(
                .chatroom(chatroomId: chatroomId, conversationID: nil),
                from: self, params: nil
            )
        }
    }

    public func reloadData() {}
}

extension LMCommunityChatViewController: LMHomFeedListViewDelegate {
    public func didTapOnCell(indexPath: IndexPath) {
        switch feedListView.tableSections[indexPath.section].sectionType {
        case .exploreTab:
            NavigationScreen.shared.perform(
                .exploreFeed, from: self, params: nil)
        case .chatrooms:
            guard let viewModel else { return }
            let chatroom = viewModel.chatrooms[indexPath.row]
            NavigationScreen.shared.perform(
                .chatroom(chatroomId: chatroom.id), from: self, params: nil)
        case .secretChatroomInvite:
            guard let viewModel else { return }
            let chatroom = viewModel.secretChatroomInvites[indexPath.row]
            NavigationScreen.shared.perform(
                .chatroom(
                    chatroomId: chatroom.id.description, conversationID: nil),
                from: self, params: nil)
        default:
            break
        }
    }

    public func fetchMoreData() {
        //     Add Logic for next page data
    }

    public func didAcceptSecretChatroomInvite(
        data: LMChatHomeFeedSecretChatroomInviteCell.ContentModel
    ) {
        guard let viewModel else { return }

        var stringConstant = Constants.shared.strings

        // Create and configure the alert controller
        let alertController = UIAlertController(
            title: stringConstant.joinThisChatroom,
            message: stringConstant.joinThisSecretChatroomDesc,
            preferredStyle: .alert
        )

        // Add Cancel action
        let cancelAction = UIAlertAction(
            title: stringConstant.cancelAllCaps, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        // Add Confirm action
        let confirmAction = UIAlertAction(
            title: stringConstant.confirmAllCaps, style: .default
        ) {
            _ in
            // Call the method to update the channel invite
            viewModel.updateChannelInvite(
                channelInvite: data, inviteStatus: .accepted)
        }
        alertController.addAction(confirmAction)

        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    public func didRejectSecretChatroomInvite(
        data: LMChatHomeFeedSecretChatroomInviteCell.ContentModel
    ) {
        guard let viewModel else { return }

        var stringConstant = Constants.shared.strings

        // Create and configure the alert controller
        let alertController = UIAlertController(
            title: stringConstant.rejectInvitation,
            message:
                stringConstant.rejectSecretChatroomInvitationDesc,
            preferredStyle: .alert
        )

        // Add Cancel action
        let cancelAction = UIAlertAction(
            title: stringConstant.cancelAllCaps, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        // Add Confirm action
        let confirmAction = UIAlertAction(
            title: stringConstant.confirmAllCaps, style: .default
        ) {
            _ in
            // Call the method to update the channel invite
            viewModel.updateChannelInvite(
                channelInvite: data, inviteStatus: .rejected)
        }
        alertController.addAction(confirmAction)

        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
}
