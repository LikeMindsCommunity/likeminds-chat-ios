//
//  LMChatSearchConversationListViewController.swift
//  Pods
//
//  Created by Anurag Tyagi on 01/02/25.
//
import LikeMindsChatUI

public class LMChatSearchConversationListViewController: LMViewController {
    public struct ContentModel {
        let title: String?
        let data: [LMChatSearchCellDataProtocol]

        public init(title: String?, data: [LMChatSearchCellDataProtocol]) {
            self.title = title
            self.data = data
        }
    }

    open private(set) lazy var tableView: LMTableView = {
        let table = LMTableView(frame: .zero, style: .grouped)
            .translatesAutoresizingMaskIntoConstraints()
        table.register(LMUIComponents.shared.searchConversationMessageCell)
        table.dataSource = self
        table.delegate = self
        table.estimatedSectionHeaderHeight = .leastNonzeroMagnitude
        table.bounces = false
        return table
    }()

    open private(set) lazy var searchController: UISearchController = {
        let search = UISearchController()
        search.searchBar.delegate = self
        search.obscuresBackgroundDuringPresentation = false
        return search
    }()

    public var searchResults: [ContentModel] = []
    public var timer: Timer?
    public var viewmodel: LMChatSearchConversationListViewModel?

    open override func setupViews() {
        super.setupViews()
        view.addSubview(tableView)
    }

    open override func setupLayouts() {
        super.setupLayouts()

        tableView.addConstraint(
            top: (view.safeAreaLayoutGuide.topAnchor, 8),
            bottom: (view.safeAreaLayoutGuide.bottomAnchor, 0),
            leading: (view.safeAreaLayoutGuide.leadingAnchor, 0),
            trailing: (view.safeAreaLayoutGuide.trailingAnchor, 0))
    }

    open override func setupAppearance() {
        super.setupAppearance()

        view.backgroundColor = Appearance.shared.colors.white
        tableView.backgroundColor = Appearance.shared.colors.clear
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        let textFieldInsideSearchBar =
            searchController.searchBar.value(forKey: "searchField")
            as? UITextField
        textFieldInsideSearchBar?.textColor = .black
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        LMChatCore.analytics?.trackEvent(
            for: .chatroomSearchClosed, eventProperties: [:])
    }
}

// MARK: UITableView
extension LMChatSearchConversationListViewController: UITableViewDataSource,
    UITableViewDelegate
{
    open func numberOfSections(in tableView: UITableView) -> Int {
        searchResults.count
    }

    open func tableView(
        _ tableView: UITableView, numberOfRowsInSection section: Int
    ) -> Int {
        searchResults[section].data.count
    }

    open func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if let data = searchResults[indexPath.section].data[indexPath.row]
            as? LMChatSearchConversationMessageCell.ContentModel,
            let cell = tableView.dequeueReusableCell(
                LMUIComponents.shared.searchConversationMessageCell)
        {
            cell.configure(with: data)
            return cell
        }

        return UITableViewCell()
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchController.searchBar.resignFirstResponder()
    }

    open func tableView(
        _ tableView: UITableView, heightForHeaderInSection section: Int
    ) -> CGFloat {
        searchResults[section].title != nil ? 24 : 0.001
    }

    open func tableView(
        _ tableView: UITableView, heightForFooterInSection section: Int
    ) -> CGFloat {
        .leastNonzeroMagnitude
    }

    open func tableView(
        _ tableView: UITableView, willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        if indexPath.section == searchResults.count - 1,
            indexPath.row == searchResults[indexPath.section].data.count - 1
        {
            self.showHideFooterLoader(isShow: true)
            viewmodel?.fetchMoreData()
        }
    }

    open func tableView(
        _ tableView: UITableView, didSelectRowAt indexPath: IndexPath
    ) {
        if let cell = searchResults[indexPath.section].data[indexPath.row]
            as? LMChatSearchChatroomCell.ContentModel
        {
            LMChatCore.analytics?.trackEvent(
                for: .chatroomSearched,
                eventProperties: viewmodel?.trackEventBasicParams(
                    chatroomId: cell.chatroomID) ?? [:])
            NavigationScreen.shared.perform(
                .chatroom(chatroomId: cell.chatroomID, conversationID: nil),
                from: self, params: nil)
        } else if let cell = searchResults[indexPath.section].data[
            indexPath.row] as? LMChatSearchConversationMessageCell.ContentModel
        {
            LMChatCore.analytics?.trackEvent(
                for: .messageSearched,
                eventProperties: viewmodel?.trackEventBasicParams(
                    chatroomId: cell.chatroomID) ?? [:])
            NavigationScreen.shared.perform(
                .chatroom(
                    chatroomId: cell.chatroomID, conversationID: cell.messageID),
                from: self, params: nil)
        }
    }

    open func tableView(
        _ tableView: UITableView, willDisplayHeaderView view: UIView,
        forSection section: Int
    ) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .black
    }
}

// MARK: UISearchResultsUpdating
extension LMChatSearchConversationListViewController: UISearchBarDelegate {
    open func searchBar(
        _ searchBar: UISearchBar, textDidChange searchText: String
    ) {
        guard
            let text = searchBar.text?.trimmingCharacters(
                in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            resetSearchData()
            return
        }

        searchResults.removeAll(keepingCapacity: true)
        tableView.reloadData()
        tableView.backgroundView = LMChatSearchShimmerView(
            frame: tableView.bounds)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {
            [weak self] _ in
            self?.viewmodel?.searchList(with: text)
        }
    }

    open func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        LMChatCore.analytics?.trackEvent(
            for: .searchCrossIconClicked,
            eventProperties: [
                LMChatAnalyticsKeys.source.rawValue: LMChatAnalyticsSource
                    .homeFeed.rawValue
            ])
        resetSearchData()
    }

    public func resetSearchData() {
        timer?.invalidate()
        viewmodel?.searchList(with: "")
        searchResults.removeAll(keepingCapacity: true)
        tableView.backgroundView = nil
        tableView.reloadData()
    }
}

// MARK: LMChatSearchListViewProtocol
extension LMChatSearchConversationListViewController:
    LMChatSearchConversationListViewProtocol
{
    public func updateSearchList(with data: [ContentModel]) {
        tableView.backgroundView =
            data.isEmpty ? LMChatNoResultView(frame: tableView.bounds) : nil
        showHideFooterLoader(isShow: false)
        self.searchResults = data
        tableView.reloadData()
    }

    public func showHideFooterLoader(isShow: Bool) {
        tableView.showHideFooterLoader(isShow: isShow)
    }
}
