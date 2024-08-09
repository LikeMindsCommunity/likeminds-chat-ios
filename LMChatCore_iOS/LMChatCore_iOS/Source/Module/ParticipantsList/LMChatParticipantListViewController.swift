//
//  LMChatParticipantListViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 16/02/24.
//

import Foundation
import LikeMindsChatUI

open class LMChatParticipantListViewController: LMViewController {
    public var viewModel: LMChatParticipantListViewModel?
    public var searchController = UISearchController(searchResultsController: nil)
    
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMChatParticipantListView = {
        let view = LMUIComponents.shared.participantListView.init().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .systemGroupedBackground
        view.delegate = self
        return view
    }()
    
    
    // MARK: setupViews
    open override func setupViews() {
        self.view.addSubview(containerView)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
    
    
    // MARK: viewDidLoad
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationTitleAndSubtitle(with: "Participants", subtitle: nil, alignment: .center)
        setupSearchBar()
        
        viewModel?.getParticipants()
        viewModel?.fetchChatroomData()
    }
    
    open func setupSearchBar() {
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        navigationController?.navigationBar.prefersLargeTitles = false
        searchController.obscuresBackgroundDuringPresentation = false
    }
}

extension LMChatParticipantListViewController: LMChatParticipantListViewModelProtocol {
    public func reloadData(with data: [LMChatParticipantCell.ContentModel]) {
        containerView.data = data
        containerView.reloadList()
        
        var subCount: String? = nil
        
        if let count = viewModel?.chatroomActionData?.participantCount,
           count != 0 {
            subCount = "\(count) participants"
        }
        
        setNavigationTitleAndSubtitle(with: "Participants", subtitle: subCount)
    }
}

@objc
extension LMChatParticipantListViewController: LMParticipantListViewDelegate {
    
    open func didTapOnCell(indexPath: IndexPath) {
        guard let participants = viewModel?.participantsContentModels, let participant = participants[safe: indexPath.row] else { return }
        LMChatCore.shared.coreCallback?.userProfileViewHandle(withRoute: LMStringConstant.shared.profileRoute + (participant.id ?? ""))
    }
    
    open func loadMoreData() {
        viewModel?.getParticipants()
    }
}

extension LMChatParticipantListViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        viewModel?.searchParticipants(searchController.searchBar.text )
    }
}
