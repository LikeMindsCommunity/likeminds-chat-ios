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
        let view = LMChatHomeFeedListView().translatesAutoresizingMaskIntoConstraints()
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
        self.setNavigationTitleAndSubtitle(with: "Community", subtitle: nil, alignment: .center)
        LMChatCore.analytics?.trackEvent(for: .homeFeedPageOpened,
                                         eventProperties: [LMChatAnalyticsKeys.communityId.rawValue: viewModel?.getCommunityId() ?? ""])
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let deeplinkUrl = LMSharedPreferences.getString(forKey: .tempDeeplinkUrl) {
            LMSharedPreferences.removeValue(forKey: .tempDeeplinkUrl)
            DeepLinkManager.sharedInstance.routeToScreen(routeUrl: deeplinkUrl, fromNotification: false, fromDeeplink: true)
        }
        viewModel?.getChatrooms()
        viewModel?.syncChatroom()
        profileIcon.kf.setImage(with: URL(string: viewModel?.memberProfile?.imageUrl ?? ""), placeholder: UIImage.generateLetterImage(name: viewModel?.memberProfile?.name?.components(separatedBy: " ").first ?? ""))
        viewModel?.getExploreTabCount()
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        self.view.addSubview(feedListView)
        setupRightItemBars()
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        self.view.safeAreaPinSubView(subView: feedListView)
    }
    
    func setupRightItemBars() {
        let profileItem = UIBarButtonItem(customView: profileIcon)
        let searchItem = UIBarButtonItem(image: Constants.shared.images.searchIcon, style: .plain, target: self, action: #selector(searchBarItemClicked))
        searchItem.tintColor = Appearance.shared.colors.textColor
        profileItem.customView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileItemClicked)))
        if let vc = self.navigationController?.viewControllers.first {
            vc.navigationItem.rightBarButtonItems = [profileItem, searchItem]
            (vc as? LMViewController)?.setNavigationTitleAndSubtitle(with: "Community", subtitle: nil)
        } else {
            navigationItem.rightBarButtonItems = [profileItem, searchItem]
        }
    }
    
    @objc open func searchBarItemClicked() {
        LMChatCore.analytics?.trackEvent(for: .searchIconClicked, eventProperties: [LMChatAnalyticsKeys.source.rawValue: LMChatAnalyticsSource.homeFeed.rawValue])
        NavigationScreen.shared.perform(.searchScreen, from: self, params: nil)
    }
    
    @objc open func profileItemClicked() {
        LMChatCore.shared.coreCallback?.userProfileViewHandle(withRoute: LMStringConstant.shared.profileRoute + (viewModel?.memberProfile?.sdkClientInfo?.uuid ?? ""))
    }
}

extension LMChatGroupFeedViewController: LMChatGroupFeedViewModelProtocol {
    
    public func updateHomeFeedChatroomsData() {
       let chatrooms =  (viewModel?.chatrooms ?? []).compactMap({ chatroom in
            LMChatHomeFeedChatroomCell.ContentModel(contentView: viewModel?.chatroomContentView(chatroom: chatroom))
        })
        feedListView.updateChatroomsData(chatroomData: chatrooms)
    }
    
    public func updateHomeFeedExploreCountData() {
        guard let countData = viewModel?.exploreTabCountData else { return }
        feedListView.updateExploreTabCount(exploreTabCount: LMChatHomeFeedExploreTabCell.ContentModel(totalChatroomsCount: countData.totalChatroomCount, unseenChatroomsCount: countData.unseenChatroomCount))
    }
    
    
    public func reloadData() {}
}

extension LMChatGroupFeedViewController: LMHomFeedListViewDelegate {
    
    public func didTapOnCell(indexPath: IndexPath) {
        switch feedListView.tableSections[indexPath.section].sectionType {
        case .exploreTab:
            NavigationScreen.shared.perform(.exploreFeed, from: self, params: nil)
        case .chatrooms:
            guard let viewModel else { return }
            let chatroom = viewModel.chatrooms[indexPath.row]
            NavigationScreen.shared.perform(.chatroom(chatroomId: chatroom.id), from: self, params: nil)
        default:
            break
        }
    }
    
    public func fetchMoreData() {
//     Add Logic for next page data
    }
}
