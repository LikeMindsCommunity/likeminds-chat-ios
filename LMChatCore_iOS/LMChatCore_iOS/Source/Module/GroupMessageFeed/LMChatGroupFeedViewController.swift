//
//  LMChatGroupFeedViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/02/24.
//

import Foundation
import LikeMindsChatUI

open class LMChatGroupFeedViewController: LMViewController {

    var viewModel: LMChatGroupFeedViewModel?

    open private(set) lazy var feedListView: LMChatHomeFeedListView = {
        let view = LMChatHomeFeedListView()
            .translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .systemGroupedBackground
        view.delegate = self
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

extension LMChatGroupFeedViewController: LMChatGroupFeedViewModelProtocol {

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

    public func updateHomeFeedSecretChatroomInvitesData(chatroomId: String?) {
        guard let secretChatroomInvites = viewModel?.secretChatroomInvites
        else { return }

        var secretChatroomInviteContentList:
            [LMChatHomeFeedSecretChatroomInviteCell.ContentModel] =
                secretChatroomInvites.compactMap { invite in

                    return LMChatHomeFeedSecretChatroomInviteCell.ContentModel(
                        chatroom: invite.chatroom.toViewData(),
                        createdAt: invite.createdAt, id: invite.id,
                        inviteStatus: invite.inviteStatus,
                        updatedAt: invite.updatedAt,
                        inviteSender: invite.inviteSender.toViewData(),
                        inviteReceiver: invite.inviteReceiver.toViewData())
                }

        feedListView.updateSecretChatroomInviteCell(
            secretChatroomInvites: secretChatroomInviteContentList)

        if let chatroomId {
            NavigationScreen.shared.perform(
                .chatroom(
                    chatroomId: chatroomId, conversationID: nil),
                from: self, params: nil)
        }
    }

    public func reloadData() {}
}

extension LMChatGroupFeedViewController: LMHomFeedListViewDelegate {

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
        print("Inside function")
        guard let viewModel else { return }
        // Create and configure the alert controller
        let alertController = UIAlertController(
            title: "Join this chatroom?",
            message: "You are about to join this secret chatroom.",
            preferredStyle: .alert
        )

        // Add Cancel action
        let cancelAction = UIAlertAction(
            title: "CANCEL", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        // Add Confirm action
        let confirmAction = UIAlertAction(title: "CONFIRM", style: .default) {
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
        print("Inside function")
        guard let viewModel else { return }

        // Create and configure the alert controller
        let alertController = UIAlertController(
            title: "Reject invitation?",
            message:
                "Are you sure you want to reject the invitation to join this chatroom?",
            preferredStyle: .alert
        )

        // Add Cancel action
        let cancelAction = UIAlertAction(
            title: "CANCEL", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        // Add Confirm action
        let confirmAction = UIAlertAction(title: "CONFIRM", style: .default) {
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
