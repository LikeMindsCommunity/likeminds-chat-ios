//
//  LMChatParticipantListView.swift
//  LikeMindsChatUI
//
//  Created by Pushpendra Singh on 16/02/24.
//

import Foundation

public protocol LMParticipantListViewDelegate: AnyObject {
    func didTapOnCell(indexPath: IndexPath)
    func loadMoreData()
}

@IBDesignable
open class LMChatParticipantListView: LMView {
    public struct ContentModel {
        public let userImage: String?
        public let userName: String
        public let route: String

        public init(userImage: String?, userName: String, route: String) {
            self.userImage = userImage
            self.userName = userName
            self.route = route
        }
    }

    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()

    open private(set) lazy var loadingView: LMChatHomeFeedShimmerView = {
        let view = LMUIComponents.shared.homeFeedShimmerView.init()
            .translatesAutoresizingMaskIntoConstraints()
        view.setWidthConstraint(with: UIScreen.main.bounds.size.width)
        return view
    }()

    open private(set) lazy var noParticipantsView: LMChatNoResultView = {
        let view = LMChatNoResultView(frame: UIScreen.main.bounds)
        return view
    }()

    open private(set) lazy var tableView: LMTableView = { [weak self] in
        let table = LMTableView().translatesAutoresizingMaskIntoConstraints()
        table.register(LMUIComponents.shared.participantListCell)
        table.dataSource = self
        table.delegate = self
        table.prefetchDataSource = self
        table.showsVerticalScrollIndicator = false
        table.clipsToBounds = true
        table.separatorStyle = .none
        table.backgroundColor = .gray
        return table
    }()

    // MARK: Data Variables
    public let cellHeight: CGFloat = 80
    public var data: [LMChatParticipantCell.ContentModel] = []
    public weak var delegate: LMParticipantListViewDelegate?

    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(tableView)
    }

    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()

        pinSubView(subView: containerView)
        containerView.pinSubView(subView: tableView)
    }

    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.clear
        containerView.backgroundColor = Appearance.shared.colors.white
        tableView.backgroundColor = Appearance.shared.colors.clear
    }

    open func reloadList(showLoadingView: Bool = true) {
        DispatchQueue.main.async {
            if !self.data.isEmpty {
                self.hideListBackgroundView()
            } else {
                if showLoadingView {
                    self.showLoaderView()
                } else {
                    self.showNoParticipantsView()
                }
            }
            self.tableView.reloadData()
        }
    }

    // This function presents the loading view for participants list
    open func showLoaderView() {
        // loading view is shown to the user when the user is waiting for
        // the response from the server
        // The loading view consists of a shimmer view
        // Ensure the loading view (e.g., a shimmer view) is set on the main thread.
        self.tableView.backgroundView = self.loadingView
    }

    // This functions remove the background from the participants list
    open func hideListBackgroundView() {
        // Background view for participants list can be shimmer in
        // case waiting for the api response
        // and can be a no participants view
        // in case the search term has no members associated with it

        // Remove any background view from the tableView safely on the main thread.
        self.tableView.backgroundView = nil

    }

    // This functions presents the no participants view
    // This view is shown to the user when no members are found
    // with the given search term
    open func showNoParticipantsView() {

        // Set the noParticipantsView on the main thread.
        self.tableView.backgroundView = self.noParticipantsView

    }
}

// MARK: UITableView
extension LMChatParticipantListView: UITableViewDataSource, UITableViewDelegate,
    UITableViewDataSourcePrefetching
{
    open func tableView(
        _ tableView: UITableView, numberOfRowsInSection section: Int
    ) -> Int {
        data.count
    }

    open func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            LMUIComponents.shared.participantListCell)
        {
            let item = data[indexPath.row]
            cell.configure(with: item)
            return cell
        }

        return UITableViewCell()
    }

    open func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        delegate?.didTapOnCell(indexPath: indexPath)
    }

    open func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        cellHeight
    }

    open func tableView(
        _ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]
    ) {
        if indexPaths.contains(where: { $0.row >= (data.count - 1) }) {
            delegate?.loadMoreData()
        }
    }
}
