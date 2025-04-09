//
//  LMNetworkingChatViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 17/06/24.
//

import Foundation
import LikeMindsChatUI

/// A protocol that helps notify when a new Direct Message (DM) is initiated.
/// Conforming types should implement how they want to handle the event of
/// starting a new DM for a given community ID.
public protocol LMNetworkingChatViewDelegate: AnyObject {
    /// Notifies that a new DM has been started for the specified community ID.
    ///
    /// - Parameter communityId: The unique identifier of the community.
    func didStartNewDM(withCommunityId communityId: String)
}

/// `LMNetworkingChatViewController` is responsible for displaying
/// a list of chatrooms, managing user interactions (e.g., opening a chatroom),
/// and handling UI elements such as the “New DM” floating action button (FAB).
///
/// This class inherits from `LMViewController` and uses an associated
/// `LMNetworkingChatViewModel` to fetch and update data.
open class LMNetworkingChatViewController: LMViewController {

    // MARK: - Properties

    /// The view model that manages the data and logic for this view controller.
    /// It provides chatrooms, user profile info, and other data-fetching methods.
    var viewModel: LMNetworkingChatViewModel?

    /// A delegate conforming to `LMNetworkingChatViewDelegate`.
    /// Used to notify external components when certain events occur,
    /// such as starting a new DM.
    public weak var delegate: LMNetworkingChatViewDelegate?

    /// A list view that displays various chatrooms in a feed-like format.
    /// Uses `LMChatHomeFeedListView` from the LikeMindsChatUI module.
    open private(set) lazy var feedListView: LMChatHomeFeedListView = {
        let view = LMChatHomeFeedListView()
            .translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .systemGroupedBackground
        view.delegate = self
        return view
    }()

    /// An image view to display the logged-in user’s profile picture.
    /// Shown in the navigation bar to indicate the current user.
    open private(set) lazy var profileIcon: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.setWidthConstraint(with: 36)
        image.setHeightConstraint(with: 36)
        image.cornerRadius(with: 18)
        return image
    }()

    /// The title displayed inside the “New DM” floating action button (FAB).
    /// Defaults to "NEW DM".
    open var fabButtonTitle = "NEW DM"

    /// Tracks the last known scroll offset of the list. Used to determine
    /// whether to expand or collapse the FAB button as the user scrolls.
    fileprivate var lastKnowScrollViewContentOfsset: CGFloat = 0

    /// Stores the width constraint for the FAB button, allowing for its
    /// dynamic resizing (expand/collapse) on scroll.
    open var fabButtonWidthConstraints: NSLayoutConstraint?

    /// A floating action button that allows the user to create a new Direct Message.
    /// When tapped, it either informs the delegate (if one is set) or navigates
    /// to the DM member list screen.
    open private(set) lazy var startNewDMFabButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(Constants.shared.images.newDMIcon, for: .normal)
        button.setTitle(fabButtonTitle, for: .normal)
        button.titleLabel?.font = Appearance.shared.fonts.textFont2
        button.tintColor = .white
        button.backgroundColor = Appearance.shared.colors.linkColor
        return button
    }()

    // MARK: - Lifecycle

    /// Called after the view has loaded its UI elements into memory.
    /// Sets the navigation title and logs an analytics event for the DM screen.
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationTitleAndSubtitle(
            with: "Community", subtitle: nil, alignment: .center)
        LMChatCore.analytics?.trackEvent(
            for: .dmScreenOpened,
            eventProperties: [
                LMChatAnalyticsKeys.communityId.rawValue: viewModel?
                    .getCommunityId() ?? "",
                LMChatAnalyticsKeys.source.rawValue: "home_feed",
            ]
        )
    }

    /// Called after the view becomes visible to the user.
    /// Checks for any deeplinks, updates user’s profile picture,
    /// and retrieves initial data from the view model.
    ///
    /// - Parameter animated: A Boolean indicating if the appearance transition is animated.
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let deeplinkUrl = LMSharedPreferences.getString(
            forKey: .tempDeeplinkUrl)
        {
            LMSharedPreferences.removeValue(forKey: .tempDeeplinkUrl)
            DeepLinkManager.sharedInstance.routeToScreen(
                routeUrl: deeplinkUrl,
                fromNotification: false,
                fromDeeplink: true
            )
        }
        viewModel?.getInitialData()

        profileIcon.kf.setImage(
            with: URL(string: viewModel?.memberProfile?.imageUrl ?? ""),
            placeholder: UIImage.generateLetterImage(
                name: viewModel?.memberProfile?.name?.components(
                    separatedBy: " "
                ).first ?? ""
            )
        )
    }

    // MARK: - Setup Methods

    /// Adds subviews to the view’s hierarchy, including the feed list view
    /// and the “New DM” FAB button.
    open override func setupViews() {
        super.setupViews()
        self.view.addSubview(feedListView)
        self.view.addSubview(startNewDMFabButton)
    }

    /// Sets layout constraints for the subviews: pins the feed list
    /// and positions the FAB button in the bottom-trailing corner.
    open override func setupLayouts() {
        super.setupLayouts()
        self.view.safeAreaPinSubView(subView: feedListView)
        startNewDMFabButton.addConstraint(
            bottom: (view.safeAreaLayoutGuide.bottomAnchor, -16),
            trailing: (view.trailingAnchor, -16)
        )
        startNewDMFabButton.setHeightConstraint(with: 50)
        setupStartNewDMFabButton()
    }

    /// Configures the right bar button items on the navigation bar.
    /// Adds a profile icon and a search icon, each with associated gestures.
    func setupRightItemBars() {
        let profileItem = UIBarButtonItem(customView: profileIcon)
        let searchItem = UIBarButtonItem(
            image: Constants.shared.images.searchIcon,
            style: .plain,
            target: self,
            action: #selector(searchBarItemClicked)
        )
        searchItem.tintColor = Appearance.shared.colors.textColor

        profileItem.customView?.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self, action: #selector(profileItemClicked))
        )

        // If this VC is the first in the navigation stack, set items on that VC.
        // Otherwise, set them on the current navigation item.
        if let vc = self.navigationController?.viewControllers.first {
            vc.navigationItem.rightBarButtonItems = [profileItem, searchItem]
            (vc as? LMViewController)?.setNavigationTitleAndSubtitle(
                with: "Community", subtitle: nil)
        } else {
            navigationItem.rightBarButtonItems = [profileItem, searchItem]
        }
    }

    // MARK: - Actions

    /// Invoked when the user taps the profile icon in the navigation bar.
    /// Routes the user to their profile screen via `coreCallback`.
    @objc open func profileItemClicked() {
        LMChatCore.shared.coreCallback?.userProfileViewHandle(
            withRoute: LMStringConstant.shared.profileRoute
                + (viewModel?.memberProfile?.sdkClientInfo?.uuid ?? "")
        )
    }

    /// Configures the “New DM” FAB button’s size and appearance,
    /// including the tap target for creating a new DM.
    open func setupStartNewDMFabButton() {
        fabButtonWidthConstraints = startNewDMFabButton.widthAnchor.constraint(
            equalToConstant: 120)
        fabButtonWidthConstraints?.isActive = true
        startNewDMFabButton.setInsets(
            forContentPadding: UIEdgeInsets(
                top: 5, left: 5, bottom: 5, right: 5),
            imageTitlePadding: 10
        )
        startNewDMFabButton.layer.cornerRadius = 25
        startNewDMFabButton.addTarget(
            self, action: #selector(startNewDMFabButtonClicked), for: .touchUpInside)
        startNewDMFabButton.isHidden = true
    }

    /// Triggered when the “New DM” FAB button is tapped.
    /// If a delegate is present, it notifies the delegate. Otherwise,
    /// it navigates to the DM member list screen.
    @objc open func startNewDMFabButtonClicked() {
        if let delegate, let communityId = viewModel?.getCommunityId() {
            delegate.didStartNewDM(withCommunityId: communityId)
            return
        } else {
            NavigationScreen.shared.perform(
                .dmMemberList(showList: viewModel?.showList),
                from: self,
                params: nil
            )
        }
    }

    /// Dynamically expands or collapses the “New DM” FAB button based on scroll direction.
    /// If the user is scrolling downward, it collapses to show only the icon.
    /// Scrolling upward expands the button to show icon + text.
    ///
    /// - Parameter offsetY: The current vertical offset of the scroll view.
    open func startNewDMButtonExpandAndCollapes(_ offsetY: CGFloat) {
        if offsetY > self.lastKnowScrollViewContentOfsset {
            // Collapse the button
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.startNewDMFabButton.setTitle(nil, for: .normal)
                weakSelf.startNewDMFabButton.setInsets(
                    forContentPadding: UIEdgeInsets(
                        top: 5, left: 5, bottom: 5, right: 5),
                    imageTitlePadding: 0
                )
                self?.fabButtonWidthConstraints?.isActive = false
                self?.fabButtonWidthConstraints = self?.startNewDMFabButton
                    .widthAnchor.constraint(equalToConstant: 50.0)
                self?.fabButtonWidthConstraints?.isActive = true
                weakSelf.view.layoutIfNeeded()
            }
        } else {
            // Expand the button
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.startNewDMFabButton.setTitle(
                    weakSelf.fabButtonTitle, for: .normal)
                weakSelf.startNewDMFabButton.setInsets(
                    forContentPadding: UIEdgeInsets(
                        top: 5, left: 5, bottom: 5, right: 5),
                    imageTitlePadding: 10
                )
                self?.fabButtonWidthConstraints?.isActive = false
                self?.fabButtonWidthConstraints = self?.startNewDMFabButton
                    .widthAnchor.constraint(equalToConstant: 120.0)
                self?.fabButtonWidthConstraints?.isActive = true
                weakSelf.view.layoutIfNeeded()
            }
        }
    }

    /// Shows or hides the “New DM” FAB button.
    ///
    /// - Parameter showFab: A boolean indicating whether the FAB should be visible.
    open func showDMFabButton(showFab: Bool) {
        startNewDMFabButton.isHidden = !showFab
    }

    /// Invoked when the search icon in the navigation bar is tapped.
    /// Tracks the event and transitions the user to the search screen.
    @objc open func searchBarItemClicked() {
        LMChatCore.analytics?.trackEvent(
            for: .searchIconClicked,
            eventProperties: [
                LMChatAnalyticsKeys.source.rawValue: LMChatAnalyticsSource
                    .homeFeed.rawValue
            ]
        )
        NavigationScreen.shared.perform(.searchScreen, from: self, params: nil)
    }
}

// MARK: - LMNetworkingChatViewModelProtocol Conformance

extension LMNetworkingChatViewController: LMNetworkingChatViewModelProtocol {

    /// Updates the visibility of the DM FAB button based on a boolean parameter.
    /// - Parameter showDM: Determines whether to show (true) or hide (false) the DM FAB.
    public func checkDMStatus(showDM: Bool) {
        showDMFabButton(showFab: showDM)
    }

    /// Updates the feed list with new chatrooms data from the view model.
    /// Transforms each chatroom into a `LMChatHomeFeedChatroomCell.ContentModel`.
    public func updateHomeFeedChatroomsData() {
        let chatrooms = (viewModel?.chatrooms ?? []).compactMap { chatroom in
            LMChatHomeFeedChatroomCell.ContentModel(
                contentView: viewModel?.chatroomContentView(chatroom: chatroom)
            )
        }
        feedListView.updateChatroomsData(chatroomData: chatrooms)
    }

    /// Updates the “Explore” tab with data on total chatrooms and unseen chatrooms,
    /// if available from the view model.
    public func updateHomeFeedExploreCountData() {
        guard let countData = viewModel?.exploreTabCountData else { return }
        feedListView.updateExploreTabCount(
            exploreTabCount: LMChatHomeFeedExploreTabCell.ContentModel(
                totalChatroomsCount: countData.totalChatroomCount,
                unseenChatroomsCount: countData.unseenChatroomCount
            )
        )
    }

    /// Reloads the entire feed list if needed.
    /// Currently implemented as an empty function; can be extended as required.
    public func reloadData() {}
}

// MARK: - LMHomFeedListViewDelegate

extension LMNetworkingChatViewController: LMHomFeedListViewDelegate {
    /// Handles acceptance of a secret chatroom invite.
    /// Currently no logic is implemented.
    /// - Parameter data: The model containing invite details.
    public func didAcceptSecretChatroomInvite(
        data: LikeMindsChatUI.LMChatHomeFeedSecretChatroomInviteCell
            .ContentModel
    ) {
        return
    }

    /// Handles rejection of a secret chatroom invite.
    /// Currently no logic is implemented.
    /// - Parameter data: The model containing invite details.
    public func didRejectSecretChatroomInvite(
        data: LikeMindsChatUI.LMChatHomeFeedSecretChatroomInviteCell
            .ContentModel
    ) {
        return
    }

    /// Called when a cell in the feed list is tapped.
    /// Navigates to the appropriate chatroom if it’s in the `.chatrooms` section.
    /// - Parameter indexPath: The index path for the tapped cell.
    public func didTapOnCell(indexPath: IndexPath) {
        switch feedListView.tableSections[indexPath.section].sectionType {
        case .chatrooms:
            guard let viewModel else { return }
            let chatroom = viewModel.chatrooms[indexPath.row]
            NavigationScreen.shared.perform(
                .chatroom(chatroomId: chatroom.id), from: self, params: nil)
        default:
            break
        }
    }

    /// Called when the user scrolls to the bottom of the feed, typically to fetch more data.
    /// Currently no logic is implemented.
    public func fetchMoreData() {
        return
    }

    /// Called when the user finishes dragging the scroll view.
    /// Records the current offset to determine future FAB button animations.
    /// - Parameter decelerate: A boolean indicating if scrolling continues.
    public func scrollViewDidEndDragging(
        _ scrollView: UIScrollView, willDecelerate decelerate: Bool
    ) {
        self.lastKnowScrollViewContentOfsset = scrollView.contentOffset.y
    }

    /// Called whenever the scroll view’s offset changes.
    /// Used to animate the FAB button based on scroll direction (expanding/collapsing).
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        startNewDMButtonExpandAndCollapes(offsetY)
    }
}
