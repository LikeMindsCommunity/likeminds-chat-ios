//
//  LMChatDMParticipantsViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 20/06/24.
//

import Foundation
import LikeMindsChatUI

open class LMChatMemberListViewController: LMViewController {
    public var viewModel: LMChatMemberListViewModel?
    public var searchController = UISearchController(searchResultsController: nil)
    
    
    // MARK: UI Elements
    open private(set) lazy var memberCountsLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = ""
        label.font = Appearance.shared.fonts.textFont2
        label.textColor = Appearance.shared.colors.previewSubtitleTextColor
        label.numberOfLines = 1
        return label
    }()
    
    open private(set) lazy var containerView: LMChatParticipantListView = {
        let view = LMUIComponents.shared.participantListView.init().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .systemGroupedBackground
        view.delegate = self
        return view
    }()
    
    
    // MARK: setupViews
    open override func setupViews() {
        self.view.addSubview(memberCountsLabel)
        self.view.addSubview(containerView)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        NSLayoutConstraint.activate([
            memberCountsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            memberCountsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            memberCountsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: memberCountsLabel.bottomAnchor, constant: 8)
        ])
    }
    
    
    // MARK: viewDidLoad
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationTitleAndSubtitle(with: Constants.shared.strings.sendDMToTitle, subtitle: nil, alignment: .center)
        setupSearchBar()
        viewModel?.getParticipants()
    }
    
    open func setupSearchBar() {
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        navigationController?.navigationBar.prefersLargeTitles = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

extension LMChatMemberListViewController: LMChatMemberListViewModelProtocol {
    public func reloadData(with data: [LMChatParticipantCell.ContentModel]) {
        containerView.data = data
        containerView.reloadList()
        
        var subCount: String? = nil
        
        if let count = viewModel?.totalParticipantCount,
           count != 0 {
            subCount = "\(count) members"
        }
        memberCountsLabel.text = subCount
//        setNavigationTitleAndSubtitle(with: Constants.shared.strings.sendDMToTitle, subtitle: subCount)
    }
}

@objc
extension LMChatMemberListViewController: LMParticipantListViewDelegate {
    
    open func didTapOnCell(indexPath: IndexPath) {
        print("participant clicked......")
        let member = containerView.data[indexPath.row]
        guard let uuid = member.id else { return }
        LMChatDMCreationHandler.shared.openDMChatroom(uuid: uuid, viewController: self) {[weak self] chatroomId in
            guard let self, let chatroomId else { return }
            DispatchQueue.main.async {
                NavigationScreen.shared.perform(.chatroom(chatroomId: chatroomId, conversationID: nil), from: self, params: nil)
            }
        }
    }
    
    open func loadMoreData() {
        viewModel?.getParticipants()
    }
}

extension LMChatMemberListViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        viewModel?.searchParticipants(searchController.searchBar.text )
    }
}
